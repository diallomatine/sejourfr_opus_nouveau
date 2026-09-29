package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Réponse retournée après POST /api/attempts/{id}/answers.
 *
 * - En TRAINING : 'correct' et 'correctChoiceIds' et 'explanation' sont renseignés.
 * - En MOCK_EXAM : tout est null sauf 'recorded' = true. On ne révèle rien jusqu'à finish.
 */
public record AnswerResultResponse(
        boolean recorded,
        Boolean correct,
        List<UUID> correctChoiceIds,
        String explanation
) {}
