package com.sejourfr.app.audioquestion.dto;

import java.util.List;
import java.util.UUID;

/**
 * Resultat d'un POST /batch-generate.
 * `batchId` est NULL si aucun draft TEXT_VALIDATED n'etait disponible.
 */
public record BatchGenerationResultDto(
    UUID batchId,
    int requested,
    int succeeded,
    int failed,
    List<DraftOutcome> outcomes
) {
    public record DraftOutcome(UUID draftId, boolean success, String errorMessage) {}
}
