package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AdminExamTemplateDto(
        UUID id,
        String slug,
        Module module,
        TargetLevel targetLevel,
        TargetProcedure targetProcedure,
        String name,
        String subtitle,
        String description,
        int durationSeconds,
        int totalQuestions,
        int passingScore,
        boolean free,
        boolean published,
        int position,
        Instant createdAt,
        Instant updatedAt,
        List<AdminExamTemplateRuleDto> rules
) {}
