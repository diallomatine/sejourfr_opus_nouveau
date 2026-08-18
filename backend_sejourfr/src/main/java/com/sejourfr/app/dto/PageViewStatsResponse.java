package com.sejourfr.app.dto;

import java.util.List;
import java.util.Map;

/**
 * Audience d'une landing sur une fenêtre glissante, pour la console admin.
 *
 * @param path       page mesurée ("/reussir")
 * @param days       nombre de jours réellement couverts par la fenêtre appliquée
 * @param from       premier jour couvert, inclus (Europe/Paris, {@code yyyy-MM-dd})
 * @param to         dernier jour couvert, inclus
 * @param views      vues totales sur la fenêtre
 * @param ctaClicks  clics sur le CTA principal sur la fenêtre
 * @param sources    détail par réseau de provenance, vues décroissantes
 * @param daily      série journalière, du plus ancien au plus récent
 * @param events     compte brut par événement du funnel, sans identifiant
 */
public record PageViewStatsResponse(
        String path,
        int days,
        String from,
        String to,
        long views,
        long ctaClicks,
        List<SourceStat> sources,
        List<DailyStat> daily,
        Map<String, Long> events
) {
    /**
     * @param ctaRate part des vues ayant abouti à un clic CTA, en pourcentage.
     *                Null si aucune vue (une division par zéro n'est pas « 0 % »).
     */
    public record SourceStat(String source, long views, long ctaClicks, Double ctaRate) {}

    public record DailyStat(String day, long views, long ctaClicks) {}
}
