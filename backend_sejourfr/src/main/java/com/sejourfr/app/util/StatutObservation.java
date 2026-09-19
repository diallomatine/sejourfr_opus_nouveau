package com.sejourfr.app.util;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.enums.LearningPlanSkillStatus;

/**
 * <b>Le statut d'une observation, a partir de son ratio de bonnes reponses.</b>
 *
 * <p>🛑 <b>Extrait a sa 2e occurrence</b> (2026-09-19). La regle vivait dans
 * {@code ComprehensionObservationService} ; le pendant <b>civique</b> en avait
 * besoin a l'identique, et deux copies d'un seuil finissent toujours par
 * diverger — c'est le defaut le plus cher de ce depot.
 *
 * <p>🛑 <b>Les seuils sont LUS dans la configuration</b>
 * ({@code learning-plan.comprehension}), jamais ecrits ici. Recalibrer relit
 * alors tout l'historique au prochain appel, sans migration.
 *
 * <p>⚠️ <b>Cette classe ne decide pas si une observation est PROBANTE</b> —
 * c'est {@code min-questions}, et l'appelant le tranche avant : une mesure trop
 * courte est {@code NOT_OBSERVED}, et son ratio n'est jamais consulte.
 * <b>{@code null} = inconnu, jamais mauvais.</b>
 */
public final class StatutObservation {

    private StatutObservation() {}

    /**
     * @param ratio  bonnes / posees, sur les questions <b>reellement
     *               repondues</b>.
     * @param config les seuils de {@code learning-plan.comprehension}.
     */
    public static LearningPlanSkillStatus selonRatio(
            double ratio, LearningPlanProperties.Comprehension config) {
        if (ratio >= config.getSolidRatio()) return LearningPlanSkillStatus.SOLID;
        if (ratio >= config.getReinforceRatio()) return LearningPlanSkillStatus.TO_REINFORCE;
        return LearningPlanSkillStatus.PRIORITY;
    }
}
