package com.sejourfr.app.dto;

import com.sejourfr.app.enums.DiagnosticJourneyStatus;
import com.sejourfr.app.enums.DiagnosticStep;

import java.time.Instant;
import java.util.UUID;

/** Contrat agrégé partagé par web et mobile pour démarrer, reprendre et lire. */
public record DiagnosticResponse(
        UUID sessionId,
        String diagnosticCode,
        Integer diagnosticVersion,
        DiagnosticJourneyStatus status,
        DiagnosticStep nextStep,
        DiagnosticExerciseDto written,
        DiagnosticExerciseDto oral,
        DiagnosticResultDto result,
        Instant startedAt,
        Instant completedAt,
        String errorMessage,
        boolean canRetry
) {}
