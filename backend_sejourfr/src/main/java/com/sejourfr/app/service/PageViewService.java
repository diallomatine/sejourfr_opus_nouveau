package com.sejourfr.app.service;

import com.sejourfr.app.dto.PageViewRequest;
import com.sejourfr.app.dto.PageViewStatsResponse;
import com.sejourfr.app.entity.PageView;
import com.sejourfr.app.enums.PageViewEvent;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.PageViewManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Mesure d'audience des landings de campagne.
 *
 * <p><strong>Deux allowlists, et c'est tout ce qui protège la table.</strong>
 * L'endpoint d'écriture est public : sans contrainte sur les valeurs acceptées,
 * n'importe qui pourrait créer autant de dimensions qu'il veut et faire enfler
 * {@code page_views}. On n'accepte donc qu'une paire chemin/événement connue
 * ({@link #EVENTS_BY_PATH}) et une source connue ({@link #KNOWN_SOURCES}, tout
 * le reste retombant sur « autre »). La cardinalité maximale de la table est ainsi fixée à
 * pages × sources × événements × jours.
 *
 * <p>Ce qui reste possible : gonfler un compteur en martelant l'endpoint. C'est
 * de la donnée fausse, pas une fuite ni une inflation de stockage — le
 * garde-fou (rate-limit par IP sur les endpoints publics) est le même chantier
 * que celui déjà noté pour la démo invitée dans le CLAUDE.md racine.
 *
 * <p>Aucune donnée personnelle n'est manipulée ici : ni IP, ni user-agent, ni
 * identifiant de visiteur. C'est ce qui permet à /confidentialite de continuer
 * d'affirmer qu'aucun traceur n'est déposé.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class PageViewService {

    /** Événements autorisés par écran : borne la cardinalité et les incohérences. */
    public static final Map<String, Set<PageViewEvent>> EVENTS_BY_PATH = Map.of(
            "/reussir", EnumSet.of(
                    PageViewEvent.VIEW,
                    PageViewEvent.CTA,
                    PageViewEvent.SOCIAL_LANDING_DIAGNOSTIC_CLICKED),
            "/diagnostic", EnumSet.of(
                    PageViewEvent.DIAGNOSTIC_VIEWED,
                    PageViewEvent.DIAGNOSTIC_STARTED,
                    PageViewEvent.DIAGNOSTIC_WRITTEN_COMPLETED,
                    PageViewEvent.DIAGNOSTIC_ORAL_COMPLETED,
                    PageViewEvent.DIAGNOSTIC_COMPLETED,
                    PageViewEvent.DIAGNOSTIC_RESULT_VIEWED,
                    // Parcours invité : les deux productions sont faites, le
                    // compte est demandé. Compté à part des vues et des clics
                    // CTA — c'est une étape de funnel, lue dans `events`.
                    PageViewEvent.DIAGNOSTIC_ACCOUNT_REQUIRED,
                    PageViewEvent.DIAGNOSTIC_TO_PREMIUM_CLICKED),
            "/plan", EnumSet.of(
                    PageViewEvent.PLAN_OPENED,
                    PageViewEvent.PLAN_RECOMMENDED_EXERCISE_STARTED,
                    PageViewEvent.DIAGNOSTIC_TO_PREMIUM_CLICKED));

    /** Pages exposées à la console admin, conservé pour compatibilité. */
    public static final Set<String> TRACKED_PATHS = EVENTS_BY_PATH.keySet();

    /** Provenances normalisées. Une valeur inconnue est rangée dans « autre ». */
    public static final Set<String> KNOWN_SOURCES =
            Set.of("tiktok", "instagram", "whatsapp", "facebook", "youtube", "direct");

    private static final String OTHER_SOURCE = "autre";
    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");
    private static final int MAX_WINDOW_DAYS = 365;

    private final PageViewManager manager;

    /** Enregistre un événement d'audience. Idempotent du point de vue du schéma. */
    public void track(PageViewRequest request) {
        String path = request.path();
        if (!TRACKED_PATHS.contains(path)) {
            throw new BusinessException("Page non suivie : " + path);
        }
        if (!EVENTS_BY_PATH.get(path).contains(request.event())) {
            throw new BusinessException(
                    "Événement " + request.event() + " non autorisé sur " + path);
        }
        manager.increment(path, normalizeSource(request.source()), request.event(),
                LocalDate.now(PARIS));
    }

    /** Agrégat sur une fenêtre glissante de {@code days} jours, aujourd'hui inclus. */
    public PageViewStatsResponse stats(String path, int days) {
        if (!TRACKED_PATHS.contains(path)) {
            throw new BusinessException("Page non suivie : " + path);
        }
        int window = Math.clamp(days, 1, MAX_WINDOW_DAYS);
        LocalDate from = LocalDate.now(PARIS).minusDays(window - 1L);
        List<PageView> rows = manager.since(path, from);

        Map<String, long[]> bySource = new TreeMap<>();
        Map<LocalDate, long[]> byDay = new TreeMap<>();
        Map<String, Long> events = new TreeMap<>();
        for (PageView row : rows) {
            accumulate(bySource.computeIfAbsent(row.getSource(), k -> new long[2]), row);
            accumulate(byDay.computeIfAbsent(row.getDay(), k -> new long[2]), row);
            events.merge(row.getEvent().name(), row.getHits(), Long::sum);
        }

        List<PageViewStatsResponse.SourceStat> sources = bySource.entrySet().stream()
                .map(e -> new PageViewStatsResponse.SourceStat(
                        e.getKey(), e.getValue()[0], e.getValue()[1],
                        ctaRate(e.getValue()[0], e.getValue()[1])))
                .sorted(Comparator.comparingLong(PageViewStatsResponse.SourceStat::views).reversed())
                .toList();

        List<PageViewStatsResponse.DailyStat> daily = byDay.entrySet().stream()
                .map(e -> new PageViewStatsResponse.DailyStat(
                        e.getKey().toString(), e.getValue()[0], e.getValue()[1]))
                .toList();

        long views = sources.stream().mapToLong(PageViewStatsResponse.SourceStat::views).sum();
        long cta = sources.stream().mapToLong(PageViewStatsResponse.SourceStat::ctaClicks).sum();
        return new PageViewStatsResponse(path, window, views, cta, sources, daily, events);
    }

    private static void accumulate(long[] bucket, PageView row) {
        if (row.getEvent() == PageViewEvent.VIEW
                || row.getEvent() == PageViewEvent.DIAGNOSTIC_VIEWED
                || row.getEvent() == PageViewEvent.PLAN_OPENED) {
            bucket[0] += row.getHits();
        } else if (row.getEvent() == PageViewEvent.CTA
                || row.getEvent() == PageViewEvent.DIAGNOSTIC_STARTED
                || row.getEvent() == PageViewEvent.PLAN_RECOMMENDED_EXERCISE_STARTED
                || row.getEvent() == PageViewEvent.SOCIAL_LANDING_DIAGNOSTIC_CLICKED
                || row.getEvent() == PageViewEvent.DIAGNOSTIC_TO_PREMIUM_CLICKED) {
            bucket[1] += row.getHits();
        }
    }

    /** Null quand il n'y a aucune vue : 0/0 n'est pas « 0 % », c'est « pas de donnée ». */
    private static Double ctaRate(long views, long cta) {
        if (views <= 0) return null;
        return Math.round(cta * 1000.0 / views) / 10.0;
    }

    private static String normalizeSource(String raw) {
        if (raw == null || raw.isBlank()) return "direct";
        String normalized = raw.trim().toLowerCase(Locale.ROOT);
        return KNOWN_SOURCES.contains(normalized) ? normalized : OTHER_SOURCE;
    }
}
