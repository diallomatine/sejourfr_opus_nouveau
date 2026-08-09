package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;

import java.util.UUID;

/** Sujet fixe et état de rendu d'une étape du diagnostic. */
public record DiagnosticExerciseDto(
        UUID productionTaskId,
        UUID attemptId,
        EpreuveType epreuve,
        String title,
        String instruction,
        String helperText,
        Integer wordsMin,
        Integer wordsMax,
        Integer durationMinSeconds,
        Integer durationMaxSeconds,
        String instructionAudioUrl,
        UUID submissionId,
        SubmissionStatut submissionStatus
) {}
