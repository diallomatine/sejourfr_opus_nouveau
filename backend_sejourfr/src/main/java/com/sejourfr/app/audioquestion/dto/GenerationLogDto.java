package com.sejourfr.app.audioquestion.dto;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Element de la liste paginee renvoyee par GET /api/admin/audio-questions/generation-logs. */
public record GenerationLogDto(
    UUID id,
    UUID questionId,
    UUID adminUserId,
    String requestedParams,
    String promptVersion,
    String anthropicModel,
    Integer anthropicInputTokens,
    Integer anthropicOutputTokens,
    Integer anthropicCacheReadTokens,
    BigDecimal anthropicCostEur,
    Integer azureCharactersCount,
    BigDecimal azureCostEur,
    String r2ObjectKey,
    Integer durationMs,
    GenerationStatus status,
    String errorMessage,
    Instant createdAt
) {}
