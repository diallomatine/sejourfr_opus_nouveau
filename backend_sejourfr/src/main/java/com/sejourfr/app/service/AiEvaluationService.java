package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
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

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final EvaluationLlmClient llmClient;
    private final EvaluationPromptBuilder promptBuilder;
    @SuppressWarnings("unused")
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

    @Transactional
    public AiEvaluation evaluate(UUID submissionId) {
        ProductionSubmission sub = submissionManager.findById(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        ProductionTask task = sub.getProductionTask();
        if (task == null) {
            throw new AiEvaluationException("Submission " + submissionId + " sans production_task.");
        }

        ProductionInput input = loadInput(sub, task);
        Integer dureeSec = task.getEpreuve() == EpreuveType.TCF_EO ? sub.getMediaDurationSec() : null;
        String systemPrompt = promptBuilder.buildSystemPrompt(task.getEpreuve());
        String userPrompt = promptBuilder.buildUserPrompt(task, input.production(), input.litteral(), dureeSec);

        EvaluationLlmClient.Outcome outcome = llmClient.evaluate(systemPrompt, userPrompt);

        // Avertissements construits cote serveur (longueur/duree), injectes dans
        // le feedback expose au front. L'IA ne les produit pas elle-meme.
        Map<String, Object> feedback = new LinkedHashMap<>(outcome.feedback());
        List<String> avertissements = buildAvertissements(sub, task);
        if (!avertissements.isEmpty()) {
            feedback.put("avertissements", avertissements);
        }
        // Joint le `label` de la grille a chaque score (le LLM ne renvoie que le
        // `code`). Source unique = production_tasks.criteres_evaluation : evite
        // au mobile de maintenir une table parallele code→libelle qui derive.
        enrichScoresWithLabels(feedback, task);
        BigDecimal noteSur20 = extractNote(feedback);
        NiveauCecrl niveau = extractNiveau(feedback);

        AiEvaluation eval = new AiEvaluation();
        eval.setSubmission(sub);
        eval.setModeleUtilise(llmClient.getModelName());
        eval.setPromptVersion(llmClient.getPromptVersion());
        eval.setNoteSur20(noteSur20);
        eval.setNiveauCecrl(niveau);
        eval.setFeedbackJson(feedback);
        eval.setTokensInput(outcome.inputTokens());
        eval.setTokensOutput(outcome.outputTokens());
        eval.setCoutEstimeCentimes(outcome.costEstimateCents());
        aiEvaluationManager.save(eval);

        sub.setStatut(SubmissionStatut.EVALUATED);
        sub.setErreurMessage(null);
        submissionManager.save(sub);

        log.info("AiEvaluation persistee submission={} note={} niveau={} model={}",
                submissionId, noteSur20, niveau, llmClient.getModelName());
        return eval;
    }

    /**
     * Avertissements affiches a l'utilisateur (construits serveur, hors IA) :
     * <ul>
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
        Integer duree = sub.getMediaDurationSec();
        Integer cible = task.getDureeMaxSec();
        Integer min = task.getDureeMinSec();
        if (duree != null && cible != null && duree < cible) {
            if (min != null && duree < min) {
                out.add("Votre enregistrement est court (" + duree + " s, soit environ "
                    + formatMinutes(duree) + "). Le minimum recommande est de 2 minutes et l'objectif "
                    + cible + " s (~" + formatMinutes(cible) + "). Une production trop courte limite la "
                    + "demonstration de vos competences : votre note en tient compte. Rapprochez-vous "
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
        Object grilleObj = task.getCriteresEvaluation() != null
                ? task.getCriteresEvaluation().get("criteres")
                : null;
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

    private static String formatMinutes(int sec) {
        int m = sec / 60;
        int s = sec % 60;
        if (m == 0) return s + " s";
        return s == 0 ? m + " min" : m + " min " + s + " s";
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
