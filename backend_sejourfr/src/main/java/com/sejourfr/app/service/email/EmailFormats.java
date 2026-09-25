package com.sejourfr.app.service.email;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/**
 * Formats partages des variables d'email. Les dates partent DEJA formatees en
 * francais : un template Brevo ne formate pas une date ISO.
 */
public final class EmailFormats {

    /** Le fuseau de tout le systeme d'emails : jours calendaires, plafond, dates. */
    public static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private static final String[] MOIS = {
            "janvier", "février", "mars", "avril", "mai", "juin",
            "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    };

    private EmailFormats() {
    }

    /** « 20 octobre 2026 ». {@code null} rend une chaine vide : rien n'est invente. */
    public static String date(Instant instant) {
        if (instant == null) return "";
        LocalDate d = instant.atZone(PARIS).toLocalDate();
        return d.getDayOfMonth() + " " + MOIS[d.getMonthValue() - 1] + " " + d.getYear();
    }

    /** « 20 octobre 2026 à 14 h 05 ». */
    public static String dateTime(Instant instant) {
        if (instant == null) return "";
        var t = instant.atZone(PARIS);
        return date(instant) + " à " + t.getHour() + " h " + String.format("%02d", t.getMinute());
    }

    public static String firstName(String firstName) {
        return firstName == null ? "" : firstName.trim();
    }

    /**
     * La salutation, vouvoyante : « Bonjour Alice » ou « Bonjour ». L'ancien repli
     * « à toi » tutoyait alors que tous les gabarits vouvoient.
     */
    public static String greeting(String firstName) {
        String name = firstName(firstName);
        return name.isEmpty() ? "Bonjour" : "Bonjour " + name;
    }
}
