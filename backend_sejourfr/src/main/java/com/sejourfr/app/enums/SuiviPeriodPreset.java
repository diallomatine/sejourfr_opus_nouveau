package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Periodes predefinies du dashboard « Suivi » (brief §7.1), resolues en jours
 * Europe/Paris par le serveur. « Personnalise » n'est pas un preset : c'est la
 * paire {@code from}/{@code to}.
 */
public enum SuiviPeriodPreset {
    /** Aujourd'hui (Paris). */
    TODAY,
    /** Hier (Paris). */
    YESTERDAY,
    /** Les 7 derniers jours, aujourd'hui compris. */
    LAST_7_DAYS,
    /** Du 1er du mois en cours a aujourd'hui. */
    MONTH;

    /**
     * @throws IllegalArgumentException (→ 400) valeur inconnue, avec un message nomme
     */
    public static SuiviPeriodPreset parse(String raw) {
        String value = raw == null ? "" : raw.trim().toUpperCase(Locale.ROOT);
        for (SuiviPeriodPreset preset : values()) {
            if (preset.name().equals(value)) return preset;
        }
        throw new IllegalArgumentException("Valeur invalide pour « preset » : « " + raw
                + " ». Attendu : TODAY, YESTERDAY, LAST_7_DAYS ou MONTH.");
    }
}
