package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Bilan serveur d'une session production EE/EO (un attempt + ses soumissions).
 *
 * <p>{@code niveauGlobal} n'est renseigné que pour une <b>session d'examen
 * blanc</b> ({@code exam = true}) dont les {@code expectedCount} tâches sont
 * évaluées : moyenne pondérée des compétences des tâches (cf.
 * {@code ProductionBilanService}), plafonnée B2. Jamais de niveau en
 * entraînement libre — seule la note /20 et le feedback y sont restitués.
 */
public record ProductionBilanResponse(
        UUID attemptId,
        EpreuveType epreuve,
        boolean exam,
        int evaluatedCount,
        int expectedCount,
        BigDecimal moyenneSur20,
        NiveauCecrl niveauGlobal
) {
}
