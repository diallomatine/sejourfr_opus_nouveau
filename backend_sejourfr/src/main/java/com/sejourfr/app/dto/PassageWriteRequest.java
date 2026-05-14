package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PassageType;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record PassageWriteRequest(
        @NotNull(message = "Le type est requis")
        PassageType type,

        String content,

        @NotNull(message = "La thématique est requise")
        UUID themeId,

        UUID mediaId
) {}
