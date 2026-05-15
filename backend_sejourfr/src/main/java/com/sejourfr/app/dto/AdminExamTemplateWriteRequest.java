package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;

public record AdminExamTemplateWriteRequest(
        @NotBlank @Size(max = 64)
        @Pattern(regexp = "^[a-z0-9]+(-[a-z0-9]+)*$",
                message = "slug doit être en kebab-case (lettres minuscules, chiffres, tirets)")
        String slug,

        @NotNull Module module,
        TargetLevel targetLevel,
        TargetProcedure targetProcedure,

        @NotBlank @Size(max = 120) String name,
        @Size(max = 160) String subtitle,
        String description,

        @Min(60) int durationSeconds,
        @Min(1) int totalQuestions,
        @Min(0) int passingScore,

        boolean free,
        boolean published,
        @Min(0) int position,

        @Valid List<AdminExamTemplateRuleWriteRequest> rules
) {}
