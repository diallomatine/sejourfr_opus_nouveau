package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MotifSignalement;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Corps de {@code POST /api/admin/productions/{submissionId}/flags}. Motif obligatoire. */
public record AdminProductionFlagRequest(
        @NotNull MotifSignalement motif,
        @Size(max = 1000) String commentaire
) {
}
