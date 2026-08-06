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
    static final String MODELE_VALIDATION_SERVEUR = "validation-serveur";

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

        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(task, input.production(), input.litteral(), null);

        ValidatedOutcome validated = evaluateValidated(
                llmClient, systemPrompt, userPrompt, task, input.production(), submissionId);
        EvaluationLlmClient.Outcome outcome = validated.outcome();
        ProductionSecondePasseService.Passe passe = postProcess(
                outcome, llmClient.getModelName(), sub, task, verdict, input.production(),
                validated.avertissements(), submissionId);

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
                    ValidatedOutcome validated2 = evaluateValidated(
                            client2, systemPrompt, userPrompt, task, input.production(), submissionId);
                    EvaluationLlmClient.Outcome outcome2 = validated2.outcome();
                    ProductionSecondePasseService.Passe passe2 = postProcess(
                            outcome2, client2.getModelName(), sub, task, verdict,
                            input.production(), validated2.avertissements(), submissionId);
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

        log.warn("Sortie LLM invalide submission={} modele={} — retry semantique unique : {}",
                submissionId, client.getModelName(), violations);
        // Le reessai rappelle la citation refusee critere par critere et enonce
        // la regle de la preuve : sans cela il ne reparait rien (cf.
        // EvaluationRepairPrompt). Aucun controle n'est relache pour autant.
        String repairPrompt = EvaluationRepairPrompt.build(
                userPrompt, violations, first.feedback(),
                task == null ? null : task.getEpreuve());
        EvaluationLlmClient.Outcome repaired = client.evaluate(systemPrompt, repairPrompt);
        List<String> remaining = EvaluationOutputValidator.violations(
                repaired.feedback(), task, rubrics, client.getPromptVersion(), production);
        if (!remaining.isEmpty()) {
            String promptVersion = client.getPromptVersion();
            var unmatchedProof = "v4".equals(promptVersion) || "v5".equals(promptVersion)
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
            sumNullable(first.outputTokens(), repaired.outputTokens()),
            sumNullable(first.costEstimateCents(), repaired.costEstimateCents()));
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
            if (criterionCode.equals(String.valueOf(score.get("code")))
                    && score.remove("preuve") != null) {
                removed++;
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
            EvaluationLlmClient.Outcome outcome, String modele,
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
        // Confiance (schema v2) : lue, normalisee, puis PLAFONNEE serveur.
        applyConfiance(feedback, sub, verdict, submissionId);
        // Accomplissement (schema v2) : conserve tel quel, structure normalisee.
        // Aucun point `obligatoire: false` (une simple piste du sujet) n'entre
        // dans un quelconque calcul de note — c'est une regle produit.
        normalizeAccomplissement(feedback);
        // VERDICT (schema v5) : le serveur ne l'invente pas, il le corrige dans
        // le sens PRUDENT quand il se contredit lui-meme — jamais l'inverse,
        // exactement comme la confiance, qu'il peut abaisser mais pas relever.
        applyObjectifCoherence(feedback, submissionId);
        // EO : `version_amelioree` (schema v5) n'a aucun sens sur un echange
        // oral — on ne rend pas au candidat un dialogue modele, et le garde-fou
        // oral interdit de parler de la forme orale. La rubrique l'interdit
        // deja ; ce filet garantit qu'aucune sortie orale n'en porte.
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            feedback.remove(CHAMP_VERSION_AMELIOREE);
        }
        // Le contrat v4 rejette une preuve absente/ambigue avant ce
        // post-traitement, sauf l'unique preuve retiree explicitement apres un
        // second appel autrement valide. Les passages acceptes sont remplaces
        // par leur sous-chaine originale exacte : le candidat ne voit jamais
        // une recopie approximative ou inventee. Sur un ancien contrat, une
        // preuve sans match conservateur est retiree.
        canonicalizePreuves(feedback, production, task.getEpreuve(), submissionId);
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
            var purge = EvaluationOralArtifactFilter.purge(feedback, production);
            if (purge.aPurge()) {
                log.info("Restitution orale purgee submission={} : {} remarque(s) de niveau mot, "
                        + "{} exemple(s) corrige(s) fondes sur un element non evaluable.",
                    submissionId, purge.remarquesRetirees(), purge.exemplesRetires());
            }
            if (purge.remarquesRetirees() > 0) {
                addAvertissement(feedback, EvaluationOralArtifactFilter.AVERTISSEMENT_ARTEFACT);
            }
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
                                ProductionValidityService.Verdict verdict, UUID submissionId) {
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
     *   <li>EO : limite assumee « evaluation fondee sur la transcription »,
     *       TOUJOURS en tete (cf. {@link #AVERTISSEMENT_TRANSCRIPTION}) ;</li>
     *   <li>EE : depassement de la limite de mots pour les anciennes donnees ;</li>
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
