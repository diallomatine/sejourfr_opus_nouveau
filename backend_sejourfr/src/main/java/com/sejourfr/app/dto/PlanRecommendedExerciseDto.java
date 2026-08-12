package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

/**
 * L'exercice reellement disponible que le Plan recommande sur une competence.
 *
 * <p><b>Deux natures, un seul champ</b> ({@link #kind}) : un micro-exercice du
 * module Competences, ou une <b>verification en situation</b> sur une vraie
 * tache TCF. Les deux ne menent pas au meme ecran, d'ou les deux identifiants
 * mutuellement exclusifs — {@link #skillPromptId()} pour
 * {@link PlanExerciseKind#MICRO_TRAINING}, {@link #productionTaskId()} et
 * {@link #tacheNumero()} pour {@link PlanExerciseKind#REASSESSMENT}. Aucun front
 * ne doit deviner la nature d'un {@code null} : il lit {@code kind}.
 *
 * <p>Les deux formes se construisent par {@link #microTraining} et
 * {@link #reassessment}, jamais par le constructeur canonique : c'est ce qui
 * garantit qu'un identifiant hors sujet ne peut pas s'y glisser.
 */
public record PlanRecommendedExerciseDto(
        PlanExerciseKind kind,
        /** Micro-exercice uniquement ; {@code null} sur une verification. */
        UUID skillPromptId,
        /** Verification uniquement ; {@code null} sur un micro-exercice. */
        UUID productionTaskId,
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        /**
         * Numero de tache (1, 2 ou 3) du sujet de production — verification
         * uniquement, {@code null} sur un micro-exercice. Avec {@link #section()},
         * c'est ce qui permet au front d'ouvrir le bon ecran de production.
         */
        Short tacheNumero,
        int estimatedMinutes,
        /**
         * {@code true} quand ce candidat ne peut pas produire sur ce sujet : le
         * front affiche un cadenas sur l'exercice et renvoie vers le paiement.
         * L'exercice reste <b>designe et visible</b> — savoir quoi travailler
         * est justement ce que le Plan apporte.
         */
        boolean locked
) {

    /** Un petit sujet du module Competences. */
    public static PlanRecommendedExerciseDto microTraining(
            UUID skillPromptId, UUID skillId, String skillCode, String title,
            SkillSection section, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.MICRO_TRAINING, skillPromptId, null, skillId, skillCode,
                title, section, null, estimatedMinutes, locked);
    }

    /** Une vraie tache TCF, pour verifier le transfert en situation. */
    public static PlanRecommendedExerciseDto reassessment(
            UUID productionTaskId, UUID skillId, String skillCode, String title,
            SkillSection section, Short tacheNumero, int estimatedMinutes, boolean locked) {
        return new PlanRecommendedExerciseDto(
                PlanExerciseKind.REASSESSMENT, null, productionTaskId, skillId, skillCode,
                title, section, tacheNumero, estimatedMinutes, locked);
    }
}
