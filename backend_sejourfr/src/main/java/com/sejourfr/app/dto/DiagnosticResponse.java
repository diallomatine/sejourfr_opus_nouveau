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
        /**
         * Le <b>format</b> du diagnostic — combien d'exercices, et leurs
         * mesures. 🛑 <b>Toujours servi</b>, y compris sur un parcours
         * {@code NOT_STARTED} ou {@code written} et {@code oral} valent
         * {@code null} : c'est precisement la que les fronts en ont besoin, et
         * c'est faute de l'avoir qu'ils annonçaient « 2 exercices » sur un
         * diagnostic qui n'en a qu'un. Cf. {@link DiagnosticFormatDto}.
         */
        DiagnosticFormatDto format,
        DiagnosticResultDto result,
        Instant startedAt,
        Instant completedAt,
        String errorMessage,
        boolean canRetry
) {}
