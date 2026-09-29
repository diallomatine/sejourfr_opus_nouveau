package com.sejourfr.app.dto;

import com.sejourfr.app.enums.DiagnosticRunType;

import java.time.Instant;
import java.util.UUID;

/**
 * Reponse de creation d'une {@code diagnostic_run}.
 *
 * <p>🛑 <b>{@code claimToken} est un secret</b> : le client le garde avec le
 * brouillon du diagnostic (IndexedDB / SharedPreferences) et ne le transmet
 * qu'a « soumis » et aux requetes d'auth. Il ne part <b>jamais</b> dans un
 * evenement d'analytics. {@code diagnosticRunId}, lui, est un identifiant : il
 * voyage dans les evenements. Un rejeu de la creation rend la meme run et un
 * <b>nouveau</b> jeton (seul le hash est stocke) : le client garde toujours la
 * derniere reponse.
 *
 * @param created {@code false} si la run existait deja (rejeu de la cle, ou
 *                session deja tracee par une run)
 */
public record DiagnosticRunCreatedResponse(
        UUID diagnosticRunId,
        DiagnosticRunType diagnosticType,
        String claimToken,
        Instant claimTokenExpiresAt,
        Instant subjectViewedAt,
        boolean created
) {}
