package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MediaType;
import com.sejourfr.app.enums.PassageType;

import java.util.UUID;

public record PassageDto(
        UUID id,
        PassageType type,
        String content,
        UUID themeId,
        String themeName,
        UUID mediaId,
        String mediaUrl,
        MediaType mediaType,
        long questionCount
) {}
