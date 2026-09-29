package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;

import java.util.List;
import java.util.UUID;

/**
 * Composition suggérée pour un nouvel ExamTemplate, basée sur le stock réel
 * de questions actives. L'admin peut accepter la proposition ou l'éditer.
 *
 * - rules        : composition recommandée (peut être rejouée telle quelle)
 * - poolSize     : nombre total de questions actives dans le module/cible
 * - warning      : message si le stock est trop faible pour totalQuestions
 *                  (sinon null)
 */
public record ExamCompositionSuggestionDto(
        int targetTotal,
        int poolSize,
        String warning,
        List<SuggestedRule> rules
) {
    public record SuggestedRule(
            UUID themeId,
            String themeName,
            Difficulty difficulty,
            int questionCount,
            long available
    ) {}
}
