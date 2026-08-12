package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillMasteryState;
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
         * travaille », distinct de {@link #description}. Il couvre les 15 sujets ;
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
         * Ou en est le candidat sur cette competence, tout son historique
         * confondu — <b>c'est ce que la carte affiche a la place de « 2/15
         * traites »</b>. Un nombre de sujets traites dit ce qu'il a fait ; cet
         * etat dit ce qu'il maitrise, ce qui est la vraie question.
         *
         * <p>Derive serveur a chaque lecture ({@code SkillMasteryEngine}),
         * jamais persiste, jamais recalcule par un front. {@code null} quand
         * aucune observation n'existe : on n'invente pas un etat pour une
         * competence que le serveur n'a jamais vue. Les compteurs ci-dessus
         * restent, ils servent ailleurs.
         */
        SkillMasteryState masteryState,
        /**
         * {@code true} quand ce candidat <b>ne peut pas produire</b> sur cette
         * compétence : les fronts affichent un cadenas et renvoient vers le
         * paiement. Toujours {@code false} pour un abonné TCF. Décidé par
         * {@code SkillAccessService}, jamais recalculé par un front.
         */
        boolean locked
) {
}
