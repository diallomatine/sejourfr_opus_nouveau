package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé d'une session pour l'historique — sans les questions imbriquées.
 * Les trois champs {@code examTemplate*} permettent au front de marquer un
 * examen comme "déjà fait" sur la liste des examens blancs et d'y revenir
 * (voir détails / refaire) sans recharger les templates côté serveur.
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
        Integer score,
        UUID examTemplateId,
        String examTemplateSlug,
        String examTemplateName
) {
}
