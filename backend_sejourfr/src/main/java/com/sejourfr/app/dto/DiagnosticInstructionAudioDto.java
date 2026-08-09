package com.sejourfr.app.dto;

import java.util.UUID;

/** État vérifiable de l'audio fixe d'un sujet diagnostic EO. */
public record DiagnosticInstructionAudioDto(
        UUID taskId,
        String diagnosticCode,
        int diagnosticVersion,
        String objectKey,
        String audioUrl,
        boolean azureConfigured,
        boolean r2Configured,
        boolean objectPresent,
        boolean generatedNow
) {}
