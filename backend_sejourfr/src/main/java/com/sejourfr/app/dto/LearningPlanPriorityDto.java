package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

/**
 * Une priorité du Plan. Les trois compteurs de fin ont exactement la sémantique
 * de {@link SkillDto} — sujets ACTIFS de la compétence, sujets déjà tentés par
 * ce candidat, sujets validés — et sortent du même calcul serveur : un front ne
 * doit jamais voir « 2 sur 5 » ici et « 3 sur 5 » dans le module Compétences.
 */
public record LearningPlanPriorityDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        LearningPlanSkillStatus status,
        String explanation,
        String evidence,
        ObservationConfidence confidence,
        Instant observedAt,
        PlanRecommendedExerciseDto recommendedExercise,
        int promptCount,
        int attemptedCount,
        int validatedCount
) {}
