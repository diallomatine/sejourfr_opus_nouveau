package com.sejourfr.app.calibration;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import com.sejourfr.app.service.competence.CompetenceAnalysisLlmClient;
import com.sejourfr.app.service.competence.CompetenceAnalysisPromptBuilder;
import com.sejourfr.app.service.competence.CompetenceAnalysisServiceImpl;
import com.sejourfr.app.service.competence.CompetenceAnalysisValidator;
import com.sejourfr.app.service.competence.CompetenceLevelDowngradeMetrics;
import com.sejourfr.app.service.competence.CompetenceLevelEvidenceGuard;
import com.sejourfr.app.service.competence.CompetenceRubricsProvider;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
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
 * Execute une campagne de mesure du module « Competences TCF » : pour chaque cas
 * du corpus, reconstitue la competence, le sujet et la tentative en memoire,
 * appelle le VRAI {@link CompetenceAnalysisServiceImpl} (memes prompts, meme
 * client LLM, meme validateur, meme garde-fou de preuve, meme normalisation) et
 * enregistre la reponse.
 *
 * <p>Jumeau de {@link CalibrationRunner}. Aucune base de donnees : le manager
 * est mocke, un par cas, ce qui rend chaque unite de travail independante et
 * parallelisable.
 *
 * <p><b>Ce qui n'est PAS envoye au correcteur, et c'est voulu</b> : ni les
 * bornes de longueur du sujet, ni la duree d'enregistrement, ni — depuis les
 * consignes v5 — le niveau cible de la competence. Le banc n'ajoute rien : il
 * passe par le meme {@link CompetenceAnalysisPromptBuilder} que le runtime, donc
 * ce que le correcteur voit ici est exactement ce qu'il voit en production.
 *
 * <p><b>Les refus de nos controles sont OBSERVES, pas instrumentes.</b> Le
 * service n'expose aucun compteur ; le banc rejoue le
 * {@link CompetenceAnalysisValidator} sur chaque sortie brute enregistree — ce
 * qui ne duplique aucune regle — et deduit du nombre d'appels emis qu'une
 * reparation a suivi. Un appel supplementaire sans violation de contrat, c'est
 * donc le garde-fou de preuve qui a rejete la sortie.
 */
final class CompetenceCalibrationRunner {

    private final CompetenceRubricsProvider rubrics;
    private final CompetenceAnalysisPromptBuilder promptBuilder;
    private final CompetenceAnalysisValidator validator;
    private final CompetenceAnalysisLlmClient client;
    private final int maxTentatives;

    CompetenceCalibrationRunner(ProductionEvaluationProperties evalProps, CompetenceProperties props,
                                ObjectMapper objectMapper, int maxTentatives) {
        this.rubrics = new CompetenceRubricsProvider(props, objectMapper);
        CalibrationEnv.postConstruct(this.rubrics, "load");
        this.promptBuilder = new CompetenceAnalysisPromptBuilder(objectMapper, this.rubrics);
        this.validator = new CompetenceAnalysisValidator(this.rubrics);
        this.client = CompetenceCalibrationEnv.client(evalProps, props, objectMapper);
        this.maxTentatives = maxTentatives;
    }

    String modele() {
        return client.getModelName();
    }

    String rubricsVersion() {
        return rubrics.getVersion();
    }

    String toolSchemaVersion() {
        return rubrics.getToolSchemaVersion();
    }

    /** Cles attendues d'une sortie sous le contrat actif. */
    List<String> clesAttendues() {
        return CompetenceAnalysisFields.cles(rubrics.getToolSchemaVersion());
    }

    /** Le contrat actif exige-t-il de DEMONTRER le palier par un numero de segment ? */
    boolean preuveExigee() {
        return CompetenceAnalysisFields.porteLaPreuveDuNiveau(rubrics.getToolSchemaVersion());
    }

    /** Lance {@code passes} passes completes du corpus, {@code parallelisme} appels en vol. */
    List<CompetenceCaseRun> run(List<CompetenceGoldenSet.Cas> corpus, int passes, int parallelisme) {
        List<Callable<CompetenceCaseRun>> unites = new ArrayList<>();
        for (int passe = 1; passe <= passes; passe++) {
            int p = passe;
            for (CompetenceGoldenSet.Cas cas : corpus) unites.add(() -> analyser(cas, p));
        }
        AtomicInteger done = new AtomicInteger();
        int total = unites.size();
        List<CompetenceCaseRun> out = new ArrayList<>(total);
        try (ExecutorService pool = Executors.newFixedThreadPool(parallelisme)) {
            List<Future<CompetenceCaseRun>> futures = new ArrayList<>();
            for (Callable<CompetenceCaseRun> u : unites) {
                futures.add(pool.submit(() -> {
                    CompetenceCaseRun r = u.call();
                    System.out.printf("  [%2d/%2d] %-18s %-16s niveau=%-14s statut=%s%s%n",
                        done.incrementAndGet(), total, r.casId(), r.statut(),
                        r.niveauObtenu() == null ? "-" : r.niveauObtenu(),
                        r.statutObtenu() == null ? "-" : r.statutObtenu(),
                        r.horsScore() ? "  (temoin, hors score)" : "");
                    return r;
                }));
            }
            for (Future<CompetenceCaseRun> f : futures) {
                try {
                    out.add(f.get());
                } catch (Exception e) {
                    throw new IllegalStateException("Unite de mesure interrompue", e);
                }
            }
        }
        out.sort(Comparator.comparing(CompetenceCaseRun::casId)
            .thenComparingInt(CompetenceCaseRun::passe));
        return out;
    }

    // ------------------------------------------------------------------- unite

    private CompetenceCaseRun analyser(CompetenceGoldenSet.Cas cas, int passe) {
        SkillPrompt prompt = prompt(cas);
        UserSkillAttempt attempt = attempt(cas, prompt);

        UserSkillAttemptManager manager = mock(UserSkillAttemptManager.class);
        when(manager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));
        when(manager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // Une instance PAR CAS : les compteurs d'abaissement doivent rester
        // attribuables a un cas precis, donc isoles et parallelisables.
        CompetenceLevelDowngradeMetrics abaissements = new CompetenceLevelDowngradeMetrics();
        RecordingClient recorder = new RecordingClient(client);
        CompetenceAnalysisServiceImpl service = new CompetenceAnalysisServiceImpl(
            manager, promptBuilder, recorder, validator, rubrics,
            new CompetenceLevelEvidenceGuard(abaissements, rubrics));

        long start = System.currentTimeMillis();
        String erreur = null;
        int tentatives = 0;
        int ratees = 0;
        boolean reussie = false;
        // Une reponse inexploitable (JSON casse, pas de tool_call, 5xx) fait
        // echouer l'analyse en production : on la COMPTE, puis on rejoue pour ne
        // pas perdre le cas — sinon les taux d'accord se mesureraient sur un
        // echantillon biaise par les productions qui cassent le modele.
        while (!reussie && tentatives < maxTentatives) {
            tentatives++;
            String erreurTentative = null;
            boolean fatal = false;
            try {
                service.analyse(attempt.getId());
                reussie = true;
            } catch (AiEvaluationTransientException | AiEvaluationException e) {
                ratees++;
                erreurTentative = resume(e);
                dormir(1000L * tentatives);
            } catch (RuntimeException e) {
                erreurTentative = resume(e);
                fatal = true;
            }
            recorder.clotureTentative(erreurTentative == null);
            // `erreur` n'est pas remis a null par une tentative qui reussit :
            // c'est ce qui effacerait le motif des refus du rapport.
            if (erreurTentative != null && erreur == null) erreur = erreurTentative;
            if (fatal) break;
        }
        long duree = System.currentTimeMillis() - start;
        return toRun(cas, passe, attempt, recorder, abaissements, erreur, duree, tentatives, ratees);
    }

    private CompetenceCaseRun toRun(CompetenceGoldenSet.Cas cas, int passe, UserSkillAttempt attempt,
                                    RecordingClient recorder, CompetenceLevelDowngradeMetrics abaissements,
                                    String erreur, long duree, int tentatives, int ratees) {
        CompetenceGoldenSet.Attendu attendu = cas.attendu();
        Map<String, Object> analyse = attempt.getAnalysisJson();

        List<String> manquantes = analyse == null ? clesAttendues() : clesManquantes(analyse);
        String niveau = analyse == null ? null : texte(analyse.get(CompetenceAnalysisFields.LEVEL_REACHED));
        String statutCritere = attempt.getCriterionStatus() == null
            ? null : attempt.getCriterionStatus().name();

        String statut;
        if (analyse == null || niveau == null || statutCritere == null) statut = "ERREUR_APPEL";
        else if (!manquantes.isEmpty()) statut = "SORTIE_INVALIDE";
        else statut = "OK";

        Map<String, Long> motifsPreuve = abaissements.compteurs();
        return new CompetenceCaseRun(
            cas.id(), cas.groupe(), cas.promptCode(), cas.echelle(), passe, cas.horsScore(),
            statut, erreur,
            attendu == null ? null : attendu.niveau().name(),
            attendu == null ? List.of() : attendu.tolerance().stream().map(Enum::name).toList(),
            niveau,
            attendu == null ? null : attendu.statut().name(),
            attendu == null ? List.of() : attendu.statutTolerance().stream().map(Enum::name).toList(),
            statutCritere,
            analyse == null ? null : texte(analyse.get(CompetenceAnalysisFields.VERDICT)),
            analyse != null && analyse.get(CompetenceAnalysisFields.LEVEL_EVIDENCE) != null,
            !motifsPreuve.isEmpty(),
            motifsPreuve,
            attendu == null ? List.of() : attendu.pieges(),
            manquantes,
            tentatives, ratees, recorder.appels(), recorder.refus().size(),
            recorder.refus(), attempt.getAiModel() == null ? modele() : attempt.getAiModel(),
            attempt.getTokensInput(), attempt.getTokensOutput(), attempt.getCoutEstimeCentimes(),
            duree);
    }

    /**
     * Cles du contrat absentes de la sortie PERSISTEE. {@code level_evidence}
     * n'y figure jamais : sous v4 elle est legitimement absente en dessous du B1,
     * et sous v5 — ou le tool-schema l'exige a tous les paliers — son absence est
     * une anomalie que le serveur COMPTE sans jamais faire echouer l'analyse.
     * Dans les deux cas, la compter « sortie invalide » melangerait deux mesures.
     */
    private List<String> clesManquantes(Map<String, Object> analyse) {
        List<String> out = new ArrayList<>();
        for (String cle : clesAttendues()) {
            if (CompetenceAnalysisFields.estExclueDuValidateur(
                    rubrics.getToolSchemaVersion(), cle)) continue;
            if (analyse.get(cle) == null) out.add(cle);
        }
        return List.copyOf(out);
    }

    // ------------------------------------------------------------------ donnees

    private Skill skill(CompetenceGoldenSet.Cas cas) {
        Skill s = new Skill();
        s.setId(UUID.randomUUID());
        s.setSection(cas.section());
        s.setTaskCode(cas.taskCode());
        s.setCode(cas.skillCode());
        s.setTitle(cas.skillTitle());
        s.setDescription(cas.skillDescription());
        s.setGeneralCriterion(cas.skillGeneralCriterion());
        s.setTargetLevel(cas.skillTargetLevel());
        s.setDisplayOrder((short) 1);
        s.setActive(true);
        return s;
    }

    private SkillPrompt prompt(CompetenceGoldenSet.Cas cas) {
        SkillPrompt p = new SkillPrompt();
        p.setId(UUID.randomUUID());
        p.setSkill(skill(cas));
        p.setSection(cas.section());
        p.setCode(cas.promptCode());
        p.setTitle(cas.promptTitle());
        p.setContext(cas.contexte());
        p.setInstruction(cas.consigne());
        p.setUniqueCriterion(cas.critereUnique());
        p.setRecommendedMinWords(cas.motsMin());
        p.setRecommendedMaxWords(cas.motsMax());
        p.setRecommendedDurationSeconds(cas.dureeSec());
        p.setDifficultyLevel(cas.difficulte());
        p.setDisplayOrder((short) 1);
        p.setActive(true);
        return p;
    }

    /**
     * En EO, la production est posee dans {@code transcript} — jamais dans
     * {@code writtenProduction} : c'est cette colonne qui fait choisir la cle
     * {@code transcript} du prompt, donc qui declenche le garde-fou oral des
     * consignes. La DUREE n'est volontairement pas renseignee : le correcteur ne
     * la recoit pas en production, le banc ne doit pas la lui offrir.
     */
    private UserSkillAttempt attempt(CompetenceGoldenSet.Cas cas, SkillPrompt prompt) {
        UserSkillAttempt a = new UserSkillAttempt();
        a.setId(UUID.randomUUID());
        a.setSkillPrompt(prompt);
        a.setStatut(SkillAttemptStatut.EVALUATING);
        a.setAnalysisRequested(true);
        if (cas.orale()) {
            a.setTranscript(cas.production());
        } else {
            a.setWrittenProduction(cas.production());
            a.setWordsCount(cas.production().isBlank() ? 0 : cas.production().strip().split("\\s+").length);
        }
        return a;
    }

    // ------------------------------------------------------------------ divers

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
     * Interpose le vrai client pour garder chaque sortie BRUTE : le service la
     * normalise (cles filtrees, preuve resolue en texte, palier eventuellement
     * abaisse), ce qui masquerait les non-conformites qu'on veut compter.
     *
     * <p>C'est aussi ici que se lisent les REFUS : une sortie suivie d'un second
     * appel dans la meme tentative a forcement ete refusee. Le validateur dit si
     * c'est le contrat qui a lache ; sinon, c'est le garde-fou de preuve.
     */
    private final class RecordingClient implements CompetenceAnalysisLlmClient {

        private final CompetenceAnalysisLlmClient delegate;
        private final List<CompetenceCaseRun.Refus> refus =
            java.util.Collections.synchronizedList(new ArrayList<>());
        /** Derniere sortie brute, pas encore jugee. */
        private Map<String, Object> enAttente;
        private int appels;

        private RecordingClient(CompetenceAnalysisLlmClient delegate) {
            this.delegate = delegate;
        }

        int appels() {
            return appels;
        }

        List<CompetenceCaseRun.Refus> refus() {
            return List.copyOf(refus);
        }

        @Override
        public Outcome analyse(String systemPrompt, String userPrompt) {
            // Un appel qui en suit un autre DANS LA MEME tentative signe le
            // refus du precedent : le service n'appelle une seconde fois que
            // pour reparer, jamais pour autre chose.
            if (enAttente != null) enregistreRefus(enAttente);
            enAttente = null;
            appels++;
            Outcome o = delegate.analyse(systemPrompt, userPrompt);
            enAttente = o.analysis() == null ? Map.of() : new LinkedHashMap<>(o.analysis());
            return o;
        }

        /**
         * La DERNIERE sortie d'une tentative n'est suivie d'aucun appel : elle ne
         * compte comme refusee que si la tentative a echoue en la refusant — ce
         * que le validateur tranche seul. Une panne de fournisseur, elle, n'est
         * pas un refus de nos controles.
         */
        void clotureTentative(boolean reussie) {
            if (enAttente != null && !reussie && !validator.violations(enAttente).isEmpty()) {
                enregistreRefus(enAttente);
            }
            enAttente = null;
        }

        private void enregistreRefus(Map<String, Object> brut) {
            List<String> violations = validator.violations(brut);
            refus.add(new CompetenceCaseRun.Refus(appels,
                violations.isEmpty() ? "PREUVE_DU_NIVEAU" : "CONTRAT", violations));
        }

        @Override
        public String getModelName() {
            return delegate.getModelName();
        }

        @Override
        public String getToolSchemaVersion() {
            return delegate.getToolSchemaVersion();
        }
    }
}
