package com.sejourfr.app.util;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

/**
 * <b>Seul endroit</b> où une date métier saisie par l'admin devient un instant,
 * et inversement (spec §2.5, GO §10, décision G-7). Europe/Paris.
 *
 * <ul>
 *   <li>Fin saisie « jusqu'au 31/10/2026 inclus » → borne EXCLUSIVE
 *       {@code 01/11/2026 00:00 Europe/Paris}. Jamais de {@code 23:59:59}.</li>
 *   <li>Début « aujourd'hui » → maintenant ; début futur → 00:00 Paris ce jour-là.</li>
 *   <li>Une fin d'ACHAT reste un instant exact (à l'heure de l'achat) : elle
 *       s'affiche avec l'heure, jamais arrondie, jamais réécrite.</li>
 * </ul>
 * Aucun front ne refait ce calcul : il reçoit la date incluse servie.
 */
public final class DateMetierParis {

    private static final DateTimeFormatter JOUR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter JOUR_HEURE = DateTimeFormatter.ofPattern("dd/MM/yyyy 'à' HH:mm");

    private DateMetierParis() {}

    public static LocalDate aujourdhui(Instant now) {
        return LocalDate.ofInstant(now, FenetreMesure.PARIS);
    }

    /** Début d'une décision : maintenant si la date est aujourd'hui, minuit Paris sinon. */
    public static Instant debut(LocalDate date, Instant now) {
        return date.equals(aujourdhui(now)) ? now : minuit(date);
    }

    /** Borne de fin EXCLUSIVE d'une date de fin incluse : le lendemain à 00:00 Paris. */
    public static Instant finExclusive(LocalDate finIncluse) {
        return minuit(finIncluse.plusDays(1));
    }

    public static Instant minuit(LocalDate date) {
        return date.atStartOfDay(FenetreMesure.PARIS).toInstant();
    }

    /**
     * La date de fin INCLUSE d'une borne exclusive, si et seulement si cette
     * borne tombe pile à minuit Paris (fin posée par une décision admin). Une
     * fin d'achat, à l'heure de l'achat, n'en a pas : elle s'affiche avec l'heure.
     */
    public static Optional<LocalDate> finIncluse(Instant finExclusive) {
        if (finExclusive == null) return Optional.empty();
        ZonedDateTime z = finExclusive.atZone(FenetreMesure.PARIS);
        if (!z.toLocalTime().equals(java.time.LocalTime.MIDNIGHT)) return Optional.empty();
        return Optional.of(z.toLocalDate().minusDays(1));
    }

    /**
     * La date que la modale admin propose par défaut dans « Fin (incluse) » pour
     * cette borne : la date incluse d'une fin admin, sinon le jour (Paris) où
     * finit l'achat — même convention que « fin actuelle de A » d'une correction
     * de produit (spec §2.6). Valeur de pré-remplissage seulement.
     */
    public static Optional<LocalDate> finProposee(Instant finExclusive) {
        if (finExclusive == null) return Optional.empty();
        return finIncluse(finExclusive).or(() -> Optional.of(aujourdhui(finExclusive)));
    }

    /** « 31/10/2026 inclus » pour une fin admin, « 01/11/2026 à 14:37 » pour une fin d'achat. */
    public static String libelleFin(Instant finExclusive) {
        return finIncluse(finExclusive)
                .map(d -> d.format(JOUR) + " inclus")
                .orElseGet(() -> finExclusive.atZone(FenetreMesure.PARIS).format(JOUR_HEURE));
    }

    public static String jour(Instant instant) {
        return instant.atZone(FenetreMesure.PARIS).format(JOUR);
    }

    public static String jour(LocalDate date) {
        return date.format(JOUR);
    }
}
