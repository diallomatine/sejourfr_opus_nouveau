package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.BandeCritere;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObjectifTache;
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
import java.util.Set;
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
     * SEUL avertissement d'une production ORALE (2026-08-17). Il dit trois
     * choses et s'arrete la : on lit la transcription et pas la voix, cette
     * transcription peut se tromper sans que le candidat en paie le prix, et la
     * prononciation n'est donc pas notee.
     *
     * <p>Il a remplace un pave de trois paragraphes. Les deux autres
     * avertissements annoncaient une purge — c'est-a-dire une mecanique interne
     * dont le candidat n'a rien a faire, et que la deuxieme phrase couvre deja.
     * La mention « prononciation et aisance ne sont pas evaluees » est
     * CONSERVEE : la retirer laisserait croire que l'oral a ete juge dessus et
     * que c'est bon. Le renvoi a l'examen officiel, lui, a sa place dans
     * {@code docs/notation-ia-eo-ee.md}, pas sur une carte de resultat.
     */
    static final String AVERTISSEMENT_TRANSCRIPTION =
        "Nous analysons la transcription écrite de votre enregistrement, pas votre voix — "
            + "et la transcription peut se tromper. Dans ce cas, l'erreur ne vous est jamais "
            + "comptée. La prononciation et l'aisance ne sont donc pas évaluées ici.";

    static final String AVERTISSEMENT_PREUVE_RETIREE =
        "Une des quatre citations justificatives n'a pas pu être reliée de façon sûre "
            + "à votre production après vérification. Elle a été retirée : aucune citation "
            + "non vérifiée n'est affichée. La confiance de cette évaluation est donc au "
            + "maximum moyenne — elle reste faible si elle l'était déjà.";

    static final String RAISON_CONFIANCE_PREUVE_RETIREE =
        "une citation justificative n'a pas pu être vérifiée et a été retirée";

    /** Resume du verdict quand la production n'a pas pu etre exploitee du tout. */
    static final String RESUME_OBJECTIF_PRODUCTION_INVALIDE =
        "Votre production n'a pas pu être exploitée : la consigne n'a pas été traitée.";

    /** Trace du modele quand aucun LLM n'a ete appele (production jugee inevaluable). */
    /**
     * Marqueur de LA ligne produite SANS aucun appel LLM : le serveur a juge la
     * production inexploitable et a decide seul. Partage avec la voie diagnostic
     * ({@code DiagnosticProductionAnalysisService}) pour qu'une seule valeur
     * reponde partout a « cette ligne a-t-elle coute un appel ? ».
     */
    public static final String MODELE_VALIDATION_SERVEUR = "validation-serveur";

    private record ValidatedOutcome(
        EvaluationLlmClient.Outcome outcome,
        List<String> avertissements
    ) {
    }

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final EvaluationLlmClient llmClient;
    private final EvaluationPromptBuilder promptBuilder;
    private final ProductionRubricsProvider rubrics;
    private final ProductionValidityService validityService;
    private final ProductionSecondePasseService secondePasseService;
    private final ProductionFluiditeService fluiditeService;
    private final EvaluationRefusalMetrics refusalMetrics;
    private final EvaluationPurgeMetrics purgeMetrics;
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
     * {@code Σ note_sur_20[code] × poids[code]}, arrondi a UNE DECIMALE (HALF_UP),
     * borne a [0,20]. Retourne null si les criteres/poids ou les scores sont
     * inexploitables (le hors-sujet — tous les criteres a 0 — rend coherent 0,
     * puisque Σ(0×poids)=0). Package-private pour le test unitaire.
     *
     * <p><b>Une decimale, et pas l'entier</b> : depuis v5 le niveau se lit sur la
     * note. Avec quatre criteres a 0,25, la moyenne tombe sur des quarts de
     * point ; arrondir a l'entier faisait afficher « 13/20 » a cote d'un niveau
     * A2 calcule sur 12,5 — exactement la contradiction que la grille du TCF
     * doit faire disparaitre. Arrondir le niveau plutot que la note a ete mesure
     * comme PIRE (38 -> 35 classements exacts sur la campagne v5) : c'est donc
     * la note qui garde la decimale.
     */
    static BigDecimal weightedNote(Object criteres, Object scoresCriteres) {
        if (!(criteres instanceof List<?> critList) || !(scoresCriteres instanceof List<?> scores)) {
            return null;
        }
        Map<String, BigDecimal> poidsByCode = new LinkedHashMap<>();
        for (Object c : critList) {
            if (!(c instanceof Map<?, ?> m) || m.get("code") == null
                    || !(m.get("poids") instanceof Number n)) return null;
            String code = m.get("code").toString();
            if (poidsByCode.containsKey(code)) return null;
            try {
                BigDecimal poids = new BigDecimal(n.toString());
                if (poids.compareTo(BigDecimal.ZERO) < 0) return null;
                poidsByCode.put(code, poids);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        if (poidsByCode.isEmpty() || scores.size() != poidsByCode.size()) return null;

        Map<String, BigDecimal> notesByCode = new HashMap<>();
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> m)) return null;
            Object code = m.get("code");
            Object note = m.get("note_sur_20");
            if (code == null || !(note instanceof Number noteNum)) return null;
            String codeValue = code.toString();
            if (!poidsByCode.containsKey(codeValue) || notesByCode.containsKey(codeValue)) return null;
            try {
                BigDecimal value = new BigDecimal(noteNum.toString());
                if (value.compareTo(BigDecimal.ZERO) < 0 || value.compareTo(NOTE_MAX) > 0) return null;
                notesByCode.put(codeValue, value);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        if (!notesByCode.keySet().equals(poidsByCode.keySet())) return null;

        BigDecimal sum = BigDecimal.ZERO;
        for (Map.Entry<String, BigDecimal> entry : poidsByCode.entrySet()) {
            sum = sum.add(notesByCode.get(entry.getKey()).multiply(entry.getValue()));
        }
        BigDecimal rounded = sum.setScale(1, RoundingMode.HALF_UP);
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

        // Contrat v6 : la production part DECOUPEE EN SEGMENTS NUMEROTES et le
        // correcteur ne renvoie qu'un numero. Une meme decoupe sert au prompt, a
        // la validation et a la resolution — elle est deterministe, donc les
        // trois lisent exactement la meme chose.
        EvaluationProductionSegments segments = preuveParNumero(llmClient.getPromptVersion())
                ? EvaluationProductionSegments.of(input.production(), task.getEpreuve())
                : null;
        if (segments != null && segments.taille() == 0) {
            throw new AiEvaluationException("Aucun segment citable dans la production de la submission "
                    + submissionId + " : rien a soumettre au correcteur.");
        }

        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(
                task, input.production(), input.litteral(), null, segments);

        ValidatedOutcome validated = evaluateValidated(
                llmClient, systemPrompt, userPrompt, task, input.production(), submissionId);
        EvaluationLlmClient.Outcome outcome = validated.outcome();
        ProductionSecondePasseService.Passe passe = postProcess(
                outcome, llmClient.getModelName(), llmClient.getPromptVersion(), segments,
                sub, task, verdict, input.production(), validated.avertissements(), submissionId);

        int tokensIn = nz(outcome.inputTokens());
        int tokensCache = nz(outcome.cachedInputTokens());
        int tokensOut = nz(outcome.outputTokens());
        int cout = nz(outcome.costEstimateMicroUsd());

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
                    ValidatedOutcome validated2 = evaluateValidated(
                            client2, systemPrompt, userPrompt, task, input.production(), submissionId);
                    EvaluationLlmClient.Outcome outcome2 = validated2.outcome();
                    ProductionSecondePasseService.Passe passe2 = postProcess(
                            outcome2, client2.getModelName(), client2.getPromptVersion(), segments,
                            sub, task, verdict, input.production(), validated2.avertissements(),
                            submissionId);
                    passe = secondePasseService.arbitrer(passe, passe2, raisons, submissionId);
                    tokensIn += nz(outcome2.inputTokens());
                    tokensCache += nz(outcome2.cachedInputTokens());
                    tokensOut += nz(outcome2.outputTokens());
                    cout += nz(outcome2.costEstimateMicroUsd());
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
        eval.setTokensInputCacheHit(tokensCache);
        eval.setTokensOutput(tokensOut);
        eval.setCoutMicroUsd(cout);
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

    /**
     * Validation semantique commune a tous les providers. Une sortie brute
     * invalide est rejouee une seule fois avec la liste des violations. Apres
     * ce retry, une unique preuve non rattachable peut etre retiree en mode
     * degrade ; toute autre violation interdit le post-traitement.
     */
    private ValidatedOutcome evaluateValidated(
            EvaluationLlmClient client, String systemPrompt, String userPrompt,
            ProductionTask task, String production, UUID submissionId) {
        EvaluationLlmClient.Outcome first = client.evaluate(systemPrompt, userPrompt);
        List<String> violations = EvaluationOutputValidator.violations(
                first.feedback(), task, rubrics, client.getPromptVersion(), production);
        if (violations.isEmpty()) return new ValidatedOutcome(first, List.of());

        // COMPTEUR PAR MOTIF, pas seulement une trace : sans lui on ne savait pas,
        // en exploitation, ce que nos propres controles refusaient (cf.
        // EvaluationRefusalMetrics). La liste brute reste logue pour le debug.
        EvaluationRefusalMetrics.Refus refus = refusalMetrics.enregistrer(
                EvaluationRefusalMetrics.Phase.PREMIER_APPEL, violations, first.feedback());
        log.warn("Sortie LLM refusee submission={} modele={} phase=PREMIER_APPEL motifs={} "
                        + "citations_refusees={} cumul={} — retry semantique unique : {}",
                submissionId, client.getModelName(), refus.motifs(), refus.citationsRefusees(),
                refusalMetrics.compteurs(), violations);
        // Le reessai rappelle la citation refusee critere par critere et enonce
        // la regle de la preuve : sans cela il ne reparait rien (cf.
        // EvaluationRepairPrompt). Aucun controle n'est relache pour autant.
        String repairPrompt = EvaluationRepairPrompt.build(
                userPrompt, violations, first.feedback(),
                task == null ? null : task.getEpreuve(),
                EvaluationToolSchema.of(client.getPromptVersion()));
        EvaluationLlmClient.Outcome repaired = client.evaluate(systemPrompt, repairPrompt);
        List<String> remaining = EvaluationOutputValidator.violations(
                repaired.feedback(), task, rubrics, client.getPromptVersion(), production);
        if (!remaining.isEmpty()) {
            EvaluationRefusalMetrics.Refus refusFinal = refusalMetrics.enregistrer(
                    EvaluationRefusalMetrics.Phase.APRES_REESSAI, remaining, repaired.feedback());
            log.warn("Sortie LLM refusee submission={} modele={} phase=APRES_REESSAI motifs={} "
                            + "citations_refusees={} cumul={}",
                    submissionId, client.getModelName(), refusFinal.motifs(),
                    refusFinal.citationsRefusees(), refusalMetrics.compteurs());
            // Le mode degrade n'existe que sur les contrats STRICTS (v4 et
            // au-dela) : ce sont les seuls a exiger une preuve. v6+ y reste
            // eligible, meme si le cas y devient tres improbable — un numero hors
            // bornes est l'exact equivalent d'une citation non rattachable, et
            // perdre une correction entiere pour un entier faux serait le defaut
            // qu'on vient justement de supprimer.
            var unmatchedProof = EvaluationToolSchema.of(client.getPromptVersion()).strict()
                ? EvaluationOutputValidator.singleUnmatchedProofCode(remaining)
                : java.util.Optional.<String>empty();
            if (unmatchedProof.isPresent()) {
                Map<String, Object> degraded = removeUnverifiedProof(
                    repaired.feedback(), unmatchedProof.get());
                log.warn("Sortie LLM degradee submission={} modele={} — preuve[{}] retiree "
                        + "apres le retry semantique.",
                    submissionId, client.getModelName(), unmatchedProof.get());
                return new ValidatedOutcome(
                    aggregateOutcomes(first, repaired, degraded),
                    List.of(AVERTISSEMENT_PREUVE_RETIREE));
            }
            throw new AiEvaluationException("Sortie LLM invalide apres une tentative de reparation : "
                + String.join(" ; ", remaining));
        }
        return new ValidatedOutcome(aggregateOutcomes(first, repaired, repaired.feedback()), List.of());
    }

    private static EvaluationLlmClient.Outcome aggregateOutcomes(
            EvaluationLlmClient.Outcome first, EvaluationLlmClient.Outcome repaired,
            Map<String, Object> feedback) {
        return new EvaluationLlmClient.Outcome(
            feedback,
            sumNullable(first.inputTokens(), repaired.inputTokens()),
            sumNullable(first.cachedInputTokens(), repaired.cachedInputTokens()),
            sumNullable(first.outputTokens(), repaired.outputTokens()),
            sumNullable(first.costEstimateMicroUsd(), repaired.costEstimateMicroUsd()));
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> removeUnverifiedProof(
            Map<String, Object> rawFeedback, String criterionCode) {
        Map<String, Object> feedback = new LinkedHashMap<>(rawFeedback);
        if (!(rawFeedback.get("scores_criteres") instanceof List<?> rawScores)) {
            throw new AiEvaluationException("Impossible de retirer la preuve non verifiee : scores absents.");
        }
        if (rawScores.size() != 4) {
            throw new AiEvaluationException(
                "Impossible de degrader une evaluation qui ne porte pas exactement quatre criteres.");
        }

        List<Object> scores = new ArrayList<>();
        int removed = 0;
        for (Object rawScore : rawScores) {
            if (!(rawScore instanceof Map<?, ?> rawMap)) {
                scores.add(rawScore);
                continue;
            }
            Map<String, Object> score = new LinkedHashMap<>((Map<String, Object>) rawMap);
            if (criterionCode.equals(String.valueOf(score.get("code")))) {
                // Contrat v6 : la preuve est un numero, la retirer est la meme
                // operation. Un seul des deux champs existe a la fois.
                Object retiree = score.remove("preuve");
                if (retiree == null) retiree = score.remove("preuve_segment");
                if (retiree != null) removed++;
            }
            scores.add(score);
        }
        if (removed != 1) {
            throw new AiEvaluationException("Impossible de retirer exactement une preuve non verifiee.");
        }
        feedback.put("scores_criteres", scores);

        ConfianceEvaluation confiance = ConfianceEvaluation.min(
            ConfianceEvaluation.parse(feedback.get("confiance")), ConfianceEvaluation.MOYENNE);
        feedback.put("confiance", confiance.name());
        List<String> raisons = new ArrayList<>();
        if (feedback.get("confiance_raisons") instanceof List<?> existing) {
            for (Object raison : existing) {
                if (raison != null && !RAISON_CONFIANCE_PREUVE_RETIREE.equals(raison.toString())
                        && raisons.size() < 2) {
                    raisons.add(raison.toString());
                }
            }
        }
        raisons.add(RAISON_CONFIANCE_PREUVE_RETIREE);
        feedback.put("confiance_raisons", raisons);
        return feedback;
    }

    private static Integer sumNullable(Integer a, Integer b) {
        if (a == null && b == null) return null;
        return nz(a) + nz(b);
    }

    /** Competence /20 (criteres porteurs du niveau) d'un feedback deja traite. */
    private BigDecimal competenceDe(Map<String, Object> feedback, BigDecimal note) {
        return ProductionBilanService.competence(
                feedback.get("scores_criteres"), rubrics.niveauCecrl().getSourceCriteres(), note);
    }

    /**
     * Tous les traitements SERVEUR appliques a une reponse brute du LLM :
     * avertissements, confiance plafonnee, normalisations, note et niveau
     * recalcules, plafonds. Extrait pour que la seconde passe subisse
     * exactement le meme traitement que la premiere — sinon les deux ne
     * seraient pas comparables.
     */
    private ProductionSecondePasseService.Passe postProcess(
            EvaluationLlmClient.Outcome outcome, String modele, String toolSchemaVersion,
            EvaluationProductionSegments segments,
            ProductionSubmission sub, ProductionTask task,
            ProductionValidityService.Verdict verdict, String production,
            List<String> validationWarnings, UUID submissionId) {
        // Avertissements construits cote serveur (limite orale, longueur/duree,
        // controles de validite), injectes dans le feedback expose au front.
        // L'IA ne les produit pas elle-meme.
        Map<String, Object> feedback = new LinkedHashMap<>(outcome.feedback());
        List<String> avertissements = buildAvertissements(sub, task);
        avertissements.addAll(verdict.raisons());
        avertissements.addAll(validationWarnings);
        if (!avertissements.isEmpty()) {
            feedback.put("avertissements", avertissements);
        }
        // QUALITE DE LA TRANSCRIPTION, mesuree sur le texte que LIT le
        // correcteur. Deux usages, et deux seulement : plafonner la confiance
        // (obstacle a l'observation) et elargir le volet FORME du filet oral.
        // Ni la note, ni le niveau, ni un seuil n'en dependent. A l'ecrit, on ne
        // mesure rien : aucune machine ne s'interpose entre le candidat et son
        // texte.
        TranscriptionQualityAudit.Mesure qualite = task.getEpreuve() == EpreuveType.TCF_EO
            ? TranscriptionQualityAudit.mesurer(production)
            : TranscriptionQualityAudit.Mesure.nonMesurable(0);
        logQualiteTranscription(qualite, sub, submissionId);
        // Confiance (schema v2) : lue, normalisee, puis PLAFONNEE serveur.
        applyConfiance(feedback, sub, verdict, qualite, submissionId);
        // Accomplissement (schema v2) : conserve tel quel, structure normalisee.
        // Aucun point `obligatoire: false` (une simple piste du sujet) n'entre
        // dans un quelconque calcul de note — c'est une regle produit.
        normalizeAccomplissement(feedback);
        // VERDICT (schema v5) : le serveur ne l'invente pas, il le corrige dans
        // le sens PRUDENT quand il se contredit lui-meme — jamais l'inverse,
        // exactement comme la confiance, qu'il peut abaisser mais pas relever.
        applyObjectifCoherence(feedback, submissionId);
        // `version_amelioree` (schemas v5 a v7). Deux raisons de la retirer, et
        // le retrait est le meme :
        //   - EO : elle n'a aucun sens sur un echange oral — on ne rend pas au
        //     candidat un dialogue modele, et le garde-fou oral interdit de
        //     parler de la forme orale ;
        //   - contrat v8 : elle a quitte le schema. Plus aucun front ne
        //     l'affiche (le texte modele rendu au candidat est `version_ciblee`,
        //     produit par un appel separe), et elle reecrivait la production AU
        //     MEME NIVEAU que le candidat. Le schema ferme suffit en theorie ;
        //     ce filet garantit qu'une sortie recalcitrante n'en persiste pas.
        if (task.getEpreuve() == EpreuveType.TCF_EO || !versionAmelioree(toolSchemaVersion)) {
            feedback.remove(CHAMP_VERSION_AMELIOREE);
        }
        // `exemples_corriges` et `suggestions` (contrats <= v8). Sous v9 ils ont
        // quitte le schema : le bloc replie « Voir l'analyse complete » qui les
        // affichait a disparu de l'ecran de resultat, et on ne paie plus des
        // tokens de sortie pour des paves que personne ne lit. Le schema ferme
        // suffit en theorie ; ce filet garantit qu'une sortie recalcitrante n'en
        // persiste pas — exactement comme pour `version_amelioree`. Retire ICI,
        // donc avant les filtres et les plafonds : tout ce qui suit et qui les
        // lit devient un no-op, sans qu'aucun de ces traitements ait a connaitre
        // la version du contrat.
        if (!exemplesEtSuggestions(toolSchemaVersion)) {
            CHAMPS_RESTITUTION_LONGUE.forEach(feedback::remove);
        }
        // PREUVE. Deux chemins, un seul resultat pour les fronts : le champ
        // `preuve` du feedback porte TOUJOURS un extrait litteral de la
        // production, jamais une recopie approximative ou inventee.
        //   - contrat v6 : le correcteur a renvoye un NUMERO de segment, deja
        //     valide comme existant ; le serveur le remplace par le texte exact
        //     du segment. Aucun rapprochement, donc aucun refus possible ;
        //   - contrats anterieurs : le correcteur a recopie un extrait, deja
        //     rapproche par le validateur (sauf l'unique preuve retiree apres un
        //     second appel autrement valide) ; on le remplace par sa sous-chaine
        //     originale exacte, et une preuve sans match conservateur est
        //     retiree.
        if (preuveParNumero(toolSchemaVersion)) {
            resolvePreuveSegments(feedback, segments, submissionId);
        } else {
            canonicalizePreuves(feedback, production, task.getEpreuve(), submissionId);
        }
        // EO : `exemples_corriges` ne doit garder que des reformulations de
        // clarte (niveau phrase). On retire les corrections purement
        // orthographiques (accents/casse/ponctuation) et les corrections de mot
        // isole : a l'oral ce sont des artefacts de la transcription Whisper,
        // pas des erreurs du candidat. Filet deterministe en plus de la consigne
        // de prompt. EE : intact (l'orthographe compte a l'ecrit).
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            stripOrthographicCorrections(feedback);
            // MEME LOGIQUE, ETENDUE AUX AUTRES CHAMPS DE RESTITUTION
            // (commentaires de critere, priorites, suggestions) : un reproche
            // adosse a UN SEUL mot de la transcription est un artefact de
            // reconnaissance vocale, pas une erreur du candidat. Purge egalement
            // les exemples corriges qui se fondent sur une notion orale
            // interdite — ce champ n'entre dans aucun calcul, le rejeter
            // detruisait des evaluations entieres. Aucun effet sur la note :
            // tout ceci est de la restitution, appliquee avant le calcul mais
            // sur des champs qu'aucun calcul ne lit.
            var purge = EvaluationOralArtifactFilter.purge(feedback, production, qualite.degradee());
            if (purge.aPurge()) {
                log.info("Restitution orale purgee submission={} : {} remarque(s) de niveau mot, "
                        + "{} remarque(s) de langue etrangere, {} reproche(s) de forme en "
                        + "morphosyntaxe, {} exemple(s) corrige(s) fondes sur un element non "
                        + "evaluable.",
                    submissionId, purge.remarquesRetirees(), purge.remarquesLangueRetirees(),
                    purge.remarquesFormeRetirees(), purge.exemplesRetires());
            }
            // 🛑 UNE PURGE NE S'ANNONCE PLUS AU CANDIDAT (2026-08-17). Les trois
            // avertissements dedies (mot isole / langue etrangere / forme en
            // morphosyntaxe) lui expliquaient une MECANIQUE INTERNE dont il n'a
            // rien a faire, et empilaient un pave de trois paragraphes sous son
            // resultat. Ce qu'il doit savoir tient dans l'unique
            // AVERTISSEMENT_TRANSCRIPTION : la transcription peut se tromper, et
            // dans ce cas l'erreur ne lui est jamais comptee — c'est exactement
            // ce que ces trois filets garantissent. La TRACE, elle, reste
            // entiere : les purges continuent et sont comptees juste en dessous.
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.ARTEFACT_ORAL_MOT,
                purge.remarquesRetirees(), 0);
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.ARTEFACT_ORAL_LANGUE,
                purge.remarquesLangueRetirees(), purge.exemplesRetires());
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.ARTEFACT_ORAL_FORME,
                purge.remarquesFormeRetirees(), 0);
        }
        // Joint le `label` des criteres a chaque score (le LLM ne renvoie que le
        // `code`). Source = la rubrique de la tache (fallback DB) : evite au mobile
        // de maintenir une table parallele code→libelle qui derive.
        enrichScoresWithLabels(feedback, task);
        // Forme unique de points_a_ameliorer pour les fronts (objets
        // {constat, comment, exemple}), quelle que soit la version de schema.
        feedback.put("points_a_ameliorer", normalizePointsAAmeliorer(feedback.get("points_a_ameliorer")));
        // « Au plus 2 points a ameliorer », « au plus 2 points forts », « au
        // plus 3 exemples corriges » : regles produit, donc garanties SERVEUR.
        // Le prompt et les `maxItems` du tool-schema les demandent, ils ne les
        // tiennent pas (83 evaluations sur 109 depassaient 2 priorites en base).
        capPointsAAmeliorer(feedback);
        capListe(feedback, "points_forts", MAX_POINTS_FORTS);
        capListe(feedback, "exemples_corriges", MAX_EXEMPLES_CORRIGES);
        // GARDE-FOU DE COUPLAGE, AVANT le calcul de la note : les criteres de
        // realisation (communiquer / interagir) ne depassent pas de plus de
        // `ecart-max` la moyenne des criteres de langue. Depuis v5 ils pesent la
        // moitie de la note, donc du niveau : c'est ce filet qui empeche une
        // consigne bien cochee en francais pauvre de faire monter d'un palier.
        applyCouplage(feedback, submissionId);
        // Bande qualitative par critere, derivee de note_sur_20 : ce sont les
        // fronts qui l'AFFICHENT a la place du nombre (une IA ne distingue pas
        // honnetement un 13 d'un 14). note_sur_20 reste dans le JSON. APRES le
        // couplage : sinon la bande affichee decrirait la note d'AVANT le
        // plafonnement, et contredirait le nombre qui l'accompagne.
        applyBandesCriteres(feedback);
        // note_globale calculee SERVEUR a partir des scores par critere ponderes
        // par la rubrique : on ecrase la valeur du LLM (advisory). Garantit la
        // coherence global <-> criteres. Une anomalie est bloquante : aucun
        // fallback vers une note LLM partielle n'est persiste.
        applyServerComputedNote(feedback, task, submissionId);
        BigDecimal noteSur20 = extractNote(feedback);
        // niveau_cecrl du LLM = advisory (conserve en base pour la calibration,
        // jamais expose). Le niveau OBSERVE expose par tache est celui calcule
        // serveur depuis les criteres porteurs de la grille active (v5 : les
        // quatre, donc la note elle-meme), comme note_globale — toujours
        // accompagne de sa confiance. On lit le brut AVANT d'ecraser
        // feedback.niveau_cecrl.
        NiveauCecrl niveauIa = extractNiveau(feedback);
        NiveauCecrl niveauCalcule = applyServerComputedNiveau(feedback, noteSur20, niveauIa, submissionId);
        // Plafonds cibles, APRES le calcul du niveau (jamais avant : ils
        // coupent un niveau, ils ne le fabriquent pas).
        niveauCalcule = applyPlafonds(feedback, task, niveauCalcule, submissionId);
        // MARQUEUR A2 VENDU COMME LEVIER D'UN PALIER SUPERIEUR : on retire la
        // promesse fausse du rapport. APRES le calcul du niveau, parce que le
        // filet a besoin du niveau REELLEMENT constate pour trancher une formule
        // relative (« gagner un niveau » depuis A1 vise A2 : c'est legitime).
        // Aucun effet sur la note ni sur le niveau — ils sont deja arretes.
        appliquerFiltreMarqueurPalier(feedback, niveauCalcule, submissionId);
        // AUDIT D'ACCENTUATION : on MESURE le francais desaccentue rendu au
        // candidat, on ne refuse rien. Cf. EvaluationAccentAudit : une
        // soumission perdue coute plus cher au candidat qu'un accent manquant.
        auditAccents(feedback, submissionId);

        return new ProductionSecondePasseService.Passe(
                feedback, noteSur20, niveauIa, niveauCalcule, modele);
    }

    /**
     * Retire du rapport les remarques qui presentent un moyen classe A2 par la
     * grille active (« parce que », « mais », « et »...) comme la cle du palier
     * superieur. Le proprietaire a suivi un tel conseil, resoumis, et obtenu la
     * meme note : il etait structurellement incapable de le faire progresser.
     *
     * <p>Ni la note, ni le niveau, ni un seuil ne bougent — c'est de la
     * restitution, comme le filet oral. Cf. {@link EvaluationPalierMarqueurFilter}.
     */
    private void appliquerFiltreMarqueurPalier(Map<String, Object> feedback,
                                               NiveauCecrl constate, UUID submissionId) {
        EvaluationPalierMarqueurFilter.Resultat purge =
            EvaluationPalierMarqueurFilter.purge(feedback, constate);
        if (!purge.aPurge()) return;
        log.info("Marqueur A2 presente comme levier de palier superieur, purge submission={} : "
                + "{} remarque(s), {} entree(s) supprimee(s) (niveau constate={}).",
            submissionId, purge.remarquesRetirees(), purge.entreesRetirees(), constate);
        addAvertissement(feedback, EvaluationPalierMarqueurFilter.AVERTISSEMENT_MARQUEUR_PALIER);
        purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER,
            purge.remarquesRetirees(), purge.entreesRetirees());
    }

    /**
     * OBSERVABILITE de la qualite de transcription. Une ligne par evaluation
     * orale, avec les deux taux et la source : c'est ce qui manquait pour voir le
     * bug « mot coupe en deux » (28 juin → 4 juillet 2026), reste six semaines en
     * production parce qu'aucun chiffre ne le disait. Les taux sont AUSSI
     * persistes sur {@code transcriptions}, pour que la meme question se pose en
     * une requete SQL plutot qu'en fouillant des logs.
     */
    private void logQualiteTranscription(TranscriptionQualityAudit.Mesure qualite,
                                         ProductionSubmission sub, UUID submissionId) {
        if (!qualite.mesurable()) return;
        if (qualite.degradee()) {
            log.warn("Transcription DEGRADEE submission={} source={} mots={} formesSuspectes={} "
                    + "collages={} formes={}",
                submissionId, sub.getSource(), qualite.mots(),
                pourcent(qualite.tauxFormesSuspectes()), pourcent(qualite.tauxCollages()),
                qualite.formes());
            return;
        }
        log.info("Qualite transcription submission={} source={} mots={} formesSuspectes={} "
                + "collages={}",
            submissionId, sub.getSource(), qualite.mots(),
            pourcent(qualite.tauxFormesSuspectes()), pourcent(qualite.tauxCollages()));
    }

    private static String pourcent(double taux) {
        return String.format(java.util.Locale.ROOT, "%.2f%%", taux * 100);
    }

    /**
     * Compte le francais DESACCENTUE rendu au candidat, sans jamais refuser la
     * sortie ni la modifier. C'est un capteur : il dit si la consigne
     * d'accentuation (rubriques v13 / tool-schema v7) prend, et permet de
     * decider plus tard, sur des chiffres, s'il faut durcir.
     */
    private void auditAccents(Map<String, Object> feedback, UUID submissionId) {
        EvaluationAccentAudit.Resultat audit = EvaluationAccentAudit.analyser(feedback);
        if (!audit.aDetecte()) return;
        log.warn("Francais desaccentue rendu au candidat submission={} : {} occurrence(s) "
                + "dans {} champ(s), formes={}",
            submissionId, audit.occurrences(), audit.champsTouches(), audit.formes());
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
        // Verdict explicite (schema v5) : une production inexploitable ne repond
        // pas a la consigne. On le dit en une phrase, sans jargon, plutot que de
        // laisser le front deviner.
        Map<String, Object> accomplissement = new LinkedHashMap<>();
        accomplissement.put("objectif", ObjectifTache.NON_ATTEINT.name());
        accomplissement.put("objectif_resume", RESUME_OBJECTIF_PRODUCTION_INVALIDE);
        accomplissement.put("points_traites", List.of());
        accomplissement.put("points_oublies", List.of());
        feedback.put("accomplissement", accomplissement);
        feedback.put("scores_criteres", scoresNonEvaluables(task));
        feedback.put("points_forts", List.of());
        feedback.put("points_a_ameliorer", normalizePointsAAmeliorer(
                raisons.stream().limit(MAX_POINTS_A_AMELIORER).toList()));
        // Ces deux champs ne sont poses que si le contrat ACTIF les porte encore
        // (<= v8). Sous v9 ils n'existent plus : les ecrire ici fabriquerait,
        // sur le seul chemin qui n'appelle aucun LLM, deux cles que le reste du
        // pipeline retire — et que plus aucun ecran ne lit.
        if (exemplesEtSuggestions(llmClient.getPromptVersion())) {
            feedback.put("suggestions", List.of());
            feedback.put("exemples_corriges", List.of());
        }

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
        eval.setCoutMicroUsd(0);
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
     *   <li>avertissement traduisant un obstacle a l'OBSERVATION (langue
     *       partiellement non francaise) → {@code MOYENNE} : on ne lit pas bien
     *       ce que le candidat produit, la correction est donc moins sure ;</li>
     *   <li>production issue d'un dialogue TEMPS REEL → {@code MOYENNE} : la
     *       transcription y est produite au fil de l'eau, elle est
     *       structurellement moins fiable qu'un texte rendu.</li>
     * </ul>
     * <p>Un avertissement d'AUTHENTICITE (consigne partiellement recopiee) ne
     * plafonne <b>rien</b> : le candidat est prevenu, seuls ses propres mots
     * sont notes, et ce qui reste est parfaitement observable. Convertir un
     * soupcon d'origine en incertitude de correction est exactement ce que les
     * rubriques v8 interdisent au correcteur — le serveur ne se l'autorise pas
     * davantage.
     *
     * <p>Une confiance absente ou hors enum vaut {@code MOYENNE} (+ log warn) :
     * l'absence d'information n'est pas une certitude.
     */
    private void applyConfiance(Map<String, Object> feedback, ProductionSubmission sub,
                                ProductionValidityService.Verdict verdict,
                                TranscriptionQualityAudit.Mesure qualite, UUID submissionId) {
        ConfianceEvaluation declaree = ConfianceEvaluation.parse(feedback.get("confiance"));
        if (declaree == null) {
            log.warn("confiance absente ou invalide ({}) submission={} — MOYENNE par defaut.",
                feedback.get("confiance"), submissionId);
            declaree = ConfianceEvaluation.MOYENNE;
        }

        List<String> raisonsServeur = new ArrayList<>();
        ConfianceEvaluation plafond = null;
        if (verdict.douteObservation()) {
            plafond = ConfianceEvaluation.min(plafond, ConfianceEvaluation.MOYENNE);
            raisonsServeur.add("des vérifications automatiques ont signalé un doute sur cette production");
        }
        if (sub.getSource() == ProductionSubmissionSource.REALTIME) {
            plafond = ConfianceEvaluation.min(plafond, ConfianceEvaluation.MOYENNE);
            raisonsServeur.add("transcription produite en direct pendant l'échange, donc partiellement incertaine");
        }
        // TRANSCRIPTION MESUREE ABIMEE (mots coupes, debris de formes) : le
        // correcteur n'a pas lu ce que le candidat a dit. C'est un obstacle a
        // l'OBSERVATION, donc exactement ce que la confiance doit dire — et
        // rien d'autre : la note et le niveau sont hors de portee de ce filet.
        if (qualite.degradee()) {
            plafond = ConfianceEvaluation.min(plafond, ConfianceEvaluation.FAIBLE);
            raisonsServeur.add("transcription automatique visiblement dégradée (mots coupés ou "
                + "fragments non reconnaissables), ce qui limite ce que nous pouvons observer");
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
     * COHERENCE DEFENSIVE DU VERDICT (schema v5). Le contrat dit :
     * {@code objectif = ATTEINT} si et seulement si aucun {@code points_oublies}
     * n'est marque {@code obligatoire=true}. Quand le LLM se contredit — verdict
     * ATTEINT alors qu'il liste lui-meme un manque obligatoire — le serveur
     * tranche dans le sens PRUDENT et abaisse a {@code PARTIELLEMENT_ATTEINT}.
     *
     * <p>Il n'abaisse QUE : jamais de remontee automatique vers ATTEINT, jamais
     * de verdict fabrique quand le LLM n'en donne pas (evaluations anterieures a
     * v5 : le champ reste simplement absent, les fronts n'affichent pas le
     * bloc). Meme philosophie que {@code applyConfiance}.
     */
    @SuppressWarnings("unchecked")
    private void applyObjectifCoherence(Map<String, Object> feedback, UUID submissionId) {
        if (!(feedback.get("accomplissement") instanceof Map<?, ?> rawAcc)) return;
        Map<String, Object> acc = (Map<String, Object>) rawAcc;
        ObjectifTache declare = ObjectifTache.parse(acc.get("objectif"));
        if (declare == null) {
            // Absent (contrat v4 et anterieurs) ou hors enum : on ne fabrique
            // rien. Une valeur hors enum est deja bloquee par le validateur sur
            // le contrat v5.
            return;
        }
        if (declare != ObjectifTache.ATTEINT || !aUnManqueObligatoire(acc.get("points_oublies"))) {
            acc.put("objectif", declare.name());
            return;
        }
        log.info("Verdict incoherent submission={} : ATTEINT alors qu'un point obligatoire "
            + "est liste comme oublie — abaisse a PARTIELLEMENT_ATTEINT.", submissionId);
        acc.put("objectif", ObjectifTache.PARTIELLEMENT_ATTEINT.name());
    }

    /** Vrai si {@code points_oublies} contient au moins une entree {@code obligatoire=true}. */
    private static boolean aUnManqueObligatoire(Object pointsOublies) {
        if (!(pointsOublies instanceof List<?> points)) return false;
        for (Object point : points) {
            if (point instanceof Map<?, ?> p && Boolean.TRUE.equals(p.get("obligatoire"))) {
                return true;
            }
        }
        return false;
    }

    /**
     * Contrat de sortie dont la preuve est un NUMERO de segment (v6 et au-dela).
     *
     * <p>La reponse vient du REGISTRE {@link EvaluationToolSchema}, pas d'une
     * egalite litterale : une version livree mais non enregistree echouerait ici
     * au lieu de faire croire, en silence, que la preuve est une citation — ce
     * qui revenait a servir au correcteur une production non decoupee alors que
     * son schema lui reclamait un numero de segment.
     */
    static boolean preuveParNumero(String toolSchemaVersion) {
        return EvaluationToolSchema.of(toolSchemaVersion).preuveParNumero();
    }

    /**
     * Contrat de sortie qui porte encore {@code version_amelioree} (v5 a v7).
     * Meme registre, meme raison que {@link #preuveParNumero(String)} : la
     * question se pose au CONTRAT, jamais a une egalite litterale.
     */
    static boolean versionAmelioree(String toolSchemaVersion) {
        return EvaluationToolSchema.of(toolSchemaVersion).versionAmelioree();
    }

    /**
     * Contrat de sortie qui porte encore {@code exemples_corriges} et
     * {@code suggestions} (jusqu'a v8). Meme registre, meme raison que
     * {@link #preuveParNumero(String)} : la question se pose au CONTRAT, jamais
     * a une egalite litterale.
     */
    static boolean exemplesEtSuggestions(String toolSchemaVersion) {
        return EvaluationToolSchema.of(toolSchemaVersion).exemplesEtSuggestions();
    }

    /**
     * CONTRAT v6 : remplace le {@code preuve_segment} rendu par le correcteur par
     * le TEXTE ORIGINAL EXACT du segment designe, sous la cle {@code preuve}.
     *
     * <p>C'est ce qui rend la bascule invisible des trois fronts : le contrat
     * expose ({@code AiEvaluation.feedback_json}, donc {@code EvaluationResultDto}
     * et ses miroirs web/mobile) continue de porter un champ {@code preuve}
     * textuel, exactement comme avant. Aucun miroir de DTO a propager.
     *
     * <p>Le numero a deja ete valide comme existant ; le seul cas ou une preuve
     * reste absente ici est celui du mode degrade, qui l'a explicitement retiree.
     */
    @SuppressWarnings("unchecked")
    private void resolvePreuveSegments(Map<String, Object> feedback,
                                       EvaluationProductionSegments segments, UUID submissionId) {
        if (segments == null || !(feedback.get("scores_criteres") instanceof List<?> scores)) return;
        int nonResolus = 0;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            Object numero = sm.remove("preuve_segment");
            if (!(numero instanceof Number n)) continue;
            var texte = segments.texte(n.intValue());
            if (texte.isEmpty()) {
                nonResolus++;
                continue;
            }
            sm.put("preuve", texte.get());
        }
        if (nonResolus > 0) {
            log.warn("{} preuve(s) sans segment correspondant submission={} — numero hors bornes "
                    + "apres validation, ce qui ne devrait pas arriver.", nonResolus, submissionId);
        }
    }

    /** Canonicalise les preuves valides et retire celles sans passage unique. */
    @SuppressWarnings("unchecked")
    private void canonicalizePreuves(Map<String, Object> feedback, String production,
                                     EpreuveType epreuve, UUID submissionId) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return;
        int retirees = 0;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            Object preuve = sm.get("preuve");
            if (preuve == null) continue;
            var passage = EvaluationProofMatcher.canonicalPassage(
                production, preuve.toString(), epreuve);
            if (passage.isEmpty()) {
                sm.remove("preuve");
                retirees++;
            } else {
                sm.put("preuve", passage.get());
            }
        }
        if (retirees > 0) {
            log.warn("{} preuve(s) retiree(s) submission={} — aucun passage unique dans la production.",
                retirees, submissionId);
        }
    }

    /** Nombre maximum de points a ameliorer rendus au candidat. */
    static final int MAX_POINTS_A_AMELIORER = 2;

    /** Nombre maximum de points forts rendus au candidat (schema v5). */
    static final int MAX_POINTS_FORTS = 2;

    /** Nombre maximum d'exemples corriges rendus au candidat (schema v5). */
    static final int MAX_EXEMPLES_CORRIGES = 3;

    /** Cle du champ v5 « ta production reecrite au palier au-dessus » (EE seulement). */
    static final String CHAMP_VERSION_AMELIOREE = "version_amelioree";

    /**
     * Les deux champs de RESTITUTION LONGUE, au contrat jusqu'a v8 et retires en
     * v9. Ils n'etaient affiches que dans le bloc replie « Voir l'analyse
     * complete » de l'ecran de resultat, qui disparait.
     */
    static final List<String> CHAMPS_RESTITUTION_LONGUE =
        List.of("exemples_corriges", "suggestions");

    /**
     * Tronque une liste de restitution a {@code max} entrees, dans l'ordre rendu
     * par le LLM (les plus importantes d'abord, comme demande dans la consigne).
     * Meme raison que {@link #capPointsAAmeliorer} : une liste trop longue noie
     * ce qui compte, et le prompt seul ne tient pas la regle.
     */
    private void capListe(Map<String, Object> feedback, String cle, int max) {
        if (!(feedback.get(cle) instanceof List<?> valeurs) || valeurs.size() <= max) return;
        log.info("{} tronque : {} -> {}", cle, valeurs.size(), max);
        feedback.put(cle, valeurs.stream().limit(max).toList());
    }

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
     * Forme UNIQUE de {@code points_a_ameliorer} pour les fronts : une liste
     * d'objets {@code {constat, comment, exemple:{avant,apres}}}.
     *
     * <p>Le tool-schema v3 la demande au LLM ; les schemas anterieurs (et le
     * chemin « production invalide », qui n'appelle aucun LLM) produisent de
     * simples chaines. Plutot que d'imposer aux 3 fronts de gerer deux formes,
     * le serveur normalise : une chaine devient {@code {constat: <la chaine>}}
     * sans {@code comment}. Les fronts n'ont donc qu'un seul contrat, et
     * {@code comment}/{@code exemple} sont optionnels a l'affichage.
     */
    private static List<Map<String, Object>> normalizePointsAAmeliorer(Object raw) {
        if (!(raw instanceof List<?> points)) return List.of();
        List<Map<String, Object>> out = new ArrayList<>();
        for (Object p : points) {
            if (p instanceof Map<?, ?> m) {
                Map<String, Object> entry = new LinkedHashMap<>();
                for (Map.Entry<?, ?> e : m.entrySet()) {
                    if (e.getKey() != null) entry.put(e.getKey().toString(), e.getValue());
                }
                if (entry.get("constat") == null) {
                    // Tolerance : certains modeles renvoient encore {libelle}/{texte}.
                    Object fallback = entry.getOrDefault("libelle", entry.get("texte"));
                    entry.put("constat", fallback == null ? "" : fallback.toString());
                }
                out.add(entry);
            } else if (p != null) {
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("constat", p.toString());
                out.add(entry);
            }
        }
        return out;
    }

    /**
     * Ajoute a chaque score sa {@code bande} qualitative, aux bornes de la
     * GRILLE ACTIVE (v3-v5 : 16-20 / 11-15 / 6-10 / 1-5 / 0 ; v6, echelle du
     * TCF : 10-20 / 6-9 / 2-5 / 1 / 0). Les fronts affichent la bande, plus le
     * nombre.
     */
    @SuppressWarnings("unchecked")
    private void applyBandesCriteres(Map<String, Object> feedback) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            if (!(sm.get("note_sur_20") instanceof Number n)) continue;
            BandeCritere bande = BandeCritere.of(new BigDecimal(n.toString()), rubrics.bandesCriteres());
            if (bande != null) sm.put("bande", bande.name());
        }
    }

    /**
     * GARDE-FOU DE COUPLAGE (filet deterministe, v5) : les criteres de
     * REALISATION ({@code communiquer}, {@code interagir}) sont ramenes sous
     * {@code moyenne(lexique, morphosyntaxe) + ecart-max}. Une tache est
     * toujours accomplie AVEC des moyens linguistiques : la reussir avec des
     * moyens tres pauvres est une reussite partielle.
     *
     * <p>Applique AVANT {@code applyServerComputedNote} pour que la note — et
     * donc le niveau, qui en decoule depuis v5 — reflete le plafond. La regle
     * est deja ecrite dans le prompt ; ce filet la garantit, comme
     * {@code capPointsAAmeliorer} garantit la regle des 2 priorites.
     *
     * <p><b>Sans effet sur les grilles anterieures</b> : v3/v4/v4.1/v4.2 n'ont
     * ni {@code communiquer} ni {@code interagir}, aucun critere ne matche.
     */
    @SuppressWarnings("unchecked")
    private void applyCouplage(Map<String, Object> feedback, UUID submissionId) {
        ProductionEvaluationProperties.Couplage cfg = rubrics.couplage();
        if (!cfg.isEnabled() || !(feedback.get("scores_criteres") instanceof List<?> scores)) return;

        Map<String, BigDecimal> notes = notesParCode(feedback.get("scores_criteres"));
        List<BigDecimal> langue = new ArrayList<>();
        for (String code : cfg.getCriteresLangue()) {
            BigDecimal v = notes.get(code);
            if (v != null) langue.add(v);
        }
        // Socle incomplet : on ne plafonne pas a l'aveugle.
        if (langue.size() != cfg.getCriteresLangue().size() || langue.isEmpty()) return;

        BigDecimal somme = BigDecimal.ZERO;
        for (BigDecimal v : langue) somme = somme.add(v);
        BigDecimal plafond = somme
                .divide(BigDecimal.valueOf(langue.size()), 4, RoundingMode.HALF_UP)
                .add(BigDecimal.valueOf(cfg.getEcartMax()));

        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> sm = (Map<String, Object>) rawMap;
            Object code = sm.get("code");
            if (code == null || !cfg.getCriteresRealisation().contains(code.toString())) continue;
            if (!(sm.get("note_sur_20") instanceof Number n)) continue;
            BigDecimal note = new BigDecimal(n.toString());
            if (note.compareTo(plafond) <= 0) continue;
            BigDecimal ramenee = plafond.setScale(1, RoundingMode.DOWN);
            log.info("Couplage applique submission={} critere={} : {} -> {} (socle langue + {}).",
                    submissionId, code, note, ramenee, cfg.getEcartMax());
            sm.put("note_sur_20", ramenee);
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
        ProductionEvaluationProperties.Plafonds cfg = rubrics.plafonds();
        if (!cfg.isEnabled() || niveau == null) return niveau;

        Map<String, BigDecimal> notes = notesParCode(feedback.get("scores_criteres"));
        int tache = task.getTacheNumero();
        NiveauCecrl out = niveau;

        BigDecimal prisePosition = noteAccomplissement(notes, "prise_position");
        if (tache == 3 && prisePosition != null
                && prisePosition.compareTo(BigDecimal.valueOf(cfg.getPrisePositionSeuil())) <= 0) {
            out = appliquerPlafond(feedback, out, cfg.getPrisePositionNiveauMax(), submissionId,
                "prise_position=" + prisePosition,
                "Aucune prise de position claire n'a été identifiée. Sur cette tâche, donner son "
                    + "avis et le défendre est attendu : le niveau observé est donc limité à "
                    + cfg.getPrisePositionNiveauMax().name().replace("_", " ") + ".");
        }

        BigDecimal conduiteEchange = noteAccomplissement(notes, "conduite_echange");
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

    /**
     * Note du critere qui porte l'ACCOMPLISSEMENT de la tache : le code propre a
     * la tache dans les grilles v4/v4.1/v4.2 ({@code prise_position},
     * {@code conduite_echange}), a defaut {@code communiquer}, qui les absorbe
     * tous dans la grille TCF (v5). Sans ce repli, les deux plafonds cibles
     * seraient devenus des no-op silencieux en v5.
     */
    private static BigDecimal noteAccomplissement(Map<String, BigDecimal> notes, String codeHistorique) {
        BigDecimal v = notes.get(codeHistorique);
        return v != null ? v : notes.get("communiquer");
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
    static String normalizeForOrthoCompare(String s) {
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
     *   <li>EO : limite assumee « on lit la transcription, pas la voix »,
     *       TOUJOURS en tete et desormais SEULE (cf.
     *       {@link #AVERTISSEMENT_TRANSCRIPTION}) — les trois avertissements de
     *       purge d'{@code EvaluationOralArtifactFilter} ont ete supprimes ;</li>
     *   <li>EE : depassement de la limite de mots pour les anciennes donnees ;</li>
     * </ul>
     *
     * <p>S'y ajoutent, au fil du pipeline, les raisons de validite et les
     * avertissements de degradation (preuve retiree, marqueur de palier purge) :
     * la liste servie aux fronts n'a donc pas de taille fixe, et les evaluations
     * deja persistees gardent leurs anciens textes — aucune migration.
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
     * scores exploitables, l'evaluation echoue au lieu de conserver la note LLM.
     */
    private void applyServerComputedNote(Map<String, Object> feedback, ProductionTask task, UUID submissionId) {
        Object criteres = rubrics.find(task.getEpreuve(), task.getTacheNumero())
                .map(r -> r.get("criteres")).orElse(null);
        BigDecimal computed = weightedNote(criteres, feedback.get("scores_criteres"));
        if (computed == null) {
            throw new AiEvaluationException("note_globale non calculable avec les quatre criteres attendus "
                    + "pour la submission " + submissionId);
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
     * Si un critere source manque, le calcul tente la moyenne ponderee complete.
     * Logue un compteur de divergence (≥1 cran) IA vs calcul pour la calibration.
     *
     * @return le niveau calcule ; une impossibilite est bloquante.
     */
    private NiveauCecrl applyServerComputedNiveau(Map<String, Object> feedback, BigDecimal noteGlobale,
                                                  NiveauCecrl niveauIa, UUID submissionId) {
        List<String> sourceCodes = rubrics.niveauCecrl().getSourceCriteres();
        Object scores = feedback.get("scores_criteres");
        if (!sourceCriteriaPresent(scores, sourceCodes)) {
            log.warn("niveau_cecrl : critere(s) porteur(s) {} manquant(s) dans scores_criteres "
                    + "(submission={}) — fallback sur la moyenne ponderee.", sourceCodes, submissionId);
        }
        NiveauCecrl calcule = ProductionBilanService.computeNiveau(
                scores, sourceCodes, noteGlobale, rubrics.niveauCecrl());
        if (calcule == null) {
            throw new AiEvaluationException("niveau_cecrl non calculable cote serveur pour la submission "
                    + submissionId);
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
            // Texte deja recolle par le manager (tours consecutifs d'un meme
            // locuteur fusionnes) : c'est le MEME que celui servi aux fronts,
            // sans quoi une preuve a cheval sur une frontiere serait citee sans
            // etre visible a l'ecran.
            String texte = transcriptionManager
                    .findLatestTexteBySubmissionId(sub.getId())
                    .orElseThrow(() -> new AiEvaluationException(
                            "Submission EO " + sub.getId() + " sans transcription : Whisper a echoue ou n'a pas tourne."
                    ));
            return new ProductionInput(texte, true);
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
