package com.sejourfr.app.dto;

import java.math.BigDecimal;

/**
 * Dashboard de calibration (cf. spec section 3.2 et 8).
 * <ul>
 *   <li>{@code totalNotes} : nombre total de notes humaines enregistrees.</li>
 *   <li>{@code ecartMoyen} : moyenne de {@code note_humaine - note_ia}.</li>
 *   <li>{@code ecartTypeAbsolu} : ecart-type de la valeur absolue des ecarts.</li>
 *   <li>{@code ecartsHorsCible} : nombre de notes avec |ecart| &gt; seuil (3 pts par defaut).</li>
 *   <li>{@code pourcentageHorsCible} : ratio sur 100 (0-100).</li>
 *   <li>{@code calibre} : true si {@code ecartMoyenAbsolu &lt; 1.5} et {@code pourcentageHorsCible &lt; 5}.</li>
 * </ul>
 */
public record CalibrationStatsDto(
        long totalNotes,
        BigDecimal ecartMoyen,
        BigDecimal ecartMoyenAbsolu,
        BigDecimal ecartTypeAbsolu,
        long ecartsHorsCible,
        BigDecimal pourcentageHorsCible,
        BigDecimal seuilHorsCible,
        boolean calibre
) {
}
