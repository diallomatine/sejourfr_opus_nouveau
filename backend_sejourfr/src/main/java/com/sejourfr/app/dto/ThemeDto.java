package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
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
