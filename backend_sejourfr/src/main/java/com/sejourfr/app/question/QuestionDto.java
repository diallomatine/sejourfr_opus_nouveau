package com.sejourfr.app.question;

import com.sejourfr.app.question.enums.Difficulty;
import com.sejourfr.app.question.enums.QuestionType;
import com.sejourfr.app.theme.enums.Module;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record QuestionDto(
        UUID id,
        Module module,
        UUID themeId,
        String themeName,
        UUID passageId,
        UUID mediaId,
        String mediaUrl,
        Difficulty difficulty,
        QuestionType questionType,
        String statement,
        String explanation,
        boolean active,
        Instant createdAt,
        Instant updatedAt,
        List<ChoiceDto> choices
) {}
