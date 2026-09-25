package com.sejourfr.app.dto;

/**
 * Une run de diagnostic a rattacher a l'authentification (controle N3) : un
 * element de {@code diagnosticRunClaims} des requetes d'auth. Memes champs, et
 * memes regles, que le trio unique historique ({@code diagnosticRunId},
 * {@code claimToken}, {@code claimVia}) : textes libres, un element illisible,
 * faux ou expire ne claime rien et ne fait jamais echouer l'auth.
 *
 * @param diagnosticRunId UUID de la run, en texte
 * @param claimToken      jeton rendu a la creation de la run
 * @param claimVia        {@code "APP_LINK"} si la run est arrivee par le lien
 *                        web → app ; toute autre valeur ou rien = {@code SAME_DEVICE}
 */
public record DiagnosticRunClaimRequest(String diagnosticRunId, String claimToken, String claimVia) {
}
