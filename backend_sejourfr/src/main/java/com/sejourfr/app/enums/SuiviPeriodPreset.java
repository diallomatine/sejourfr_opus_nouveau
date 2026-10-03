package com.sejourfr.app.enums;

import com.sejourfr.app.util.FenetreMesure;

import java.time.LocalDate;
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
    /** Les 30 derniers jours, aujourd'hui compris (D10, chantier « Activite »). */
    LAST_30_DAYS,
    /** Du 1er du mois en cours a aujourd'hui. */
    MONTH;

    /**
     * Les jours couverts, {@code today} etant aujourd'hui a Paris. <b>Autorite
     * unique</b> de la table des presets, lue par Suivi et par Activite.
     */
    public FenetreMesure window(LocalDate today) {
        return switch (this) {
            case TODAY -> new FenetreMesure(today, today);
            case YESTERDAY -> new FenetreMesure(today.minusDays(1), today.minusDays(1));
            case LAST_7_DAYS -> new FenetreMesure(today.minusDays(6), today);
            case LAST_30_DAYS -> new FenetreMesure(today.minusDays(29), today);
            case MONTH -> new FenetreMesure(today.withDayOfMonth(1), today);
        };
    }

    /**
     * @throws IllegalArgumentException (→ 400) valeur inconnue, avec un message nomme
     */
    public static SuiviPeriodPreset parse(String raw) {
        String value = raw == null ? "" : raw.trim().toUpperCase(Locale.ROOT);
        for (SuiviPeriodPreset preset : values()) {
            if (preset.name().equals(value)) return preset;
        }
        throw new IllegalArgumentException("Valeur invalide pour « preset » : « " + raw
                + " ». Attendu : TODAY, YESTERDAY, LAST_7_DAYS, LAST_30_DAYS ou MONTH.");
    }
}
