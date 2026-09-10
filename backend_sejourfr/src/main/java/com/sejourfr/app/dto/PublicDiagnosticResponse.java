package com.sejourfr.app.dto;

/**
 * Les sujets de la version active du diagnostic, servis sans compte.
 *
 * <p>Le couple {@code diagnosticCode} / {@code diagnosticVersion} est renvoyé
 * pour que les fronts sachent à quelle version se rattache la production
 * conservée côté client : si la version a changé entre la rédaction et
 * l'inscription, la session créée servira d'autres sujets.
 *
 * <p>🛑 <b>{@code written.taskId} doit être renvoyé</b> à
 * {@code POST /api/diagnostics?writtenTaskId=…} : depuis L3 le sujet est
 * <b>tiré dans un pool</b>, et sans cet identifiant la session serait créée sur
 * un autre énoncé que celui qui a été rédigé.
 *
 * <p>🛑 <b>{@code oral} peut être {@code null}</b> — le diagnostic rapide n'a
 * pas d'étape orale ({@code 50_} §3.2). Ce n'est pas une panne : un front qui
 * le traiterait comme telle bloquerait tout le parcours.
 */
public record PublicDiagnosticResponse(
        String diagnosticCode,
        int diagnosticVersion,
        PublicDiagnosticExerciseDto written,
        /** {@code null} = ce diagnostic n'a pas d'étape orale. */
        PublicDiagnosticExerciseDto oral
) {}
