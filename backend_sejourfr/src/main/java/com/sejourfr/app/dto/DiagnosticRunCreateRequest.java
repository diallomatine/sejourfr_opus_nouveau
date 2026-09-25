package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Creation d'une {@code diagnostic_run} ({@code POST /api/public/diagnostic-runs}),
 * a l'affichage du sujet (premiere question).
 *
 * @param diagnosticType {@code QUICK_TCF} | {@code FULL_TCF} | {@code CIVIQUE}
 * @param clientKey      cle d'idempotence tiree par le client, <b>une par
 *                       passage</b> (conservee avec le brouillon) : un rejeu
 *                       avec la meme cle et le meme {@code X-Sejourfr-Anonymous-Id}
 *                       rend la meme run
 * @param sessionId      facultatif : la session deja ouverte que cette run
 *                       trace ({@code civic_diagnostic_sessions} pour
 *                       {@code CIVIQUE}, {@code tcf_diagnostic_sessions} pour
 *                       {@code FULL_TCF}, {@code diagnostic_sessions} pour
 *                       {@code QUICK_TCF} connecte). Verifiee serveur :
 *                       elle doit appartenir a l'appelant (compte, ou IP pour
 *                       une session civique invitee)
 */
public record DiagnosticRunCreateRequest(
        @NotBlank(message = "diagnosticType requis") String diagnosticType,
        @NotNull(message = "clientKey requis") UUID clientKey,
        UUID sessionId
) {}
