package com.sejourfr.app.dto;

import java.util.List;
import java.util.Objects;

/**
 * Synthèse légère de la paire EE/EO, dérivée et bornée côté serveur.
 *
 * @param exempleCible avant / après de la production ÉCRITE, produit par un
 *                     second appel LLM best-effort. <b>{@code null} est un cas
 *                     normal</b> : bloc absent ⇒ les fronts ne rendent rien.
 */
public record DiagnosticResultDto(
        DiagnosticProductionResultDto written,
        DiagnosticProductionResultDto oral,
        List<String> strengths,
        List<DiagnosticSkillObservationDto> priorities,
        String mainPriorityExplanation,
        PlanRecommendedExerciseDto nextAction,
        DiagnosticExempleCibleDto exempleCible
) {
    public DiagnosticResultDto {
        // Critère d'acceptation du parcours : un résultat terminé donne
        // toujours une action immédiatement réalisable dans le catalogue.
        Objects.requireNonNull(nextAction, "nextAction");
    }
}
