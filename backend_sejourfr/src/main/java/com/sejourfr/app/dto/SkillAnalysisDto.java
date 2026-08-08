package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillCriterionStatus;

/**
 * Retour de l'analyse ciblee, tel qu'il est affiche au candidat.
 *
 * <p><b>Cinq champs, et rien d'autre</b> : ni note sur 20, ni niveau CECRL. Un
 * micro-exercice de quelques phrases ne permet ni l'un ni l'autre, et le
 * tool-schema de sortie ne prevoit aucun champ pour les accueillir.
 * {@code improvedVersion} reformule l'idee DU CANDIDAT — ce n'est pas un modele
 * de substitution.
 */
public record SkillAnalysisDto(
        SkillCriterionStatus status,
        String verdict,
        String successPoint,
        String improvementPriority,
        String improvedVersion
) {
}
