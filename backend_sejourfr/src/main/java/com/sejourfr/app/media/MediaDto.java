package com.sejourfr.app.media;

import com.sejourfr.app.media.enums.MediaType;

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
) {
    public static MediaDto from(Media m) {
        return new MediaDto(
                m.getId(),
                m.getType(),
                m.getUrl(),
                m.getOriginalFilename(),
                m.getContentType(),
                m.getSizeBytes(),
                m.getDurationSec(),
                m.getAltText(),
                m.getCreatedAt()
        );
    }
}
