package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import jakarta.validation.constraints.Min;

import java.util.UUID;

public record AdminExamTemplateRuleWriteRequest(
        UUID themeId,
        QuestionType questionType,
        Difficulty difficulty,
        @Min(1) int questionCount
) {}
