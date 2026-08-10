package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

/** Micro-exercice réellement disponible, recommandé par le Plan. */
public record PlanRecommendedExerciseDto(
        UUID skillPromptId,
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        int estimatedMinutes,
        /**
         * {@code true} quand ce candidat ne peut pas produire sur ce sujet : le
         * front affiche un cadenas sur l'exercice et renvoie vers le paiement.
         * L'exercice reste <b>désigné et visible</b> — savoir quoi travailler
         * est justement ce que le Plan apporte.
         */
        boolean locked
) {}
