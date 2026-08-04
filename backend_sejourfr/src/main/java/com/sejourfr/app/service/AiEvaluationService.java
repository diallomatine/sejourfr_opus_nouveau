package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.BandeCritere;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Orchestre l'evaluation IA d'une {@link ProductionSubmission} :
 * construit les prompts, appelle le LLM via {@link EvaluationLlmClient}
 * (provider selectionne par config : Anthropic, OpenAI, ...), persiste
 * {@link AiEvaluation} et passe la submission a EVALUATED.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiEvaluationService {

    private static final BigDecimal NOTE_MAX = new BigDecimal("20");
    /**
     * Au-dela de cet ecart |note_LLM − note_calculee|, on log pour calibration.
     */
    private static final BigDecimal SEUIL_ECART_CALIBRATION = new BigDecimal("3");

    /**
     * Limite ASSUMEE de la correction orale : on ne dispose que du texte
     * transcrit (en temps reel, l'audio ne transite meme pas par nos serveurs).
     * Ce n'est pas un choix pedagogique — on le dit au candidat, mot pour mot.
     */
    static final String AVERTISSEMENT_TRANSCRIPTION =
        "Cette évaluation est fondée sur la transcription écrite de votre production : "
            + "nous n'analysons pas votre voix. L'aisance, la fluidité, le débit et la "
            + "prononciation ne sont donc pas évalués ici — c'est une limite technique de "
            + "notre correction, pas un choix pédagogique. À l'examen officiel, ces "
            + "dimensions comptent.";

    /** Trace du modele quand aucun LLM n'a ete appele (production jugee inevaluable). */
    static final String MODELE_VALIDATION_SERVEUR = "validation-serveur";

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final EvaluationLlmClient llmClient;
    private final EvaluationPromptBuilder promptBuilder;
    private final ProductionRubricsProvider rubrics;
    private final ProductionValidityService validityService;
    private final ProductionSecondePasseService secondePasseService;
    private final ProductionFluiditeService fluiditeService;
    private final ProductionEvaluationProperties props;

    private static BigDecimal extractNote(Map<String, Object> feedback) {
        Object raw = feedback.get("note_globale");
        if (raw == null) return null;
        try {
            BigDecimal v = new BigDecimal(raw.toString()).setScale(1, RoundingMode.HALF_UP);
            if (v.compareTo(BigDecimal.ZERO) < 0 || v.compareTo(NOTE_MAX) > 0) {
                log.warn("note_globale hors borne [0,20] : {}", v);
                return null;
            }
            return v;
        } catch (NumberFormatException e) {
            log.warn("note_globale non-numerique : {}", raw);
            return null;
        }
    }

    private static NiveauCecrl extractNiveau(Map<String, Object> feedback) {
        Object raw = feedback.get("niveau_cecrl");
        if (raw == null) return null;
        try {
            return NiveauCecrl.valueOf(raw.toString());
        } catch (IllegalArgumentException e) {
            log.warn("niveau_cecrl inconnu : {}", raw);
            return null;
        }
    }

    /**
     * {@code round(Σ note_sur_20[code] × poids[code])}, arrondi a l'entier le plus
     * proche (HALF_UP), borne a [0,20]. Retourne null si les criteres/poids ou les
     * scores sont inexploitables (le hors-sujet — tous les criteres a 0 — rend
     * coherent 0, puisque Σ(0×poids)=0). Package-private pour le test unitaire.
     */
    static BigDecimal weightedNote(Object criteres, Object scoresCriteres) {
        if (!(criteres instanceof List<?> critList) || !(scoresCriteres instanceof List<?> scores)) {
            return null;
        }
        Map<String, BigDecimal> poidsByCode = new HashMap<>();
        for (Object c : critList) {
            if (c instanceof Map<?, ?> m && m.get("code") != null && m.get("poids") instanceof Number n) {
                poidsByCode.put(m.get("code").toString(), new BigDecimal(n.toString()));
            }
        }
        if (poidsByCode.isEmpty()) return null;

        BigDecimal sum = BigDecimal.ZERO;
        boolean any = false;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> m)) continue;
            Object code = m.get("code");
            Object note = m.get("note_sur_20");
            if (code == null || !(note instanceof Number noteNum)) continue;
            BigDecimal poids = poidsByCode.get(code.toString());
            if (poids == null) continue;
            sum = sum.add(new BigDecimal(noteNum.toString()).multiply(poids));
            any = true;
        }
        if (!any) return null;
        BigDecimal rounded = sum.setScale(0, RoundingMode.HALF_UP);
        if (rounded.compareTo(BigDecimal.ZERO) < 0) return BigDecimal.ZERO;
        if (rounded.compareTo(NOTE_MAX) > 0) return NOTE_MAX;
        return rounded;
    }

    private static boolean sourceCriteriaPresent(Object scoresCriteres, List<String> sourceCodes) {
        if (!(scoresCriteres instanceof List<?> scores)) return false;
        java.util.Set<String> present = new java.util.HashSet<>();
        for (Object s : scores) {
            if (s instanceof Map<?, ?> m && m.get("code") != null && m.get("note_sur_20") instanceof Number) {
                present.add(m.get("code").toString());
            }
        }
        return present.containsAll(sourceCodes);
    }

    private static String formatMinutes(int sec) {
        int m = sec / 60;
        int s = sec % 60;
        if (m == 0) return s + " s";
        return s == 0 ? m + " min" : m + " min " + s + " s";
    }

    @Transactional
    public AiEvaluation evaluate(UUID submissionId) {
        ProductionSubmission sub = submissionManager.findById(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        ProductionTask task = sub.getProductionTask();
        if (task == null) {
            throw new AiEvaluationException("Submission " + submissionId + " sans production_task.");
        }

        ProductionInput input = loadInput(sub, task);

        // Controles DETERMINISTES avant tout appel LLM (langue, recopiage de la
        // consigne, production vide). Un verdict INVALIDE court-circuite l'IA :
        // pas de note absurde, pas d'appel paye.
        ProductionValidityService.Verdict verdict = validityService.evaluer(task, input.production());
        if (verdict.invalide()) {
            return persistProductionInvalide(sub, task, verdict);
        }

        Integer dureeSec = task.getEpreuve() == EpreuveType.TCF_EO ? sub.getMediaDurationSec() : null;
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(task, input.production(), input.litteral(), dureeSec);

        EvaluationLlmClient.Outcome outcome = llmClient.evaluate(systemPrompt, userPrompt);
        ProductionSecondePasseService.Passe passe = postProcess(
                outcome, llmClient.getModelName(), sub, task, verdict, input.production(), submissionId);

        int tokensIn = nz(outcome.inputTokens());
        int tokensOut = nz(outcome.outputTokens());
        int cout = nz(outcome.costEstimateCents());

        // Seconde passe en ZONE FLOUE uniquement (drapeau seconde-passe.enabled,
        // false par defaut). On retient la plus basse des deux et on abaisse la
        // confiance si elles divergent. Un echec de la seconde passe ne doit
        // jamais faire echouer l'evaluation : on garde la premiere.
        if (secondePasseService.isEnabled()) {
            List<String> raisons = secondePasseService.raisonsZoneFloue(
                    ConfianceEvaluation.parse(passe.feedback().get("confiance")),
                    competenceDe(passe.feedback(), passe.note()),
                    passe.niveauIa(), passe.niveauCalcule());
            if (!raisons.isEmpty()) {
                try {
                    EvaluationLlmClient client2 = secondePasseService.client();
                    EvaluationLlmClient.Outcome outcome2 = client2.evaluate(systemPrompt, userPrompt);
                    ProductionSecondePasseService.Passe passe2 = postProcess(
                            outcome2, client2.getModelName(), sub, task, verdict,
                            input.production(), submissionId);
                    passe = secondePasseService.arbitrer(passe, passe2, raisons, submissionId);
                    tokensIn += nz(outcome2.inputTokens());
                    tokensOut += nz(outcome2.outputTokens());
                    cout += nz(outcome2.costEstimateCents());
                } catch (RuntimeException e) {
                    log.warn("Seconde passe en echec submission={} ({}) — premiere passe conservee.",
                            submissionId, e.toString());
                }
            }
        }

        Map<String, Object> feedback = passe.feedback();
        // Indice de fluidite (debit + pauses longues), drapeau fluidite.enabled,
        // false par defaut. Ajoute EN DERNIER, apres note/niveau/plafonds :
        // structurellement, il ne peut influencer ni la note ni le niveau.
        Map<String, Object> fluidite = fluiditeService.indicateurs(sub, task, input.production());
        if (fluidite != null) {
            feedback.put("fluidite", fluidite);
        }

        AiEvaluation eval = new AiEvaluation();
        eval.setSubmission(sub);
        eval.setModeleUtilise(passe.modele());
        eval.setPromptVersion(llmClient.getPromptVersion());
        eval.setRubricsVersion(props.getRubricsVersion());
        eval.setNoteSur20(passe.note());
        eval.setNiveauCecrl(passe.niveauCalcule());
        eval.setNiveauCecrlIa(passe.niveauIa());
        eval.setFeedbackJson(feedback);
        eval.setTokensInput(tokensIn);
        eval.setTokensOutput(tokensOut);
        eval.setCoutEstimeCentimes(cout);
        aiEvaluationManager.save(eval);

        sub.setStatut(SubmissionStatut.EVALUATED);
        sub.setErreurMessage(null);
        submissionManager.save(sub);

        log.info("AiEvaluation persistee submission={} note={} niveau={} (LLM={}) model={}",
                submissionId, passe.note(), passe.niveauCalcule(), passe.niveauIa(), passe.modele());
        return eval;
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }

    /** Competence /20 (criteres porteurs du niveau) d'un feedback deja traite. */
    private BigDecimal competenceDe(Map<String, Object> feedback, BigDecimal note) {
        return ProductionBilanService.competence(
                feedback.get("scores_criteres"), props.getNiveauCecrl().getSourceCriteres(), note);
    }

    /**
     * Tous les traitements SERVEUR appliques a une reponse brute du LLM :
     * avertissements, confiance plafonnee, normalisations, note et niveau
     * recalcules, plafonds. Extrait pour que la seconde passe subisse
     * exactement le meme traitement que la premiere — sinon les deux ne
     * seraient pas comparables.
     */
    private ProductionSecondePasseService.Passe postProcess(
            EvaluationLlmClient.Outcome outcome, String modele,
            ProductionSubmission sub, ProductionTask task,
            ProductionValidityService.Verdict verdict, String production, UUID submissionId) {
        // Avertissements construits cote serveur (limite orale, longueur/duree,
        // controles de validite), injectes dans le feedback expose au front.
        // L'IA ne les produit pas elle-meme.
        Map<String, Object> feedback = new LinkedHashMap<>(outcome.feedback());
        List<String> avertissements = buildAvertissements(sub, task);
        avertissements.addAll(verdict.raisons());
        if (!avertissements.isEmpty()) {
            feedback.put("avertissements", avertissements);
        }
        // Confiance (schema v2) : lue, normalisee, puis PLAFONNEE serveur.
        applyConfiance(feedback, sub, verdict, submissionId);
        // Accomplissement (schema v2) : conserve tel quel, structure normalisee.
        // Aucun point `obligatoire: false` (une simple piste du sujet) n'entre
        // dans un quelconque calcul de note — c'est une regle produit.
        normalizeAccomplissement(feedback);
        // Preuves : une citation absente de la production a ete inventee par
        // l'IA -> on la retire plutot que de la montrer au candidat.
        stripPreuvesInventees(feedback, production, submissionId);
        // EO : `exemples_corriges` ne doit garder que des reformulations de
        // clarte (niveau phrase). On retire les corrections purement
        // orthographiques (accents/casse/ponctuation) et les corrections de mot
        // isole : a l'oral ce sont des artefacts de la transcription Whisper,
        // pas des erreurs du candidat. Filet deterministe en plus de la consigne
        // de prompt. EE : intact (l'orthographe compte a l'ecrit).
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            stripOrthographicCorrections(feedback);
        }
        // Joint le `label` des criteres a chaque score (le LLM ne renvoie que le
        // `code`). Source = la rubrique de la tache (fallback DB) : evite au mobile
        // de maintenir une table parallele code→libelle qui derive.
        enrichScoresWithLabels(feedback, task);
        // Bande qualitative par critere, derivee de note_sur_20 : ce sont les
        // fronts qui l'AFFICHENT a la place du nombre (une IA ne distingue pas
        // honnetement un 13 d'un 14). note_sur_20 reste dans le JSON.
        applyBandesCriteres(feedback);
        // « Au plus 2 points a ameliorer » : regle produit, donc garantie
        // SERVEUR. Le prompt et le maxItems du tool-schema la demandent, ils ne
        // la tiennent pas (83 evaluations sur 109 depassaient 2 en base).
        capPointsAAmeliorer(feedback);
        // note_globale calculee SERVEUR a partir des scores par critere ponderes
        // par la rubrique : on ecrase la valeur du LLM (advisory). Garantit la
        // coherence global <-> criteres. Si la rubrique est absente, on conserve
        // la note du LLM (extractNote la relira).
        applyServerComputedNote(feedback, task, submissionId);
        BigDecimal noteSur20 = extractNote(feedback);
        // niveau_cecrl du LLM = advisory (conserve en base pour la calibration,
        // jamais expose). Le niveau OBSERVE expose par tache est celui calcule
        // serveur depuis lexique+morphosyntaxe+coherence, comme note_globale —
        // toujours accompagne de sa confiance. On lit le brut AVANT d'ecraser
        // feedback.niveau_cecrl.
        NiveauCecrl niveauIa = extractNiveau(feedback);
        NiveauCecrl niveauCalcule = applyServerComputedNiveau(feedback, noteSur20, niveauIa, submissionId);
        // Plafonds cibles, APRES le calcul du niveau (jamais avant : ils
        // coupent un niveau, ils ne le fabriquent pas).
        niveauCalcule = applyPlafonds(feedback, task, niveauCalcule, submissionId);

        return new ProductionSecondePasseService.Passe(
                feedback, noteSur20, niveauIa, niveauCalcule, modele);
    }

    /**
     * Production jugee ineexploitable par les controles deterministes : aucun
     * appel LLM. On persiste quand meme une {@link AiEvaluation} (note 0,
     * {@code A1_NON_ATTEINT}, confiance {@code FAIBLE}) expliquant au candidat
     * pourquoi, et la submission passe a {@code EVALUATED} : l'utilisateur voit
     * un resultat, pas une erreur technique.
     */
    private AiEvaluation persistProductionInvalide(ProductionSubmission sub, ProductionTask task,
                                                   ProductionValidityService.Verdict verdict) {
        List<String> raisons = verdict.raisons();
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", BigDecimal.ZERO);
        feedback.put("niveau_cecrl", NiveauCecrl.A1_NON_ATTEINT.name());
        feedback.put("confiance", ConfianceEvaluation.FAIBLE.name());
        feedback.put("confiance_raisons", List.copyOf(raisons));
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(),
            "points_oublies", List.of()));
        feedback.put("scores_criteres", scoresNonEvaluables(task));
        feedback.put("points_forts", List.of());
        feedback.put("points_a_ameliorer", raisons.stream().limit(MAX_POINTS_A_AMELIORER).toList());
        feedback.put("suggestions", List.of());
        feedback.put("exemples_corriges", List.of());

        List<String> avertissements = buildAvertissements(sub, task);
        avertissements.addAll(raisons);
        feedback.put("avertissements", avertissements);

        AiEvaluation eval = new AiEvaluation();
        eval.setSubmission(sub);
        eval.setModeleUtilise(MODELE_VALIDATION_SERVEUR);
        eval.setPromptVersion(llmClient.getPromptVersion());
        eval.setRubricsVersion(props.getRubricsVersion());
        eval.setNoteSur20(BigDecimal.ZERO);
        eval.setNiveauCecrl(NiveauCecrl.A1_NON_ATTEINT);
        eval.setNiveauCecrlIa(null);
        eval.setFeedbackJson(feedback);
        eval.setTokensInput(0);
        eval.setTokensOutput(0);
        eval.setCoutEstimeCentimes(0);
        aiEvaluationManager.save(eval);

        sub.setStatut(SubmissionStatut.EVALUATED);
        sub.setErreurMessage(null);
        submissionManager.save(sub);

        log.info("Production jugee invalide (aucun appel LLM) submission={} raisons={}",
            sub.getId(), raisons);
        return eval;
    }

    /** Tous les criteres de la rubrique a 0, bande {@code NON_EVALUABLE}. */
    private List<Map<String, Object>> scoresNonEvaluables(ProductionTask task) {
        Object grille = rubrics.find(task.getEpreuve(), task.getTacheNumero())
            .map(r -> r.get("criteres")).orElse(null);
        if (!(grille instanceof List<?> criteres)) return List.of();
        List<Map<String, Object>> out = new ArrayList<>();
        for (Object c : criteres) {
            if (!(c instanceof Map<?, ?> m) || m.get("code") == null) continue;
            Map<String, Object> score = new LinkedHashMap<>();
            score.put("code", m.get("code").toString());
            if (m.get("label") != null) score.put("label", m.get("label").toString());
            score.put("note_sur_20", 0);
            score.put("bande", BandeCritere.NON_EVALUABLE.name());
            score.put("commentaire", "Ce critère n'a pas pu être évalué : votre production "
                + "n'était pas exploitable.");
            out.add(score);
        }
        return out;
    }

    /**
     * Confiance finale = {@code min(confiance IA, plafond serveur)} — on peut
     * abaisser la certitude annoncee par l'IA, jamais la relever. Plafonds :
     * <ul>
     *   <li>verdict {@code AVERTISSEMENT} (langue douteuse, consigne recopiee)
     *       → {@code MOYENNE} ;</li>
     *   <li>production issue d'un dialogue TEMPS REEL → {@code MOYENNE} : la
     *       transcription y est produite au fil de l'eau, elle est
     *       structurellement moins fiable qu'un texte rendu.</li>
     * </ul>
     * Une confiance absente ou hors enum vaut {@code MOYENNE} (+ log warn) :
     * l'absence d'information n'est pas une certitude.
     */
    private void applyConfiance(Map<String, Object> feedback, ProductionSubmission sub,
                                ProductionValidityService.Verdict verdict, UUID submissionId) {
        ConfianceEvaluation declaree = ConfianceEvaluation.parse(feedback.get("confiance"));
        if (declaree == null) {
            log.warn("confiance absente ou invalide ({}) submission={} — MOYENNE par defaut.",
                feedback.get("confiance"), submissionId);
            declaree = ConfianceEvaluation.MOYENNE;
        }

        List<String> raisonsServeur = new ArrayList<>();
        ConfianceEvaluation plafond = null;
        if (verdict.avertissement()) {
            plafond = ConfianceEvaluation.min(plafond, ConfianceEvaluation.MOYENNE);
            raisonsServeur.add("des vérifications automatiques ont signalé un doute sur cette production");
        }
        if (sub.getSource() == ProductionSubmissionSource.REALTIME) {
            plafond = ConfianceEvaluation.min(plafond, ConfianceEvaluation.MOYENNE);
            raisonsServeur.add("transcription produite en direct pendant l'échange, donc partiellement incertaine");
        }

        ConfianceEvaluation finale = ConfianceEvaluation.min(declaree, plafond);
        feedback.put("confiance", finale.name());
        if (finale != declaree) {
            log.info("Confiance degradee submission={} : IA={} -> serveur={} ({})",
                submissionId, declaree, finale, raisonsServeur);
            List<String> raisons = new ArrayList<>();
            Object existantes = feedback.get("confiance_raisons");
            if (existantes instanceof List<?> l) {
                for (Object r : l) if (r != null) raisons.add(r.toString());
            }
            raisons.addAll(raisonsServeur);
            feedback.put("confiance_raisons", raisons);
        }
    }

    /**
     * Garantit la presence du bloc {@code accomplissement} avec ses deux listes,
     * meme quand le LLM l'omet (ancien schema ou reponse partielle). On ne
     * REECRIT rien : la distinction {@code obligatoire} true/false vient de
     * l'IA et une piste ({@code obligatoire: false}) ne doit jamais peser sur
     * la note — aucun calcul de ce service ne la lit.
     */
    @SuppressWarnings("unchecked")
    private void normalizeAccomplissement(Map<String, Object> feedback) {
        Object raw = feedback.get("accomplissement");
        if (!(raw instanceof Map<?, ?> map)) {
            feedback.put("accomplissement", new LinkedHashMap<>(Map.of(
                "points_traites", List.of(),
                "points_oublies", List.of())));
            return;
        }
        Map<String, Object> acc = new LinkedHashMap<>((Map<String, Object>) map);
        acc.putIfAbsent("points_traites", List.of());
        acc.putIfAbsent("points_oublies", List.of());
        if (!(acc.get("points_traites") instanceof List<?>)) acc.put("points_traites", List.of());
        if (!(acc.get("points_oublies") instanceof List<?>)) acc.put("points_oublies", List.of());
        feedback.put("accomplissement", acc);
    }

    /**
     * Retire les {@code preuve} qui n'apparaissent PAS dans la production : ce
     * sont des citations inventees par l'IA, et une fausse citation detruit la
     * confiance du candidat dans toute la correction. Comparaison sur texte
     * normalise (accents/casse/ponctuation/espaces neutralises) pour tolerer
     * une recopie approximative sans tolerer une invention.
     */
    @SuppressWarnings("unchecked")
    private void stripPreuvesInventees(Map<String, Object> feedback, String production, UUID submissionId) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return;
        String haystack = normalizeForOrthoCompare(production == null ? "" : production);
        int retirees = 0;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            Object preuve = sm.get("preuve");
            if (preuve == null) continue;
            String needle = normalizeForOrthoCompare(preuve.toString());
            if (needle.isEmpty()) {
                sm.remove("preuve");
                continue;
            }
            if (!haystack.contains(needle)) {
                sm.remove("preuve");
                retirees++;
            }
        }
        if (retirees > 0) {
            log.warn("{} preuve(s) inventee(s) retiree(s) submission={} — citation absente de la production.",
                retirees, submissionId);
        }
    }

    /** Nombre maximum de points a ameliorer rendus au candidat. */
    static final int MAX_POINTS_A_AMELIORER = 2;

    /**
     * Tronque {@code points_a_ameliorer} a {@value #MAX_POINTS_A_AMELIORER}
     * entrees, dans l'ordre rendu par le LLM (les plus importantes d'abord,
     * comme demande dans la consigne). Une liste de 5 axes noie le candidat :
     * la regle produit est « deux priorites, pas un inventaire ».
     */
    private void capPointsAAmeliorer(Map<String, Object> feedback) {
        if (!(feedback.get("points_a_ameliorer") instanceof List<?> points)) return;
        if (points.size() <= MAX_POINTS_A_AMELIORER) return;
        log.info("points_a_ameliorer tronque : {} -> {}", points.size(), MAX_POINTS_A_AMELIORER);
        feedback.put("points_a_ameliorer",
                points.stream().limit(MAX_POINTS_A_AMELIORER).toList());
    }

    /**
     * Ajoute a chaque score sa {@code bande} qualitative (16-20 / 11-15 / 6-10 /
     * 1-5 / 0). Les fronts affichent la bande, plus le nombre.
     */
    @SuppressWarnings("unchecked")
    private void applyBandesCriteres(Map<String, Object> feedback) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            if (!(sm.get("note_sur_20") instanceof Number n)) continue;
            BandeCritere bande = BandeCritere.of(new BigDecimal(n.toString()));
            if (bande != null) sm.put("bande", bande.name());
        }
    }

    /**
     * Plafonds cibles appliques APRES le calcul du niveau. Seules les regles
     * objectivables a partir des criteres v4 sont retenues :
     * <ul>
     *   <li>T3 (EE ou EO) avec {@code prise_position} ≤ seuil : aucune opinion
     *       identifiable → le niveau observe ne peut pas depasser A2 ;</li>
     *   <li>EO T2 avec {@code conduite_echange} ≤ seuil : aucun veritable
     *       echange → meme plafond.</li>
     * </ul>
     * Le hors-sujet (note 0 → {@code A1_NON_ATTEINT}) est deja tranche par
     * {@code computeNiveau} : on ne le touche pas. Chaque plafond applique est
     * logue ET explique au candidat dans {@code avertissements}.
     *
     * @return le niveau eventuellement abaisse (jamais releve)
     */
    static final String PLAFOND_NIVEAU_KEY = "plafond_niveau";

    private NiveauCecrl applyPlafonds(Map<String, Object> feedback, ProductionTask task,
                                      NiveauCecrl niveau, UUID submissionId) {
        ProductionEvaluationProperties.Plafonds cfg = props.getPlafonds();
        if (!cfg.isEnabled() || niveau == null) return niveau;

        Map<String, BigDecimal> notes = notesParCode(feedback.get("scores_criteres"));
        int tache = task.getTacheNumero();
        NiveauCecrl out = niveau;

        BigDecimal prisePosition = notes.get("prise_position");
        if (tache == 3 && prisePosition != null
                && prisePosition.compareTo(BigDecimal.valueOf(cfg.getPrisePositionSeuil())) <= 0) {
            out = appliquerPlafond(feedback, out, cfg.getPrisePositionNiveauMax(), submissionId,
                "prise_position=" + prisePosition,
                "Aucune prise de position claire n'a été identifiée. Sur cette tâche, donner son "
                    + "avis et le défendre est attendu : le niveau observé est donc limité à "
                    + cfg.getPrisePositionNiveauMax().name().replace("_", " ") + ".");
        }

        BigDecimal conduiteEchange = notes.get("conduite_echange");
        if (task.getEpreuve() == EpreuveType.TCF_EO && tache == 2 && conduiteEchange != null
                && conduiteEchange.compareTo(BigDecimal.valueOf(cfg.getConduiteEchangeSeuil())) <= 0) {
            out = appliquerPlafond(feedback, out, cfg.getConduiteEchangeNiveauMax(), submissionId,
                "conduite_echange=" + conduiteEchange,
                "L'échange n'a pas vraiment eu lieu : vous n'avez pas mené le dialogue ni obtenu "
                    + "les informations attendues. Le niveau observé est donc limité à "
                    + cfg.getConduiteEchangeNiveauMax().name().replace("_", " ") + ".");
        }

        if (out != niveau) {
            feedback.put("niveau_cecrl", out.name());
            // Plafond PERSISTE dans le feedback : le bilan d'epreuve recalcule
            // sa propre competence depuis `scores_criteres` et ne lit pas
            // `niveau_cecrl` — sans cette trace, une tache plafonnee A2
            // ressortait B1/B2 au bilan, c'est-a-dire au seul niveau qui fait
            // foi. Cf. ProductionBilanService#competenceOf.
            feedback.put(PLAFOND_NIVEAU_KEY, out.name());
        }
        return out;
    }

    private NiveauCecrl appliquerPlafond(Map<String, Object> feedback, NiveauCecrl actuel,
                                         NiveauCecrl plafond, UUID submissionId,
                                         String declencheur, String raisonCandidat) {
        if (plafond == null || actuel.ordinal() <= plafond.ordinal()) return actuel;
        log.info("Plafond de niveau applique submission={} ({}) : {} -> {}",
            submissionId, declencheur, actuel, plafond);
        addAvertissement(feedback, raisonCandidat);
        return plafond;
    }

    @SuppressWarnings("unchecked")
    private static void addAvertissement(Map<String, Object> feedback, String message) {
        List<String> out = new ArrayList<>();
        if (feedback.get("avertissements") instanceof List<?> l) {
            for (Object o : l) if (o != null) out.add(o.toString());
        }
        out.add(message);
        feedback.put("avertissements", out);
    }

    /** Index {@code code -> note_sur_20} des scores exploitables. */
    private static Map<String, BigDecimal> notesParCode(Object scoresCriteres) {
        Map<String, BigDecimal> out = new HashMap<>();
        if (!(scoresCriteres instanceof List<?> scores)) return out;
        for (Object s : scores) {
            if (s instanceof Map<?, ?> m && m.get("code") != null
                    && m.get("note_sur_20") instanceof Number n) {
                out.put(m.get("code").toString(), new BigDecimal(n.toString()));
            }
        }
        return out;
    }

    /**
     * EO : ne conserve dans {@code exemples_corriges} que les vraies
     * reformulations de clarte (niveau phrase). Jette les entrees dont la
     * difference original/corrige est purement orthographique (accents, casse,
     * ponctuation -> normalisation identique) ou qui portent sur un MOT isole
     * (les deux cotes tiennent en un seul mot) : a l'oral, ce sont des artefacts
     * de transcription, pas des erreurs du candidat.
     */
    @SuppressWarnings("unchecked")
    private void stripOrthographicCorrections(Map<String, Object> feedback) {
        Object raw = feedback.get("exemples_corriges");
        if (!(raw instanceof List<?> list)) {
            return;
        }
        List<Object> kept = new ArrayList<>();
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> m)) {
                kept.add(item);
                continue;
            }
            String original = stringOrEmpty(m.get("original"));
            String corrige = stringOrEmpty(m.get("corrige"));
            String normOriginal = normalizeForOrthoCompare(original);
            String normCorrige = normalizeForOrthoCompare(corrige);
            boolean orthoOnly = normOriginal.equals(normCorrige);
            boolean motIsole = isSingleWord(normOriginal) && isSingleWord(normCorrige);
            if (!orthoOnly && !motIsole) {
                kept.add(item);
            }
        }
        feedback.put("exemples_corriges", kept);
    }

    private static String stringOrEmpty(Object o) {
        return o == null ? "" : o.toString();
    }

    private static boolean isSingleWord(String normalized) {
        return !normalized.isEmpty() && !normalized.contains(" ");
    }

    /**
     * Minuscules, accents retires, tout ce qui n'est pas lettre/chiffre reduit a
     * un espace, espaces normalises. Deux chaines egales apres ce traitement ne
     * different que par l'orthographe/casse/ponctuation.
     */
    private static String normalizeForOrthoCompare(String s) {
        String sansAccents = java.text.Normalizer
                .normalize(s, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return sansAccents
                .toLowerCase(java.util.Locale.FRENCH)
                .replaceAll("[^a-z0-9]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
    }

    /**
     * Avertissements affiches a l'utilisateur (construits serveur, hors IA) :
     * <ul>
     *   <li>EO : limite assumee « evaluation fondee sur la transcription »,
     *       TOUJOURS en tete (cf. {@link #AVERTISSEMENT_TRANSCRIPTION}) ;</li>
     *   <li>EE : depassement modere de la limite de mots (tolerance) ;</li>
     *   <li>EO : duree parlee sous la cible / sous le minimum (2 min).</li>
     * </ul>
     */
    private List<String> buildAvertissements(ProductionSubmission sub, ProductionTask task) {
        List<String> out = new ArrayList<>();
        if (task.getEpreuve() == EpreuveType.TCF_EE) {
            Integer mots = sub.getMotsCount();
            Integer max = task.getMotsMax();
            if (mots != null && max != null && mots > max) {
                out.add("Votre texte depasse legerement la limite (" + mots
                        + " mots pour un maximum de " + max + "). A l'examen, restez dans les bornes.");
            }
            return out;
        }
        // TCF_EO
        out.add(AVERTISSEMENT_TRANSCRIPTION);
        Integer duree = sub.getMediaDurationSec();
        Integer cible = task.getDureeMaxSec();
        Integer min = task.getDureeMinSec();
        if (duree != null && cible != null && duree < cible) {
            if (min != null && duree < min) {
                out.add("Votre enregistrement est court (" + duree + " s, soit environ "
                        + formatMinutes(duree) + "). Le minimum recommandé est de 2 minutes et l'objectif "
                        + cible + " s (~" + formatMinutes(cible) + "). Une production trop courte limite la "
                        + "démonstration de vos competences : votre note en tient compte. Rapprochez-vous "
                        + "de 3 minutes la prochaine fois.");
            } else {
                out.add("Vous avez parle " + duree + " s ; l'objectif est " + cible + " s (~"
                        + formatMinutes(cible) + "). Developpez davantage pour viser le niveau superieur.");
            }
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private void enrichScoresWithLabels(Map<String, Object> feedback, ProductionTask task) {
        Object scoresObj = feedback.get("scores_criteres");
        // Source UNIQUE des labels = la rubrique de la tache (meme source que les
        // criteres envoyes au LLM). Plus de fallback DB.
        Object grilleObj = rubrics.find(task.getEpreuve(), task.getTacheNumero())
                .map(r -> r.get("criteres"))
                .orElse(null);
        if (!(scoresObj instanceof List<?> scores) || !(grilleObj instanceof List<?> grille)) return;
        Map<String, String> labelByCode = new HashMap<>();
        for (Object g : grille) {
            if (g instanceof Map<?, ?> m) {
                Object code = m.get("code");
                Object label = m.get("label");
                if (code != null && label != null) {
                    labelByCode.put(code.toString(), label.toString());
                }
            }
        }
        if (labelByCode.isEmpty()) return;
        for (Object s : scores) {
            if (s instanceof Map<?, ?> rawMap) {
                Map<String, Object> sm = (Map<String, Object>) rawMap;
                Object existing = sm.get("label");
                if (existing == null || existing.toString().isBlank()) {
                    Object code = sm.get("code");
                    if (code != null) {
                        String lbl = labelByCode.get(code.toString());
                        if (lbl != null) sm.put("label", lbl);
                    }
                }
            }
        }
    }

    /**
     * Recalcule {@code note_globale} cote serveur = {@code round(Σ note_sur_20 × poids)}
     * a partir des {@code scores_criteres} et des poids de la rubrique, puis
     * <b>ecrase</b> la valeur du LLM dans {@code feedback}. La note du LLM devient
     * advisory : un ecart > seuil est logue (calibration). Sans rubrique ou sans
     * scores exploitables, on ne touche pas a la note du LLM.
     */
    private void applyServerComputedNote(Map<String, Object> feedback, ProductionTask task, UUID submissionId) {
        Object criteres = rubrics.find(task.getEpreuve(), task.getTacheNumero())
                .map(r -> r.get("criteres")).orElse(null);
        BigDecimal computed = weightedNote(criteres, feedback.get("scores_criteres"));
        if (computed == null) {
            log.warn("note_globale non recalculee serveur (submission={} : rubrique/scores manquants) — "
                    + "note LLM conservee.", submissionId);
            return;
        }
        BigDecimal llmNote = extractNote(feedback);
        if (llmNote != null && llmNote.subtract(computed).abs().compareTo(SEUIL_ECART_CALIBRATION) > 0) {
            log.warn("Ecart de notation submission={} : LLM={} vs serveur={} (>{}) — a calibrer.",
                    submissionId, llmNote, computed, SEUIL_ECART_CALIBRATION);
        }
        feedback.put("note_globale", computed);
    }

    /**
     * Calcule le {@code niveau_cecrl} SERVEUR depuis lexique+morphosyntaxe et le
     * persiste comme niveau affiche, en <b>ecrasant</b> {@code feedback.niveau_cecrl}
     * (le mobile lit ce champ). Le niveau du LLM ({@code niveauIa}) reste advisory.
     * Si un critere source manque, WARN + fallback sur la moyenne ponderee (note).
     * Logue un compteur de divergence (≥1 cran) IA vs calcul pour la calibration.
     *
     * @return le niveau calcule, ou le niveau LLM si le calcul est impossible.
     */
    private NiveauCecrl applyServerComputedNiveau(Map<String, Object> feedback, BigDecimal noteGlobale,
                                                  NiveauCecrl niveauIa, UUID submissionId) {
        List<String> sourceCodes = props.getNiveauCecrl().getSourceCriteres();
        Object scores = feedback.get("scores_criteres");
        if (!sourceCriteriaPresent(scores, sourceCodes)) {
            log.warn("niveau_cecrl : critere(s) porteur(s) {} manquant(s) dans scores_criteres "
                    + "(submission={}) — fallback sur la moyenne ponderee.", sourceCodes, submissionId);
        }
        NiveauCecrl calcule = ProductionBilanService.computeNiveau(
                scores, sourceCodes, noteGlobale, props.getNiveauCecrl());
        if (calcule == null) {
            log.warn("niveau_cecrl non calculable serveur (submission={}) — niveau LLM conserve.", submissionId);
            return niveauIa; // feedback.niveau_cecrl reste la valeur LLM
        }
        if (niveauIa != null && niveauIa != calcule) {
            String sens = niveauIa.ordinal() < calcule.ordinal() ? "sous-estimation LLM" : "sur-estimation LLM";
            log.info("Divergence niveau submission={} : LLM={} vs calcule={} ({}) — calibration.",
                    submissionId, niveauIa, calcule, sens);
        }
        feedback.put("niveau_cecrl", calcule.name());
        return calcule;
    }

    private ProductionInput loadInput(ProductionSubmission sub, ProductionTask task) {
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            Transcription t = transcriptionManager
                    .findLatestBySubmissionId(sub.getId())
                    .orElseThrow(() -> new AiEvaluationException(
                            "Submission EO " + sub.getId() + " sans transcription : Whisper a echoue ou n'a pas tourne."
                    ));
            return new ProductionInput(t.getTexte(), true);
        }
        // EE : texte rendu directement par l'utilisateur.
        if (sub.getTexteSoumis() == null || sub.getTexteSoumis().isBlank()) {
            throw new AiEvaluationException("Submission EE " + sub.getId() + " sans texte_soumis.");
        }
        return new ProductionInput(sub.getTexteSoumis(), false);
    }

    private record ProductionInput(String production, boolean litteral) {
    }
}
