package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

public record DiagnosticSkillObservationDto(
        UUID skillId,
        String skillCode,
        String skillTitle,
        SkillSection section,
        boolean observed,
        LearningPlanSkillStatus status,
        String evidence,
        String explanation,
        ObservationConfidence confidence,
        boolean priority
) {}
