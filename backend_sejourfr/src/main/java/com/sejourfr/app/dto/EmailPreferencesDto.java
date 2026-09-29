package com.sejourfr.app.dto;

/**
 * {@code GET /api/me/email-preferences} — les preferences servies, valeurs par
 * defaut comprises quand aucune ligne n'existe. Aucun champ ne concerne les
 * mails REQUIRED : ils ne se desactivent pas.
 */
public record EmailPreferencesDto(boolean engagementEnabled, boolean marketingEnabled) {
}
