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
        String transcription,
        /**
         * Ce que cette production a change dans le Plan — une ligne, pas la liste
         * des competences observees. <b>Nullable, et son absence est normale</b>
         * (rien n'a bouge, ou les observations ne sont pas encore ecrites : cf.
         * {@link PlanChangeDto}). Rempli sur le detail d'une soumission evaluee,
         * jamais sur une liste d'historique ni sur une soumission de diagnostic.
         */
        PlanChangeDto planChange
) {

    /** Meme soumission, avec le changement de Plan resolu a la lecture. */
    public ProductionSubmissionDto withPlanChange(PlanChangeDto planChange) {
        return new ProductionSubmissionDto(
                id, attemptId, productionTaskId, tacheNumero, statut, mediaUrl, texteSoumis,
                motsCount, mediaDurationSec, retryCount, erreurMessage, submittedAt,
                evaluation, transcription, planChange);
    }
}
