package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPeriodPreset;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Reponse de {@code GET /api/admin/analytics/activity} — l'ecran « Activite »
 * de la console ({@code /dashboard/activity}, D9). Contrat publie dans
 * {@code docs/admin/activites/decisions-implementation.md} § Contrat.
 *
 * <p>🛑 <b>{@code null} = non mesure</b> (avant la date de debut de mesure de
 * l'indicateur), jamais 0. Une periode qui chevauche la date est lue depuis
 * cette date ({@code measuredSince}, D117) ; la periode precedente n'est lue que
 * si elle est mesuree de bout en bout. Pourcentages en pourcent, une decimale.
 * Libelles servis : le front n'en calcule aucun.
 */
public record AdminActivityResponse(
        Window window,
        boolean includeInternal,
        /** Les quatre indicateurs de l'activite ; valeur {@code null} = pas encore mesure. */
        Map<SuiviIndicator, LocalDate> measurementStart,
        ActiveUsers activeUsers,
        Logins logins,
        /** Les cinq plateformes, dans l'ordre. */
        List<PlatformRow> platforms,
        Screens screens
) {

    public record Window(SuiviPeriodPreset preset, LocalDate from, LocalDate to, LocalDate previousFrom,
                         LocalDate previousTo, String timezone, Instant generatedAt) {
    }

    /**
     * @param deltaPct variation en %, {@code null} si {@code previous} est
     *                 inconnu ou vaut 0
     */
    public record Kpi(Long value, Long previous, Double deltaPct) {
    }

    /** Un jour de la periode : comptes actifs distincts (serie continue, non additive). */
    public record DailyPoint(LocalDate day, Long total, List<ActivityPlatformCount> byPlatform) {
    }

    public record ActiveUsers(LocalDate measuredSince, Kpi total, Long multiPlatformUsers,
                              List<DailyPoint> daily) {
    }

    public record MethodCount(AuthProvider method, String label, Long value) {
    }

    /**
     * @param uniqueUsers comptes distincts ayant ouvert au moins une session
     * @param total       ouvertures de session (login + inscription)
     * @param signups     dont inscriptions
     */
    public record Logins(LocalDate measuredSince, Kpi uniqueUsers, Long total, Long signups,
                         List<MethodCount> byMethod) {
    }

    /**
     * Une ligne du tableau de repartition par plateforme.
     *
     * @param activeUsers   comptes actifs distincts
     * @param loggedInUsers comptes distincts ayant ouvert une session
     * @param logins        ouvertures de session
     */
    public record PlatformRow(ClientPlatform platform, String label, boolean displayed, Long activeUsers,
                              Long loggedInUsers, Long logins) {
    }

    public enum ScreenRowKind { SCREEN, OTHER, UNDECLARED, TOTAL }

    /**
     * @param path           gabarit suivi ({@code SCREEN}), sinon {@code null}
     * @param uniqueVisitors identifiants de mesure distincts
     * @param uniqueUsers    comptes distincts — PARTIEL (un lot sans jeton n'a pas de compte)
     * @param ios            vues iOS (onglet App), {@code null} sur l'onglet Web
     */
    public record ScreenRow(ScreenRowKind kind, String path, String label, long views, long uniqueVisitors,
                            long uniqueUsers, Long ios, Long android, Long appUnknownSystem) {
    }

    /**
     * @param measuredSince premier jour mesure de la periode ; {@code null} = non
     *                      mesure ({@code rows} vide, lignes de synthese nulles)
     * @param rows          les {@code topLimit} ecrans les plus vus
     * @param otherTracked  ecrans suivis hors top (uniques non additifs, calcules en SQL)
     */
    public record ScreenTable(LocalDate measuredSince, int topLimit, List<ScreenRow> rows,
                              ScreenRow otherTracked, ScreenRow undeclared, ScreenRow total) {
    }

    public record Screens(ScreenTable web, ScreenTable app) {
    }
}
