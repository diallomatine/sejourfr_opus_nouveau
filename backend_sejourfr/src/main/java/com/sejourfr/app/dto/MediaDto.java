package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MediaType;

import java.time.Instant;
import java.util.UUID;

public record MediaDto(
        UUID id,
        MediaType type,
        String url,
        String originalFilename,
        String contentType,
        Long sizeBytes,
        Integer durationSec,
        String altText,
        Instant createdAt
) {}
