package com.sejourfr.app.calibration;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.AiEvaluationService;
import com.sejourfr.app.service.EvaluationLlmClient;
import com.sejourfr.app.service.EvaluationPromptBuilder;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.EvaluationRefusalMetrics;
import com.sejourfr.app.service.ProductionFluiditeService;
import com.sejourfr.app.service.ProductionRubricsProvider;
import com.sejourfr.app.service.ProductionSecondePasseService;
import com.sejourfr.app.service.ProductionValidityService;
import com.sejourfr.app.util.TranscriptTurnStitcher;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Execute une campagne de mesure : pour chaque cas du corpus, construit la tache
 * en memoire, appelle le VRAI {@link AiEvaluationService} (memes prompts, meme
 * client LLM, meme post-traitement serveur : note ponderee, niveau calcule,
 * plafonds, confiance) et enregistre la reponse.
 *
 * <p>Aucune base de donnees : les trois managers sont mockes, un par cas, ce qui
 * rend chaque unite de travail independante et parallelisable.
 *
 * <p><b>Conventions de format IRN</b> appliquees aux taches reconstituees :
 * EE T1 30-60 mots, EE T2/T3 40-90 mots ; EO T1 180 s, EO T2/T3 210 s (plancher
 * 120 s). La duree parlee simulee est posee a l'objectif : le corpus ne porte pas
 * de duree, et une duree courte injecterait un signal absent de la reference.
 */
final class CalibrationRunner {

    private final ProductionEvaluationProperties props;
    private final ProductionRubricsProvider rubrics;
    private final EvaluationPromptBuilder promptBuilder;
    private final ProductionValidityService validity;
    private final EvaluationLlmClient client;
    private final List<String> champsRequis;
    private final int maxTentatives;

    CalibrationRunner(ProductionEvaluationProperties props, ObjectMapper objectMapper, int maxTentatives) {
        this.props = props;
        this.rubrics = new ProductionRubricsProvider(props, objectMapper);
        CalibrationEnv.postConstruct(this.rubrics, "load");
        this.promptBuilder = new EvaluationPromptBuilder(objectMapper, this.rubrics);
        this.validity = new ProductionValidityService(props);
        this.client = CalibrationEnv.client(props, objectMapper);
        this.champsRequis = CalibrationEnv.champsRequis(client.getPromptVersion(), objectMapper);
        this.maxTentatives = maxTentatives;
    }

    String modele() {
        return client.getModelName();
    }

    String promptVersion() {
        return client.getPromptVersion();
    }

    /** Champs obligatoires du contrat de sortie de la version de prompt active. */
    List<String> champsRequis() {
        return champsRequis;
    }

    /** Lance {@code passes} passes completes du corpus, {@code parallelisme} appels en vol. */
    List<CaseRun> run(List<GoldenSet.Cas> corpus, int passes, int parallelisme) {
        List<Callable<CaseRun>> unites = new ArrayList<>();
        for (int passe = 1; passe <= passes; passe++) {
            int p = passe;
            for (GoldenSet.Cas cas : corpus) unites.add(() -> evaluer(cas, p));
        }
        AtomicInteger done = new AtomicInteger();
        int total = unites.size();
        List<CaseRun> out = new ArrayList<>(total);
        try (ExecutorService pool = Executors.newFixedThreadPool(parallelisme)) {
            List<Future<CaseRun>> futures = new ArrayList<>();
            for (Callable<CaseRun> u : unites) {
                futures.add(pool.submit(() -> {
                    CaseRun r = u.call();
                    System.out.printf("  [%2d/%2d] %-16s %-18s note=%-5s niveau=%s%n",
                        done.incrementAndGet(), total, r.casId(), r.statut(),
                        r.note() == null ? "-" : r.note(), r.niveauObtenu());
                    return r;
                }));
            }
            for (Future<CaseRun> f : futures) {
                try {
                    out.add(f.get());
                } catch (Exception e) {
                    throw new IllegalStateException("Unite de mesure interrompue", e);
                }
            }
        }
        out.sort(Comparator.comparing(CaseRun::casId).thenComparingInt(CaseRun::passe));
        return out;
    }

    private CaseRun evaluer(GoldenSet.Cas cas, int passe) {
        ProductionTask task = task(cas);
        ProductionSubmission sub = submission(cas, task);

        ProductionSubmissionManager submissionManager = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptionManager = mock(TranscriptionManager.class);
        AiEvaluationManager aiEvaluationManager = mock(AiEvaluationManager.class);
        when(submissionManager.findById(sub.getId())).thenReturn(Optional.of(sub));
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            // Meme chemin de lecture qu'en production : le manager rend le
            // texte RECOLLE. Le corpus ne porte aucun tour consecutif d'un
            // meme locuteur, c'est donc un no-op mesurable — mais le banc ne
            // doit pas pouvoir diverger du runtime sur ce point.
            when(transcriptionManager.findLatestTexteBySubmissionId(sub.getId()))
                .thenReturn(Optional.of(new TranscriptTurnStitcher(props).stitch(cas.production())));
        }

        RecordingClient recorder = new RecordingClient(client);
        // Une instance PAR CAS : le banc y lit les violations et la citation
        // refusee de CHAQUE appel, y compris celles du premier — l'exception ne
        // porte que celles du reessai. Isolee par cas, donc parallelisable.
        EvaluationRefusalMetrics refus = new EvaluationRefusalMetrics();
        // Seconde passe et fluidite suivent la config du banc : desactivees par
        // defaut, activables via application.yaml pour mesurer leur effet.
        AiEvaluationService service = new AiEvaluationService(submissionManager, transcriptionManager,
            aiEvaluationManager, recorder, promptBuilder, rubrics, validity,
            new ProductionSecondePasseService(props, recorder, rubrics),
            new ProductionFluiditeService(props), refus, new EvaluationPurgeMetrics(), props);

        long start = System.currentTimeMillis();
        AiEvaluation eval = null;
        String erreur = null;
        int tentatives = 0;
        int ratees = 0;
        List<CaseRun.Tentative> traces = new ArrayList<>();
        // Une reponse inexploitable (JSON casse, pas de tool_call, 5xx) fait
        // echouer la soumission en production : on la COMPTE, puis on rejoue pour
        // ne pas perdre le cas — sinon les taux d'accord se mesureraient sur un
        // echantillon biaise par les productions qui cassent le modele.
        while (eval == null && tentatives < maxTentatives) {
            tentatives++;
            refus.reset();
            String erreurTentative = null;
            boolean fatal = false;
            try {
                eval = service.evaluate(sub.getId());
            } catch (AiEvaluationTransientException | AiEvaluationException e) {
                ratees++;
                erreurTentative = resume(e);
                dormir(1000L * tentatives);
            } catch (RuntimeException e) {
                erreurTentative = resume(e);
                fatal = true;
            }
            traces.add(trace(tentatives, erreurTentative, refus));
            // `erreur` n'est PLUS remis a null par une tentative qui reussit :
            // c'est ce qui effacait le motif des refus du rapport.
            if (erreurTentative != null && erreur == null) erreur = erreurTentative;
            if (fatal) break;
        }
        long duree = System.currentTimeMillis() - start;
        return toRun(cas, passe, eval, recorder, erreur, duree, tentatives, ratees, traces);
    }

    /** Ce que NOS controles ont refuse pendant une tentative, phase par phase. */
    private static CaseRun.Tentative trace(int numero, String erreur, EvaluationRefusalMetrics refus) {
        List<String> violations = new ArrayList<>();
        List<String> citations = new ArrayList<>();
        Map<String, Integer> motifs = new LinkedHashMap<>();
        List<EvaluationRefusalMetrics.Refus> refuses = refus.derniersRefus();
        for (EvaluationRefusalMetrics.Refus r : refuses) {
            for (String v : r.violations()) violations.add(r.phase() + " : " + v);
            for (String c : r.citationsRefusees()) citations.add(r.phase() + " : " + c);
            r.motifs().forEach((motif, n) -> motifs.merge(motif, n, Integer::sum));
        }
        return new CaseRun.Tentative(numero, erreur == null, erreur, refuses.size(),
            List.copyOf(violations), List.copyOf(citations), Map.copyOf(motifs));
    }

    private CaseRun toRun(GoldenSet.Cas cas, int passe, AiEvaluation eval, RecordingClient recorder,
                          String erreur, long duree, int tentatives, int ratees,
                          List<CaseRun.Tentative> traces) {
        GoldenSet.Attendu attendu = cas.attendu();
        if (eval == null) {
            return new CaseRun(cas.id(), cas.groupe(), passe, "ERREUR_APPEL", erreur,
                attendu.niveau().name(), noms(attendu.tolerance()), null, null, null,
                Map.of(), attendu.noteMin(), attendu.noteMax(),
                nom(attendu.confiance()), null, attendu.obligatoireTraite(), null,
                attendu.pointsOublies(), List.of(), attendu.pieges(),
                List.of(), List.of(), recorder.appele, tentatives, ratees, modele(),
                null, null, null, duree, recorder.appels, List.copyOf(traces));
        }

        Map<String, Object> feedback = eval.getFeedbackJson();
        // Aucun appel LLM = les controles deterministes ont juge la production
        // inexploitable et le service a repondu seul (note 0, A1_NON_ATTEINT).
        boolean courtCircuit = !recorder.appele;
        List<String> manquants = courtCircuit ? List.of() : champsManquants(recorder.brut);
        List<String> criteresManquants = courtCircuit ? List.of() : criteresManquants(cas, recorder.brut);
        boolean sortieInvalide = !courtCircuit
            && (eval.getNoteSur20() == null || eval.getNiveauCecrl() == null
                || !manquants.isEmpty() || !criteresManquants.isEmpty());
        String statut = courtCircuit ? "VALIDITE_SERVEUR" : (sortieInvalide ? "SORTIE_INVALIDE" : "OK");

        return new CaseRun(cas.id(), cas.groupe(), passe, statut, erreur,
            attendu.niveau().name(), noms(attendu.tolerance()),
            eval.getNiveauCecrl() == null ? null : eval.getNiveauCecrl().name(),
            eval.getNiveauCecrlIa() == null ? null : eval.getNiveauCecrlIa().name(),
            eval.getNoteSur20() == null ? null : eval.getNoteSur20().doubleValue(),
            notesParCode(feedback.get("scores_criteres")),
            attendu.noteMin(), attendu.noteMax(),
            nom(attendu.confiance()), texte(feedback.get("confiance")),
            attendu.obligatoireTraite(), obligatoireTraite(feedback),
            attendu.pointsOublies(), libelles(feedback, "points_oublies"),
            attendu.pieges(), manquants, criteresManquants,
            recorder.appele, tentatives, ratees, eval.getModeleUtilise(),
            eval.getTokensInput(), eval.getTokensOutput(), eval.getCoutEstimeCentimes(), duree,
            recorder.appels, List.copyOf(traces));
    }

    // ------------------------------------------------------------------ donnees

    private ProductionTask task(GoldenSet.Cas cas) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(cas.epreuve());
        t.setTacheNumero((short) cas.tache());
        t.setNiveauCible(cas.niveauCible());
        t.setConsigne(cas.consigne());
        t.setActive(true);
        if (cas.epreuve() == EpreuveType.TCF_EE) {
            t.setMotsMin(cas.tache() == 1 ? 30 : 40);
            t.setMotsMax(cas.tache() == 1 ? 60 : 90);
        } else {
            t.setDureeMaxSec(cas.tache() == 1 ? 180 : 210);
            t.setDureeMinSec(120);
        }
        return t;
    }

    private ProductionSubmission submission(GoldenSet.Cas cas, ProductionTask task) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setSource(ProductionSubmissionSource.ASYNC);
        if (cas.epreuve() == EpreuveType.TCF_EE) {
            s.setTexteSoumis(cas.production());
            s.setMotsCount(cas.production().strip().isEmpty() ? 0 : cas.production().strip().split("\\s+").length);
        } else {
            s.setMediaDurationSec(task.getDureeMaxSec());
        }
        return s;
    }

    // ---------------------------------------------------------------- conformite

    private List<String> champsManquants(Map<String, Object> brut) {
        if (brut == null) return champsRequis;
        List<String> out = new ArrayList<>();
        for (String champ : champsRequis) {
            if (brut.get(champ) == null) out.add(champ);
        }
        return List.copyOf(out);
    }

    private List<String> criteresManquants(GoldenSet.Cas cas, Map<String, Object> brut) {
        Object grille = rubrics.getTask(cas.epreuve(), cas.tache()).map(r -> r.get("criteres")).orElse(null);
        if (!(grille instanceof List<?> criteres)) return List.of();
        Set<String> rendus = new HashSet<>();
        if (brut != null && brut.get("scores_criteres") instanceof List<?> scores) {
            for (Object s : scores) {
                if (s instanceof Map<?, ?> m && m.get("code") != null && m.get("note_sur_20") instanceof Number) {
                    rendus.add(m.get("code").toString());
                }
            }
        }
        List<String> out = new ArrayList<>();
        for (Object c : criteres) {
            if (c instanceof Map<?, ?> m && m.get("code") != null && !rendus.contains(m.get("code").toString())) {
                out.add(m.get("code").toString());
            }
        }
        return List.copyOf(out);
    }

    /**
     * Notes /20 par code de critere, telles que le serveur les a vues. Permet de
     * rejouer hors ligne le passage note -> niveau (seuils, plafonds) sans
     * relancer d'appel LLM.
     */
    private static Map<String, Double> notesParCode(Object scoresCriteres) {
        Map<String, Double> out = new LinkedHashMap<>();
        if (scoresCriteres instanceof List<?> scores) {
            for (Object s : scores) {
                if (s instanceof Map<?, ?> m && m.get("code") != null
                    && m.get("note_sur_20") instanceof Number n) {
                    out.put(m.get("code").toString(), n.doubleValue());
                }
            }
        }
        return Map.copyOf(out);
    }

    private static Boolean obligatoireTraite(Map<String, Object> feedback) {
        if (!(feedback.get("accomplissement") instanceof Map<?, ?> acc)) return null;
        if (!(acc.get("points_oublies") instanceof List<?> oublies)) return null;
        for (Object o : oublies) {
            if (o instanceof Map<?, ?> m && Boolean.TRUE.equals(m.get("obligatoire"))) return false;
        }
        return true;
    }

    private static List<String> libelles(Map<String, Object> feedback, String cle) {
        if (!(feedback.get("accomplissement") instanceof Map<?, ?> acc)) return List.of();
        if (!(acc.get(cle) instanceof List<?> points)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object p : points) {
            if (p instanceof Map<?, ?> m && m.get("libelle") != null) out.add(m.get("libelle").toString());
            else if (p != null) out.add(p.toString());
        }
        return List.copyOf(out);
    }

    private static List<String> noms(List<com.sejourfr.app.enums.NiveauCecrl> niveaux) {
        return niveaux.stream().map(Enum::name).toList();
    }

    private static String nom(Enum<?> e) {
        return e == null ? null : e.name();
    }

    private static String texte(Object o) {
        return o == null ? null : o.toString();
    }

    private static String resume(Throwable e) {
        String msg = e.getMessage();
        return e.getClass().getSimpleName() + (msg == null ? "" : " : " + msg);
    }

    private static void dormir(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Interpose le vrai client pour garder la reponse BRUTE du LLM : le service
     * la normalise (confiance par defaut, accomplissement complete, note et
     * niveau recalcules), ce qui masquerait les non-conformites qu'on veut compter.
     */
    private static final class RecordingClient implements EvaluationLlmClient {
        private final EvaluationLlmClient delegate;
        private Map<String, Object> brut;
        private boolean appele;
        /** Appels LLM reellement emis, reparations comprises. */
        private int appels;

        private RecordingClient(EvaluationLlmClient delegate) {
            this.delegate = delegate;
        }

        @Override
        public Outcome evaluate(String systemPrompt, String userPrompt) {
            appele = true;
            appels++;
            Outcome o = delegate.evaluate(systemPrompt, userPrompt);
            brut = o.feedback() == null ? null : new LinkedHashMap<>(o.feedback());
            return o;
        }

        @Override
        public String getModelName() {
            return delegate.getModelName();
        }

        @Override
        public String getPromptVersion() {
            return delegate.getPromptVersion();
        }
    }
}
