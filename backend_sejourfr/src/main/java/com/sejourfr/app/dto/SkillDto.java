package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.util.UUID;

/**
 * Une micro-competence avec la progression du candidat courant. Les compteurs
 * portent sur les sujets ACTIFS de la competence : desactiver un sujet le
 * retire du denominateur, jamais de l'historique du candidat.
 */
public record SkillDto(
        UUID id,
        SkillSection section,
        SkillTaskCode taskCode,
        /** Code editorial stable, ex. {@code "EE1-C1"}. */
        String code,
        String title,
        /** Courte explication : sert d'encart « Pourquoi cet exercice ? » cote fronts. */
        String description,
        /**
         * Le critere GENERAL travaille par la competence — encart « Critere
         * travaille », distinct de {@link #description}. Il couvre les 5 sujets ;
         * {@code SkillPromptDto.uniqueCriterion} n'en couvre qu'un.
         */
        String generalCriterion,
        String targetLevel,
        short displayOrder,
        int promptCount,
        int attemptedCount,
        int validatedCount,
        int toReinforceCount,
        /**
         * {@code true} quand ce candidat <b>ne peut pas produire</b> sur cette
         * compétence : les fronts affichent un cadenas et renvoient vers le
         * paiement. Toujours {@code false} pour un abonné TCF. Décidé par
         * {@code SkillAccessService}, jamais recalculé par un front.
         */
        boolean locked
) {
}
