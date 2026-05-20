package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé d'une session pour l'historique — sans les questions imbriquées.
 * Les trois champs {@code examTemplate*} permettent au front de marquer un
 * examen comme "déjà fait" sur la liste des examens blancs et d'y revenir
 * (voir détails / refaire) sans recharger les templates côté serveur.
 * <p>
 * {@code epreuve} permet au front de distinguer les attempts QCM (CIVIQUE,
 * TCF_CO/CE/STRUCTURE) des productions EO/EE (TCF_EO/TCF_EE/TCF_COMPLET)
 * qui n'ont ni totalQuestions ni score — leur évaluation vit sur d'autres
 * routes (production_submissions + ai_evaluations).
 */
public record AttemptSummaryResponse(
        UUID id,
        AttemptType type,
        Module module,
        EpreuveType epreuve,
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
