package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.PassageType;
import com.sejourfr.app.enums.QuestionType;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record QuestionDto(
        UUID id,
        Module module,
        UUID themeId,
        String themeName,
        UUID passageId,
        PassageType passageType,
        String passagePreview,
        UUID mediaId,
        String mediaUrl,
        MediaType mediaType,
        Difficulty difficulty,
        QuestionType questionType,
        String statement,
        String explanation,
        boolean active,
        Instant createdAt,
        Instant updatedAt,
        List<ChoiceDto> choices
) {}
