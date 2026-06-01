package com.sejourfr.app.audioquestion.dto;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Vue d'un draft audio pour l'admin (liste + ecran de validation).
 * Inclut l'audio si genere, et la liste des choix avec la reponse correcte mise en evidence.
 */
public record AudioDraftDto(
    UUID id,
    String difficulty,
    String competenceCode,
    UUID themeId,
    String themeName,
    String transcriptText,
    String statement,
    String explanation,
    List<ChoiceDto> choices,
    String voiceRecommended,
    String inlineSvg,
    String imageUrl,
    String imageAltText,
    AudioDraftStatus status,
    String audioUrl,
    Integer audioDurationSec,
    String audioVoiceUsed,
    Instant audioGeneratedAt,
    UUID batchId,
    Instant createdAt,
    String rejectionReason
) {
    public record ChoiceDto(String label, boolean isCorrect, int displayOrder) {}

    public static AudioDraftDto from(AudioQuestionDraft d) {
        List<ChoiceDto> choices = d.getChoices() == null ? List.of() :
            d.getChoices().stream()
                .sorted((a, b) -> Integer.compare(a.displayOrder(), b.displayOrder()))
                .map(c -> new ChoiceDto(c.label(), c.isCorrect(), c.displayOrder()))
                .toList();
        return new AudioDraftDto(
            d.getId(),
            d.getDifficulty() != null ? d.getDifficulty().name() : null,
            d.getCompetenceCode(),
            d.getTheme() != null ? d.getTheme().getId() : null,
            d.getTheme() != null ? d.getTheme().getName() : null,
            d.getTranscriptText(),
            d.getStatement(),
            d.getExplanation(),
            choices,
            d.getVoiceRecommended(),
            d.getInlineSvg(),
            d.getImageUrl(),
            d.getImageAltText(),
            d.getStatus(),
            d.getAudioUrl(),
            d.getAudioDurationSec(),
            d.getAudioVoiceUsed(),
            d.getAudioGeneratedAt(),
            d.getBatchId(),
            d.getCreatedAt(),
            d.getRejectionReason()
        );
    }
}
