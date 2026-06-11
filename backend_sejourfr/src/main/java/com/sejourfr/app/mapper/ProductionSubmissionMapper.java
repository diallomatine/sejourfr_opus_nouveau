package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.EvaluationResultDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.ProductionAudioStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class ProductionSubmissionMapper {

    private final AiEvaluationManager aiEvaluationManager;
    private final TranscriptionManager transcriptionManager;
    private final ProductionAudioStorageService audioStorage;

    public ProductionSubmissionDto toDto(ProductionSubmission s) {
        EvaluationResultDto eval = aiEvaluationManager
            .findLatestBySubmissionId(s.getId())
            .map(this::toEvaluationDto)
            .orElse(null);

        // Transcription Whisper (EO uniquement, null sinon).
        String transcription = transcriptionManager
            .findLatestBySubmissionId(s.getId())
            .map(t -> t.getTexte())
            .orElse(null);

        // L'URL signee n'est generee qu'a la demande : on s'epargne un round-trip
        // R2 quand le client n'est pas l'utilisateur final (ex: l'admin liste
        // des submissions pour calibration).
        String mediaUrl = s.getMediaUrl();

        return new ProductionSubmissionDto(
            s.getId(),
            s.getAttempt() != null ? s.getAttempt().getId() : null,
            s.getProductionTask() != null ? s.getProductionTask().getId() : null,
            s.getProductionTask() != null ? s.getProductionTask().getTacheNumero() : null,
            s.getStatut(),
            mediaUrl,
            s.getTexteSoumis(),
            s.getMotsCount(),
            s.getMediaDurationSec(),
            s.getRetryCount(),
            s.getErreurMessage(),
            s.getSubmittedAt(),
            eval,
            transcription
        );
    }

    /** Variante qui remplace media_url par une URL signee (TTL court). */
    public ProductionSubmissionDto toDtoWithSignedAudio(ProductionSubmission s) {
        ProductionSubmissionDto base = toDto(s);
        if (s.getMediaUrl() == null || s.getMediaUrl().isBlank()) return base;
        String signed = audioStorage.presignGet(s.getMediaUrl());
        return new ProductionSubmissionDto(
            base.id(), base.attemptId(), base.productionTaskId(),
            base.tacheNumero(),
            base.statut(), signed, base.texteSoumis(),
            base.motsCount(), base.mediaDurationSec(),
            base.retryCount(), base.erreurMessage(),
            base.submittedAt(), base.evaluation(),
            base.transcription()
        );
    }

    /**
     * Le niveau CECRL par tache n'est jamais expose (calibration interne
     * seulement) : on expurge {@code niveau_cecrl} et
     * {@code justification_niveau} du feedback avant envoi. Le niveau
     * n'apparait qu'au bilan d'epreuve en examen blanc.
     */
    private EvaluationResultDto toEvaluationDto(AiEvaluation e) {
        Map<String, Object> feedback = e.getFeedbackJson();
        if (feedback != null) {
            Map<String, Object> sanitized = new LinkedHashMap<>(feedback);
            sanitized.remove("niveau_cecrl");
            sanitized.remove("justification_niveau");
            feedback = sanitized;
        }
        return new EvaluationResultDto(e.getNoteSur20(), feedback);
    }
}
