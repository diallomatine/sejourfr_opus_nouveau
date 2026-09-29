package com.sejourfr.app.dto;

/**
 * « Soumis » d'une run {@code QUICK_TCF} ({@code POST /api/public/diagnostic-runs/{id}/submit}).
 *
 * @param claimToken le jeton rendu a la creation. Facultatif si l'appelant est
 *                   connecte et porte deja la run ; sinon c'est lui qui prouve
 *                   que la run est la sienne (le runId n'est pas un secret)
 */
public record DiagnosticRunSubmitRequest(String claimToken) {}
