package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.EvaluationResultDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.repository.AiEvaluationRepository;
import com.sejourfr.app.repository.TranscriptionRepository;
import com.sejourfr.app.service.ProductionAudioStorageService;
import org.springframework.stereotype.Component;

@Component
public class ProductionSubmissionMapper {

    private final AiEvaluationRepository aiEvaluationRepository;
    private final TranscriptionRepository transcriptionRepository;
    private final ProductionAudioStorageService audioStorage;

    public ProductionSubmissionMapper(
            AiEvaluationRepository aiEvaluationRepository,
            TranscriptionRepository transcriptionRepository,
            ProductionAudioStorageService audioStorage) {
        this.aiEvaluationRepository = aiEvaluationRepository;
        this.transcriptionRepository = transcriptionRepository;
        this.audioStorage = audioStorage;
    }

    public ProductionSubmissionDto toDto(ProductionSubmission s) {
        EvaluationResultDto eval = aiEvaluationRepository
            .findFirstBySubmissionIdOrderByEvaluatedAtDesc(s.getId())
            .map(this::toEvaluationDto)
            .orElse(null);

        // Transcription Whisper (EO uniquement, null sinon).
        String transcription = transcriptionRepository
            .findFirstBySubmissionIdOrderByCreatedAtDesc(s.getId())
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

    private EvaluationResultDto toEvaluationDto(AiEvaluation e) {
        Object justifRaw = e.getFeedbackJson() != null
            ? e.getFeedbackJson().get("justification_niveau")
            : null;
        String justification = justifRaw == null ? null : justifRaw.toString();
        return new EvaluationResultDto(
            e.getNoteSur20(),
            e.getNiveauCecrl(),
            justification,
            e.getFeedbackJson()
        );
    }
}
