package com.sejourfr.app.dto;

/**
 * {@code PATCH /api/me/email-preferences} — un champ absent ({@code null}) ne
 * change rien. Passer {@code marketingEnabled} a {@code true} date le
 * consentement.
 */
public record UpdateEmailPreferencesRequest(Boolean engagementEnabled, Boolean marketingEnabled) {
}
