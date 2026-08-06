package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.time.Instant;
import java.util.UUID;

/**
 * Le petit sujet complet, pour l'ecran de production (« niveau 5 » du parcours).
 *
 * <p><b>Ne contient JAMAIS les references</b> : elles ont leur propre route,
 * gardee cote serveur, et ne sont revelees qu'apres la production. Les inclure
 * ici les rendrait lisibles avant l'exercice et le transformerait en recopie.
 *
 * <p>En revanche il porte {@link #skillPromptCount}, {@link #skillDescription}
 * et {@link #skillGeneralCriterion} : sans eux, l'ecran de production devait
 * appeler {@code GET /api/skills/{skillId}} EN PLUS, uniquement pour afficher le
 * fil d'Ariane « Sujet i/5 » et l'encart « Pourquoi cet exercice ? » — un
 * aller-retour reseau pour deux chaines de caracteres.
 */
public record SkillPromptDto(
        UUID id,
        UUID skillId,
        String skillCode,
        String skillTitle,
        /**
         * Nombre de sujets ACTIFS de la competence : le denominateur du fil
         * d'Ariane « Sujet i/5 » (le numerateur est {@link #displayOrder}).
         */
        int skillPromptCount,
        /** {@code Skill.description} — encart « Pourquoi cet exercice ? ». */
        String skillDescription,
        /** {@code Skill.generalCriterion} — le critere general de la competence. */
        String skillGeneralCriterion,
        /**
         * Palier CECRL de la competence ({@code A1}..{@code B2}). La spec le
         * demande sur l'ecran d'un petit sujet ; sans lui ici, supprimer le
         * second appel a {@code GET /api/skills/{skillId}} l'aurait fait
         * disparaitre de l'ecran.
         */
        String skillTargetLevel,
        SkillSection section,
        SkillTaskCode taskCode,
        /** Libelle officiel de la tache, ex. « Écrire un message court ». */
        String taskTitle,
        String code,
        String title,
        String context,
        String instruction,
        /** LE critere evalue — affiche AVANT la production. */
        String uniqueCriterion,
        Integer recommendedMinWords,
        Integer recommendedMaxWords,
        Integer recommendedDurationSeconds,
        SkillDifficulty difficultyLevel,
        short displayOrder,
        SkillPromptStatus status,
        int attemptCount,
        Instant lastAttemptAt,
        /** Derniere production du candidat, pour l'action « Reprendre ma reponse ». */
        UUID lastAttemptId,
        /**
         * Premier sujet encore {@code TODO} de la MEME competence, sujet courant
         * exclu. {@code null} quand il n'en reste aucun — le bouton « Sujet
         * suivant a travailler » se desactive alors, sans jamais bloquer la
         * navigation.
         */
        UUID nextPromptId
) {
}
