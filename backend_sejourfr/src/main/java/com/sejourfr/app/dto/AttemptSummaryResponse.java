package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;

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
        String examTemplateName,
        // Champs spécifiques aux examens module TCF (cf. migration V098).
        // Renseignés uniquement quand l'attempt est un examen scopé à une épreuve.
        QuestionType moduleExamQuestionType,
        Integer weightedScore,
        Integer maxWeightedScore,
        // Thème ciblé par cet attempt (CIVIQUE) — non null pour un lot ou
        // un examen thème-scopé (20 Q d'un seul thème), null pour un examen
        // blanc complet civique (40 Q tous thèmes). Permet au front de
        // distinguer les deux variantes dans les listes d'historique.
        UUID lotThemeId,
        // Slot d'examen blanc dans la grille UI (1..10). Non null uniquement
        // pour les MOCK_EXAM standalone. L'UI groupe par slotNumber et prend
        // le plus récent par slot — refaire l'examen N met à jour la note
        // du slot N au lieu de créer un slot N+1. Cf. migration V110.
        Integer slotNumber
) {
}
