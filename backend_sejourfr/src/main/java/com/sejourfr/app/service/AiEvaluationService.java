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
import com.sejourfr.app.repository.AiEvaluationRepository;
import com.sejourfr.app.repository.ProductionSubmissionRepository;
import com.sejourfr.app.repository.TranscriptionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;
import java.util.UUID;

/**
 * Orchestre l'evaluation IA d'une {@link ProductionSubmission} :
 * construit les prompts, appelle le LLM via {@link EvaluationLlmClient}
 * (provider selectionne par config : Anthropic, OpenAI, ...), persiste
 * {@link AiEvaluation} et passe la submission a EVALUATED.
 */
@Service
public class AiEvaluationService {

    private static final Logger log = LoggerFactory.getLogger(AiEvaluationService.class);

    private final ProductionSubmissionRepository submissionRepository;
    private final TranscriptionRepository transcriptionRepository;
    private final AiEvaluationRepository aiEvaluationRepository;
    private final EvaluationLlmClient llmClient;
    private final EvaluationPromptBuilder promptBuilder;
    @SuppressWarnings("unused")
    private final ProductionEvaluationProperties props;

    public AiEvaluationService(
            ProductionSubmissionRepository submissionRepository,
            TranscriptionRepository transcriptionRepository,
            AiEvaluationRepository aiEvaluationRepository,
            EvaluationLlmClient llmClient,
            EvaluationPromptBuilder promptBuilder,
            ProductionEvaluationProperties props) {
        this.submissionRepository = submissionRepository;
        this.transcriptionRepository = transcriptionRepository;
        this.aiEvaluationRepository = aiEvaluationRepository;
        this.llmClient = llmClient;
        this.promptBuilder = promptBuilder;
        this.props = props;
    }

    @Transactional
    public AiEvaluation evaluate(UUID submissionId) {
        ProductionSubmission sub = submissionRepository.findById(submissionId)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        ProductionTask task = sub.getProductionTask();
        if (task == null) {
            throw new AiEvaluationException("Submission " + submissionId + " sans production_task.");
        }

        ProductionInput input = loadInput(sub, task);
        String systemPrompt = promptBuilder.buildSystemPrompt(task.getEpreuve());
        String userPrompt = promptBuilder.buildUserPrompt(task, input.production(), input.litteral());

        EvaluationLlmClient.Outcome outcome = llmClient.evaluate(systemPrompt, userPrompt);

        Map<String, Object> feedback = outcome.feedback();
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
        aiEvaluationRepository.save(eval);

        sub.setStatut(SubmissionStatut.EVALUATED);
        sub.setErreurMessage(null);
        submissionRepository.save(sub);

        log.info("AiEvaluation persistee submission={} note={} niveau={} model={}",
            submissionId, noteSur20, niveau, llmClient.getModelName());
        return eval;
    }

    private ProductionInput loadInput(ProductionSubmission sub, ProductionTask task) {
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            Transcription t = transcriptionRepository
                .findFirstBySubmissionIdOrderByCreatedAtDesc(sub.getId())
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

    private static BigDecimal extractNote(Map<String, Object> feedback) {
        Object raw = feedback.get("note_globale");
        if (raw == null) return null;
        try {
            BigDecimal v = new BigDecimal(raw.toString()).setScale(1, RoundingMode.HALF_UP);
            if (v.compareTo(BigDecimal.ZERO) < 0 || v.compareTo(new BigDecimal("20")) > 0) {
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

    private record ProductionInput(String production, boolean litteral) {}
}
