package com.sejourfr.app.dto;

import java.math.BigDecimal;

/**
 * Dashboard de calibration du NIVEAU CECRL : écart entre le niveau brut du LLM
 * ({@code niveau_cecrl_ia}, jamais affiché) et le niveau calculé serveur
 * ({@code niveau_cecrl}, affiché). Permet de suivre la tendance de sous/sur-
 * estimation du LLM et de recalibrer les seuils.
 *
 * @param totalAvecNiveau    évaluations ayant les deux niveaux renseignés.
 * @param divergents         celles où LLM ≠ calculé (≥ 1 cran).
 * @param pourcentageDivergents ratio sur 100 (0-100).
 */
public record NiveauCalibrationStatsDto(
        long totalAvecNiveau,
        long divergents,
        BigDecimal pourcentageDivergents
) {
}
