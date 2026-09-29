package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Une <b>étape franchie</b> du parcours : une compétence dont le transfert est
 * prouvé, donc qui n'est plus une priorité.
 *
 * <p><b>Pourquoi elle est servie.</b> Jusqu'ici une compétence réussie sortait
 * simplement des priorités : son étape <b>disparaissait</b> du Plan et le
 * candidat perdait la trace de ce qu'il avait franchi. Elles sont désormais
 * publiées pour être affichées <b>avant</b> l'étape courante et les suivantes,
 * dans le même parcours numéroté, et <b>cochées</b>.
 *
 * <p>Elle porte exactement de quoi rendre la même carte qu'une
 * {@link LearningPlanPriorityDto} : identité de la compétence et compteurs
 * d'<b>étape</b> (les {@code LearningPlanStep.PROMPTS_PAR_ETAPE} premiers sujets
 * actifs). Elle ne porte <b>ni exercice recommandé ni cadenas</b> : il n'y a
 * plus rien à y faire, et une étape franchie n'est pas une porte commerciale.
 *
 * <p>Dérivée serveur, jamais persistée, jamais recalculée par un front — même
 * philosophie que {@code SkillStatusResolver} et {@code SituationDansNiveau}.
 */
public record LearningPlanCompletedStepDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        /**
         * Date de la dernière observation probante de la compétence : c'est ce
         * qui ordonne les étapes franchies entre elles, et ce qu'un front peut
         * afficher comme « franchie le … ».
         */
        Instant observedAt,
        /** Sujets de l'étape : au plus 5, moins si la compétence en publie moins. */
        int stepPromptCount,
        /** Sujets de l'étape déjà traités. Une étape franchie n'est pas forcément à 5/5. */
        int stepAttemptedCount,
        /** Sujets de l'étape dont le critère a été validé. Toujours ≤ {@link #stepAttemptedCount()}. */
        int stepValidatedCount,
        /**
         * Le périmètre de l'étape, dans l'ordre. Jamais {@code null} ; vide si la
         * compétence n'a aucun sujet actif. Même sémantique que
         * {@link LearningPlanPriorityDto#stepPromptIds()} — un front qui rouvre
         * l'étape pour se relire reste sur les mêmes sujets.
         */
        List<UUID> stepPromptIds,
        /**
         * État de maîtrise agrégé, du même moteur que
         * {@link LearningPlanPriorityDto#masteryState()}. <b>Pas forcément
         * {@code SOLID}</b> : une preuve de transfert récente suffit à franchir
         * l'étape, alors que {@code SOLID} exige en plus un score agrégé. Les
         * deux informations sont distinctes et toutes deux honnêtes.
         */
        SkillMasteryState masteryState
) {}
