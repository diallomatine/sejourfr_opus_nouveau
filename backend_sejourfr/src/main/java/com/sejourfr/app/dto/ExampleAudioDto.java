package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ExampleAudioStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Vue admin d'un exemple EO et de l'état de son audio (génération / validation).
 */
public record ExampleAudioDto(
        UUID id,
        UUID taskId,
        String titre,
        String resume,
        String contenu,
        ExampleAudioStatus audioStatus,
        String audioUrl,
        String audioVoice,
        Integer audioDurationSec,
        Instant audioGeneratedAt,
        UUID audioBatchId,
        String audioError,
        Instant createdAt
) {
}
