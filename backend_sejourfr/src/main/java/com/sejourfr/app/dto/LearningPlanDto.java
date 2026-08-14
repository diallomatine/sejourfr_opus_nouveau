package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanState;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Plan actionnable ; aucune priorité n'est recalculée dans les fronts. */
public record LearningPlanDto(
        LearningPlanState state,
        UUID diagnosticSessionId,
        Instant diagnosticCompletedAt,
        LearningPlanPriorityDto currentPriority,
        List<LearningPlanPriorityDto> nextPriorities,
        List<LearningPlanSkillDto> observedSkills,
        int observedSkillCount,
        int activitiesThisWeek,
        boolean progressionAvailable,
        /**
         * Le <b>jalon</b> du parcours, un cran au-dessus des étapes : un examen
         * blanc d'épreuve puis l'examen blanc TCF complet
         * ({@code PlanExerciseKind.EPREUVE_MOCK_EXAM} /
         * {@code FULL_TCF_MOCK_EXAM}). Il vit <b>à côté</b> des priorités, il ne
         * les remplace pas — chaque étape garde son propre
         * {@code recommendedExercise}.
         *
         * <p>{@code null} est le <b>cas normal</b> : tant qu'une épreuve n'a pas
         * majoritairement transféré, il n'y a rien à mesurer, et juste après un
         * examen blanc il n'y a rien à re-mesurer. Verrouillé, il reste
         * <b>désigné</b> avec son {@code locked} : le Plan reste intégralement
         * visible, seuls les accès sont fermés.
         */
        PlanRecommendedExerciseDto milestone
) {}
