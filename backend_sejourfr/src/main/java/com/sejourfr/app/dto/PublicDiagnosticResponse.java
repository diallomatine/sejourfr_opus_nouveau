package com.sejourfr.app.dto;

/**
 * Les deux sujets de la version active du diagnostic, servis sans compte.
 *
 * <p>Le couple {@code diagnosticCode} / {@code diagnosticVersion} est renvoyé
 * pour que les fronts sachent à quelle version se rattache la production
 * conservée côté client : si la version a changé entre la rédaction et
 * l'inscription, la session créée servira d'autres sujets.
 */
public record PublicDiagnosticResponse(
        String diagnosticCode,
        int diagnosticVersion,
        PublicDiagnosticExerciseDto written,
        PublicDiagnosticExerciseDto oral
) {}
