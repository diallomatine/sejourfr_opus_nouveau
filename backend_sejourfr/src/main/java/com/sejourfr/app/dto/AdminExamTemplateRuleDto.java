package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;

import java.util.UUID;

public record AdminExamTemplateRuleDto(
        UUID id,
        UUID themeId,
        String themeName,
        QuestionType questionType,
        Difficulty difficulty,
        int questionCount,
        int position
) {}
