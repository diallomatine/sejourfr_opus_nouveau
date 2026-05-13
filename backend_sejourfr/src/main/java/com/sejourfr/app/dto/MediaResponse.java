package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MediaType;

import java.util.UUID;

public record MediaResponse(
        UUID id,
        MediaType type,
        String url,
        Integer durationSeconds,
        String transcript
) {}
