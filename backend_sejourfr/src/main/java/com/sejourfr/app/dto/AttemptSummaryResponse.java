package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé d'une session pour l'historique — sans les questions imbriquées.
 */
public record AttemptSummaryResponse(
        UUID id,
        AttemptType type,
        Module module,
        Difficulty difficulty,
        Integer totalQuestions,
        Integer passThreshold,
        Instant startedAt,
        Instant finishedAt,
        Integer score
) {
}
