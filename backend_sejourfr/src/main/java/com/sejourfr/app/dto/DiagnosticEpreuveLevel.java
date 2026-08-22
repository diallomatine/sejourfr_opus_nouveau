package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

/**
 * Niveau estimé par l'analyse du <b>diagnostic initial</b> pour une épreuve de
 * production (EE ou EO).
 *
 * <p>Projection interne : aucun endpoint ne la sert. Elle n'existe que parce que
 * le diagnostic est bifurqué avant {@code ai_evaluations}
 * ({@code production_submissions.is_diagnostic}) — son verdict vit dans
 * {@code diagnostic_production_analyses.level_estimate} et devait donc être lu
 * séparément par {@code TcfProfileService}.
 */
public record DiagnosticEpreuveLevel(EpreuveType epreuve, NiveauCecrl niveau) {
}
