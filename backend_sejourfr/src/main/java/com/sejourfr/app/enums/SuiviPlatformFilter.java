package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Filtre « plateforme » du dashboard « Suivi » (brief §7.1). Les lignes
 * historiques {@link ClientPlatform#MOBILE} (systeme inconnu) et
 * {@link ClientPlatform#UNKNOWN} ne sont comptees que sous {@link #ALL} : on ne
 * les reverse jamais dans iOS ou Android.
 */
public enum SuiviPlatformFilter {
    ALL,
    WEB,
    IOS,
    ANDROID;

    /**
     * @throws IllegalArgumentException (→ 400) valeur inconnue
     */
    public static SuiviPlatformFilter parse(String raw) {
        if (raw == null || raw.isBlank()) return ALL;
        String value = raw.trim().toUpperCase(Locale.ROOT);
        for (SuiviPlatformFilter platform : values()) {
            if (platform.name().equals(value)) return platform;
        }
        throw new IllegalArgumentException("Valeur invalide pour « platform » : « " + raw
                + " ». Attendu : ALL, WEB, IOS ou ANDROID.");
    }
}
