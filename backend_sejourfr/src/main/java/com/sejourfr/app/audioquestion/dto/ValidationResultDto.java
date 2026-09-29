package com.sejourfr.app.audioquestion.dto;

import java.time.Instant;
import java.util.UUID;

/** Reponse a PATCH /api/admin/audio-questions/{id}/validate. */
public record ValidationResultDto(
    UUID questionId,
    String status,
    Instant activatedAt
) {}
