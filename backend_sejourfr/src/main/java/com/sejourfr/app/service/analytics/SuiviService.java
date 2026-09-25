package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminSuiviResponse;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.enums.SuiviPeriodPreset;
import com.sejourfr.app.enums.SuiviPlatformFilter;
import com.sejourfr.app.enums.SuiviTypeFilter;
import com.sejourfr.app.manager.SuiviReadManager;
import com.sejourfr.app.mapper.SuiviMapper;
import com.sejourfr.app.util.FenetreMesure;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Le dashboard « Suivi » ({@code GET /api/admin/analytics/suivi}) : resout la
 * periode et les filtres, lit les six agregats, applique les dates de debut de
 * mesure (Q16, D43), rend la reponse. Definitions de chaque indicateur :
 * {@code docs/regles/mesure-audience.md} § « Lecture du dashboard Suivi ».
 *
 * <p>Aucun cache : la lecture est constante (six requetes) et tient sous la
 * seconde sur un jeu realiste ({@code SuiviPerformanceIT}).
 */
@Service
@RequiredArgsConstructor
public class SuiviService {

    private final SuiviReadManager readManager;
    private final SuiviMapper mapper;
    private final AnalyticsConfig config;
    private final Clock clock;

    /**
     * @throws IllegalArgumentException (→ 400) filtre inconnu, periode incoherente,
     *         ou {@code preset} fourni avec {@code from}/{@code to}
     */
    public AdminSuiviResponse suivi(String preset, String from, String to, String type, String platform,
                                    String source, boolean includeInternal) {
        return compute(query(preset, from, to, type, platform, source, includeInternal), measurementStarts());
    }

    /**
     * Le calcul, dates de debut de mesure fournies. Public pour que les tests
     * d'acceptation lisent le vrai calcul sans dependre des dates de la config
     * de production (toutes {@code null} tant que le proprietaire ne les a pas
     * posees au deploiement).
     */
    public AdminSuiviResponse compute(SuiviQuery query, Map<SuiviIndicator, LocalDate> starts) {
        FenetreMesure previous = query.previousWindow();
        int windowDays = config.cohortWindowDays();
        Instant from = query.window().startInstant();
        Instant to = query.window().endInstantExclusive();
        SuiviReadManager.Lectures lectures = readManager.lire(new SuiviReadManager.Requete(
                previous.startInstant(), from, to, to.plus(Duration.ofDays(windowDays)), windowDays,
                query.type() == SuiviTypeFilter.ALL ? null : query.type().name(),
                runType(query.type()),
                query.platform() == SuiviPlatformFilter.ALL ? null : query.platform().name(),
                query.source(), query.includeInternal(), sourceMapJson(), config.utmSourceFallbackGroup(),
                config.civicSubmittedMinAnsweredRatio()));
        SuiviMapper.Mesure mesure = new SuiviMapper.Mesure(starts, query.window().from(), previous.from(),
                SuiviMapper.needsPlatformDetail(query.platform()));
        return mapper.toResponse(query, previous, windowDays, clock.instant(), availableSources(), starts,
                mesure, lectures);
    }

    /** Filtres valides ; {@code preset} par defaut : aujourd'hui. */
    public SuiviQuery query(String preset, String from, String to, String type, String platform,
                            String source, boolean includeInternal) {
        boolean custom = !blank(from) || !blank(to);
        if (custom && !blank(preset)) {
            throw new IllegalArgumentException(
                    "Indiquez soit « preset », soit « from » et « to », pas les deux.");
        }
        SuiviPeriodPreset appliedPreset = custom ? null
                : blank(preset) ? SuiviPeriodPreset.TODAY : SuiviPeriodPreset.parse(preset);
        FenetreMesure window = custom ? FenetreMesure.resolve(from, to, 1) : window(appliedPreset);
        return new SuiviQuery(appliedPreset, window, SuiviTypeFilter.parse(type),
                SuiviPlatformFilter.parse(platform), source(source), includeInternal);
    }

    /** Dates de debut de mesure de la config, une entree par indicateur ({@code null} = pas mesure). */
    public Map<SuiviIndicator, LocalDate> measurementStarts() {
        Map<SuiviIndicator, LocalDate> starts = new EnumMap<>(SuiviIndicator.class);
        for (SuiviIndicator indicator : SuiviIndicator.values()) {
            starts.put(indicator, config.measurementStartOf(indicator).orElse(null));
        }
        return starts;
    }

    private FenetreMesure window(SuiviPeriodPreset preset) {
        LocalDate today = LocalDate.ofInstant(clock.instant(), FenetreMesure.PARIS);
        return switch (preset) {
            case TODAY -> new FenetreMesure(today, today);
            case YESTERDAY -> new FenetreMesure(today.minusDays(1), today.minusDays(1));
            case LAST_7_DAYS -> new FenetreMesure(today.minusDays(6), today);
            case MONTH -> new FenetreMesure(today.withDayOfMonth(1), today);
        };
    }

    private static String runType(SuiviTypeFilter type) {
        return switch (type) {
            case ALL -> null;
            case TCF -> "QUICK_TCF";
            case CIVIQUE -> "CIVIQUE";
        };
    }

    /** Groupes de la config dans leur ordre, repli en dernier : les seules valeurs de {@code source}. */
    List<String> availableSources() {
        List<String> groups = new ArrayList<>(config.utmSourceGroups().keySet());
        groups.add(config.utmSourceFallbackGroup());
        return groups;
    }

    private String source(String raw) {
        if (blank(raw) || "ALL".equalsIgnoreCase(raw.trim())) return null;
        String value = raw.trim().toLowerCase(Locale.ROOT);
        List<String> groups = availableSources();
        if (!groups.contains(value)) {
            throw new IllegalArgumentException("Valeur invalide pour « source » : « " + raw
                    + " ». Attendu : ALL ou l'un de " + groups + ".");
        }
        return value;
    }

    /**
     * {@code utmSourceGroups} inverse en objet JSON source declaree → groupe,
     * pour le regroupement en SQL. Les cles et groupes sont des slugs
     * {@code [a-z0-9._-]} (verifies au boot par {@link AnalyticsConfigLoader}) :
     * aucun echappement n'est necessaire.
     */
    String sourceMapJson() {
        StringBuilder json = new StringBuilder("{");
        for (Map.Entry<String, List<String>> group : config.utmSourceGroups().entrySet()) {
            for (String source : group.getValue()) {
                if (json.length() > 1) json.append(',');
                json.append('"').append(source).append("\":\"").append(group.getKey()).append('"');
            }
        }
        return json.append('}').toString();
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }
}
