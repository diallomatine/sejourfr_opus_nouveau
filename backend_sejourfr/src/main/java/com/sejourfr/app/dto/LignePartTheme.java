package com.sejourfr.app.dto;

import java.util.UUID;

/**
 * Part d'un thème dans un examen civique : {@code posees} questions de ce thème
 * dans l'attempt, dont {@code bonnes} réussies. Une ligne de la requête groupée
 * {@code AttemptQuestionRepository.aggregatePartsParTheme}.
 */
public record LignePartTheme(UUID attemptId, UUID themeId, int posees, int bonnes) {
}
