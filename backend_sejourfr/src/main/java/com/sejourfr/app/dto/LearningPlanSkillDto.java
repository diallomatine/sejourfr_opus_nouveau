package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

public record LearningPlanSkillDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        LearningPlanSkillStatus status,
        Instant lastObservedAt
) {}
