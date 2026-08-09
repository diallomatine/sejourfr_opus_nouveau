package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

/**
 * Une compétence observée, avec sa progression réelle. Mêmes trois compteurs,
 * même sémantique et même calcul que {@link LearningPlanPriorityDto} et
 * {@link SkillDto}.
 */
public record LearningPlanSkillDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        LearningPlanSkillStatus status,
        Instant lastObservedAt,
        int promptCount,
        int attemptedCount,
        int validatedCount
) {}
