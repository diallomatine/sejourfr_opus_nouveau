package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EtatSignalement;
import com.sejourfr.app.enums.MotifSignalement;

import java.time.Instant;
import java.util.UUID;

/**
 * Un signalement admin d'une évaluation IA. {@code etat} vaut {@code SIGNALE},
 * {@code VERIFIE} ou {@code RETIRE} (jamais {@code AUCUN}). Un signalement ne
 * modifie jamais l'évaluation qu'il vise.
 */
public record AdminProductionFlagDto(
        UUID id,
        UUID submissionId,
        UUID evaluationId,
        MotifSignalement motif,
        String motifLabel,
        String commentaire,
        EtatSignalement etat,
        String etatLabel,
        Instant createdAt,
        AdminActeurDto createdBy,
        Instant verifiedAt,
        AdminActeurDto verifiedBy,
        Instant removedAt,
        AdminActeurDto removedBy
) {
}
