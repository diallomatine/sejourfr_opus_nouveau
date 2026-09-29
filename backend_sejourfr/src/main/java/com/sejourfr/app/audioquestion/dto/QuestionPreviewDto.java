package com.sejourfr.app.audioquestion.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.sejourfr.app.audioquestion.domain.AudioMode;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Payload retourne au front admin apres une generation reussie.
 * Contient tout ce que l'admin doit voir pour valider ou rejeter la question :
 * audio + transcript + question + 4 choix + metriques.
 */
public record QuestionPreviewDto(
    UUID questionId,
    String status,
    AudioPreviewDto audio,
    QuestionContentDto question,
    List<ChoiceDto> choices,
    GenerationMetadataDto metadata
) {

    public record AudioPreviewDto(
        UUID mediaId,
        String url,
        int durationSec,
        int speakerCount,
        List<VoiceDto> voices,
        String transcript,
        String contextDescription,
        @JsonInclude(JsonInclude.Include.NON_NULL) AudioMode audioMode
    ) {}

    public record VoiceDto(
        String role,
        String azureVoice,
        String gender
    ) {}

    public record QuestionContentDto(
        String statement,
        String explanation,
        String competenceCode,
        String difficulty,
        String theme
    ) {}

    public record ChoiceDto(
        UUID id,
        String label,
        boolean isCorrect,
        int displayOrder
    ) {}

    public record GenerationMetadataDto(
        Instant generatedAt,
        long generationDurationMs,
        BigDecimal costEur,
        Integer anthropicInputTokens,
        Integer anthropicOutputTokens,
        Integer anthropicCacheReadTokens,
        Integer azureCharactersCount
    ) {}
}
