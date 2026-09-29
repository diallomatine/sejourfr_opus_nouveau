package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.time.Instant;

/**
 * Niveau estimé par l'analyse du <b>diagnostic initial</b> pour une épreuve de
 * production (EE ou EO).
 *
 * <p>Projection interne : aucun endpoint ne la sert telle quelle. Elle n'existe
 * que parce que le diagnostic est bifurqué avant {@code ai_evaluations}
 * ({@code production_submissions.is_diagnostic}) — son verdict vit dans
 * {@code diagnostic_production_analyses.level_estimate} et devait donc être lu
 * séparément par {@code TcfProfileService}.
 *
 * @param mesureA quand l'analyse a été produite
 *                ({@code diagnostic_production_analyses.analyzed_at}, NOT
 *                NULL). 🛑 <b>Elle est portée par la MÊME projection</b> que le
 *                niveau, et non par une seconde requête : les deux lecteurs —
 *                le profil de niveau et l'historique d'une épreuve — doivent
 *                retenir exactement les mêmes lignes. Une seconde requête
 *                finirait par en retenir d'autres.
 *                {@code TcfProfileService} l'ignore, et c'est normal : il
 *                cherche un maximum, pas une chronologie
 */
public record DiagnosticEpreuveLevel(
        EpreuveType epreuve,
        NiveauCecrl niveau,
        Instant mesureA
) {
}
