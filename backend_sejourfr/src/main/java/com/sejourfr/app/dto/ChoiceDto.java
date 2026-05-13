package com.sejourfr.app.dto;

import java.util.UUID;

public record ChoiceDto(
        UUID id,
        String label,
        boolean correct,
        int displayOrder
) {}
