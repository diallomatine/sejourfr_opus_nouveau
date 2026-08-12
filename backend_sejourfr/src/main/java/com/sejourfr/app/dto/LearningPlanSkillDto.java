package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

/**
 * Une compétence observée, avec sa progression réelle. Mêmes trois compteurs,
 * même sémantique et même calcul que {@link LearningPlanPriorityDto} et
 * {@link SkillDto}.
 */
public record LearningPlanSkillDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        LearningPlanSkillStatus status,
        Instant lastObservedAt,
        int promptCount,
        int attemptedCount,
        int validatedCount,
        /**
         * Etat de maitrise agrege, identique a
         * {@code SkillDto.masteryState} et issu du meme moteur — un candidat ne
         * doit pas lire « En consolidation » dans son Plan et « À renforcer »
         * dans le module Competences. Derive serveur, jamais persiste,
         * {@code null} sans observation.
         *
         * <p>A ne pas confondre avec {@link #status()}, qui est le verdict de la
         * <b>derniere production</b> sur cette competence.
         */
        SkillMasteryState masteryState,
        /**
         * {@code true} quand ce candidat ne peut pas produire sur cette
         * compétence. La compétence reste affichée avec son historique : seul
         * l'accès est verrouillé.
         */
        boolean locked
) {}
