package com.sejourfr.app.dto;

import java.util.List;
import java.util.Objects;

/** Synthèse légère de la paire EE/EO, dérivée et bornée côté serveur. */
public record DiagnosticResultDto(
        DiagnosticProductionResultDto written,
        DiagnosticProductionResultDto oral,
        List<String> strengths,
        List<DiagnosticSkillObservationDto> priorities,
        String mainPriorityExplanation,
        PlanRecommendedExerciseDto nextAction
) {
    public DiagnosticResultDto {
        // Critère d'acceptation du parcours : un résultat terminé donne
        // toujours une action immédiatement réalisable dans le catalogue.
        Objects.requireNonNull(nextAction, "nextAction");
    }
}
