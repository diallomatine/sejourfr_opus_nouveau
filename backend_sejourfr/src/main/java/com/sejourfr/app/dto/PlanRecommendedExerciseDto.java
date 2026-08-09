package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

/** Micro-exercice réellement disponible, recommandé par le Plan. */
public record PlanRecommendedExerciseDto(
        UUID skillPromptId,
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        int estimatedMinutes
) {}
