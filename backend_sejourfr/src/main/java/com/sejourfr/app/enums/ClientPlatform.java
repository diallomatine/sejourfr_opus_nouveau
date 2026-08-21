package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Plateforme d'ou vient un appel, telle que le client la declare.
 *
 * <p>{@link #UNKNOWN} n'est pas une erreur : c'est le cas d'un client qui n'a
 * pas (encore) pose l'en-tete, et de tout ce qui est anterieur a la mesure. On
 * ne devine PAS la plateforme depuis le {@code User-Agent} — une heuristique
 * fausse est pire qu'une absence declaree, parce qu'elle se mele aux vrais
 * chiffres sans se signaler.
 */
public enum ClientPlatform {
    WEB,
    MOBILE,
    UNKNOWN;

    /** Plateforme declaree par un client, {@link #UNKNOWN} pour tout le reste. */
    public static ClientPlatform parse(String raw) {
        if (raw == null || raw.isBlank()) return UNKNOWN;
        return switch (raw.trim().toLowerCase(Locale.ROOT)) {
            case "web" -> WEB;
            case "mobile" -> MOBILE;
            default -> UNKNOWN;
        };
    }

    /** Valeur affichable d'une plateforme lue en base, {@code null} compris. */
    public static String readOrUnknown(String stored) {
        if (stored == null || stored.isBlank()) return UNKNOWN.name();
        return stored;
    }
}
