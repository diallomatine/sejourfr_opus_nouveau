package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.UUID;

/**
 * Sujet diagnostic servi à un visiteur <strong>non authentifié</strong>.
 *
 * <p>Volontairement sans {@code attemptId}, {@code submissionId} ni
 * {@code submissionStatus} : ces trois champs n'existent qu'une fois la session
 * créée, donc après l'inscription. Tant que le visiteur n'a pas de compte, sa
 * production vit côté client et rien n'est écrit en base.
 */
public record PublicDiagnosticExerciseDto(
        UUID productionTaskId,
        EpreuveType epreuve,
        String title,
        String instruction,
        String helperText,
        Integer wordsMin,
        Integer wordsMax,
        Integer durationMinSeconds,
        Integer durationMaxSeconds,
        String instructionAudioUrl
) {}
