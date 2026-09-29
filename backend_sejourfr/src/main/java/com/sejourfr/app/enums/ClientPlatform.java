package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Plateforme d'ou vient un appel, telle que le client la declare
 * ({@code X-Sejourfr-Client}).
 *
 * <p>{@link #UNKNOWN} n'est pas une erreur : c'est le cas d'un client qui n'a
 * pas (encore) pose l'en-tete, et de tout ce qui est anterieur a la mesure. On
 * ne devine PAS la plateforme depuis le {@code User-Agent} — une heuristique
 * fausse est pire qu'une absence declaree, parce qu'elle se mele aux vrais
 * chiffres sans se signaler.
 *
 * <p>{@link #MOBILE} est la valeur <b>historique</b> de l'application, d'avant
 * la distinction iOS / Android (chantier Suivi, Q4). Elle reste acceptee et
 * reste lue telle quelle : une ligne {@code MOBILE} est une application dont on
 * ne sait pas le systeme, jamais une repartition devinee entre les deux.
 */
public enum ClientPlatform {
    WEB,
    IOS,
    ANDROID,
    /** Application, systeme non declare (clients anterieurs a iOS / Android). */
    MOBILE,
    UNKNOWN;

    /** Plateforme declaree par un client, {@link #UNKNOWN} pour tout le reste. */
    public static ClientPlatform parse(String raw) {
        if (raw == null || raw.isBlank()) return UNKNOWN;
        return switch (raw.trim().toLowerCase(Locale.ROOT)) {
            case "web" -> WEB;
            case "ios" -> IOS;
            case "android" -> ANDROID;
            case "mobile" -> MOBILE;
            default -> UNKNOWN;
        };
    }

    /** Vrai pour l'application native, systeme connu ou non. */
    public boolean isNativeApp() {
        return this == IOS || this == ANDROID || this == MOBILE;
    }

    /** Valeur affichable d'une plateforme lue en base, {@code null} compris. */
    public static String readOrUnknown(String stored) {
        if (stored == null || stored.isBlank()) return UNKNOWN.name();
        return stored;
    }
}
