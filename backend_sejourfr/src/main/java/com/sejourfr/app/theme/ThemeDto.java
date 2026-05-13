package com.sejourfr.app.theme;

import com.sejourfr.app.theme.enums.Module;

import java.util.UUID;

public record ThemeDto(
        UUID id,
        Module module,
        String code,
        String name,
        String description,
        int displayOrder,
        long questionCount
) {}
