package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

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
        PlanRecommendedExerciseDto recommendedExercise
) {}
