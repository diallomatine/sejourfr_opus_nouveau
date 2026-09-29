package com.sejourfr.app.util;

import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

/**
 * Fenêtre de mesure d'une console admin — <strong>autorité unique</strong>,
 * partagée par l'audience anonyme des landings et le funnel par compte.
 *
 * <p>Deux façons de la désigner, jamais trois : soit une paire de dates
 * {@code from}/{@code to} (bornes <b>incluses</b>, Europe/Paris), soit un
 * nombre de jours glissants. La paire l'emporte quand elle est fournie. Les
 * libellés (« hier », « ce mois ») vivent côté admin : le serveur ne reçoit que
 * deux dates, et n'a donc aucune règle de calendrier à dupliquer.
 *
 * <p><strong>Un demi-intervalle est une erreur nommée, jamais un repli muet</strong>
 * sur {@code days} : rendre la fenêtre par défaut à qui a demandé une date
 * précise afficherait des chiffres qu'on croirait filtrés — le pire des cas,
 * puisqu'il ne se voit pas.
 *
 * <p>Une borne de fin dans le futur est <strong>acceptée</strong> et ramenée à
 * aujourd'hui : cliquer un jour à venir dans un sélecteur de date n'est pas une
 * faute de l'appelant, et il n'existe de toute façon aucune donnée après
 * aujourd'hui. La fenêtre <em>réellement appliquée</em> est ensuite rendue dans
 * la réponse, pour que l'écran puisse prouver ce qu'il affiche.
 *
 * @param from premier jour couvert, inclus
 * @param to   dernier jour couvert, inclus
 */
public record FenetreMesure(LocalDate from, LocalDate to) {

    public static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    /** Même plafond que le clamp historique, et pour la même raison. */
    public static final int MAX_WINDOW_DAYS = 365;

    /**
     * Résout la fenêtre demandée.
     *
     * @param rawFrom borne de début ISO {@code yyyy-MM-dd}, ou {@code null}
     * @param rawTo   borne de fin ISO {@code yyyy-MM-dd}, ou {@code null}
     * @param days    repli en jours glissants quand aucune borne n'est fournie
     * @throws IllegalArgumentException (→ 400) si une seule borne est fournie,
     *         si une date est illisible, si {@code from > to}, ou si l'amplitude
     *         dépasse {@link #MAX_WINDOW_DAYS}
     */
    public static FenetreMesure resolve(String rawFrom, String rawTo, int days) {
        String start = blankToNull(rawFrom);
        String end = blankToNull(rawTo);

        if (start == null && end == null) {
            int window = Math.clamp(days, 1, MAX_WINDOW_DAYS);
            LocalDate today = LocalDate.now(PARIS);
            return new FenetreMesure(today.minusDays(window - 1L), today);
        }
        if (start == null) {
            throw new IllegalArgumentException(
                    "Paramètre « from » manquant : indiquez les deux bornes (from et to) "
                    + "ou aucune des deux.");
        }
        if (end == null) {
            throw new IllegalArgumentException(
                    "Paramètre « to » manquant : indiquez les deux bornes (from et to) "
                    + "ou aucune des deux.");
        }

        LocalDate parsedFrom = parse(start, "from");
        LocalDate parsedTo = parse(end, "to");
        if (parsedFrom.isAfter(parsedTo)) {
            throw new IllegalArgumentException(
                    "Période invalide : « from » (" + parsedFrom + ") est postérieur à « to » ("
                    + parsedTo + ").");
        }

        // Une borne future est ramenée à aujourd'hui, jamais refusée. Si les
        // DEUX le sont, la fenêtre se réduit à la journée d'aujourd'hui plutôt
        // que de devenir vide : c'est ce que l'appelant voit, et la réponse le
        // dit en rendant les bornes appliquées.
        LocalDate today = LocalDate.now(PARIS);
        LocalDate appliedTo = parsedTo.isAfter(today) ? today : parsedTo;
        LocalDate appliedFrom = parsedFrom.isAfter(appliedTo) ? appliedTo : parsedFrom;

        long span = ChronoUnit.DAYS.between(appliedFrom, appliedTo) + 1;
        if (span > MAX_WINDOW_DAYS) {
            throw new IllegalArgumentException(
                    "Période trop large : " + span + " jours demandés, maximum "
                    + MAX_WINDOW_DAYS + ".");
        }
        return new FenetreMesure(appliedFrom, appliedTo);
    }

    /** Nombre de jours réellement couverts, bornes incluses. Vaut 1 sur une journée. */
    public int days() {
        return (int) (ChronoUnit.DAYS.between(from, to) + 1);
    }

    /** Instant du premier tic de la fenêtre (inclus). */
    public java.time.Instant startInstant() {
        return from.atStartOfDay(PARIS).toInstant();
    }

    /** Instant du premier tic APRÈS la fenêtre (exclu) — borne de fin incluse. */
    public java.time.Instant endInstantExclusive() {
        return to.plusDays(1).atStartOfDay(PARIS).toInstant();
    }

    private static LocalDate parse(String raw, String name) {
        try {
            return LocalDate.parse(raw);
        } catch (DateTimeException e) {
            throw new IllegalArgumentException(
                    "Date illisible pour « " + name + " » : « " + raw
                    + " ». Format attendu : yyyy-MM-dd.");
        }
    }

    private static String blankToNull(String raw) {
        if (raw == null) return null;
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
