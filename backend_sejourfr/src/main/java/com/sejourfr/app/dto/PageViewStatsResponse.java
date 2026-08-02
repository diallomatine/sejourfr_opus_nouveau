package com.sejourfr.app.dto;

import java.util.List;

/**
 * Audience d'une landing sur une fenêtre glissante, pour la console admin.
 *
 * @param path       page mesurée ("/reussir")
 * @param days       taille de la fenêtre en jours
 * @param views      vues totales sur la fenêtre
 * @param ctaClicks  clics sur le CTA principal sur la fenêtre
 * @param sources    détail par réseau de provenance, vues décroissantes
 * @param daily      série journalière, du plus ancien au plus récent
 */
public record PageViewStatsResponse(
        String path,
        int days,
        long views,
        long ctaClicks,
        List<SourceStat> sources,
        List<DailyStat> daily
) {
    /**
     * @param ctaRate part des vues ayant abouti à un clic CTA, en pourcentage.
     *                Null si aucune vue (une division par zéro n'est pas « 0 % »).
     */
    public record SourceStat(String source, long views, long ctaClicks, Double ctaRate) {}

    public record DailyStat(String day, long views, long ctaClicks) {}
}
