package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SubmissionStatut;

import java.time.Instant;
import java.util.UUID;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.ProductionSubmission}. Le
 * champ {@code evaluation} est nul tant que le pipeline IA n'a pas abouti
 * (statut != EVALUATED).
 */
public record ProductionSubmissionDto(
        UUID id,
        UUID attemptId,
        UUID productionTaskId,
        /** Situation d'entrainement jouee (NULL si entrainement libre sur la tache). */
        UUID situationId,
        /** Numero de tache (1, 2 ou 3) de la production_task associee. Sert au hub
         *  d'entrainement a regrouper la derniere submission par numero. */
        Short tacheNumero,
        SubmissionStatut statut,
        String mediaUrl,
        String texteSoumis,
        Integer motsCount,
        Integer mediaDurationSec,
        short retryCount,
        String erreurMessage,
        Instant submittedAt,
        EvaluationResultDto evaluation,
        /**
         * Transcription Whisper de l'audio (EO uniquement). Null pour EE et tant
         * que Whisper n'a pas tourne. Exposee pour afficher dans l'ecran detail
         * de l'evaluation cote mobile.
         */
        String transcription
) {
}
