package com.sejourfr.app.dto;

public record StoredFile(
        String storageKey,
        String publicUrl,
        String contentType,
        long sizeBytes,
        String originalFilename
) {}
