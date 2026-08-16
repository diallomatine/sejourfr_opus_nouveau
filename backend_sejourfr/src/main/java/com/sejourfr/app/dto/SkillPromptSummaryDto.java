package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillPromptStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Un petit sujet tel qu'il apparait dans la liste d'une competence : de quoi
 * afficher une carte (titre, critere, statut, tentatives) sans charger le sujet
 * complet. Ne porte ni le contexte, ni la consigne, ni les references.
 */
public record SkillPromptSummaryDto(
        UUID id,
        /** Code editorial stable, ex. {@code "EE1-C1-S1"}. */
        String code,
        String title,
        /** LE critere evalue — affiche avant la production, jamais cache. */
        String uniqueCriterion,
        SkillDifficulty difficultyLevel,
        short displayOrder,
        /** EE uniquement : conseil de longueur, jamais bloquant. */
        Integer recommendedMinWords,
        Integer recommendedMaxWords,
        /** EO uniquement : conseil de duree, jamais bloquant. */
        Integer recommendedDurationSeconds,
        /** Derive serveur de la derniere tentative — aucun front ne le recalcule. */
        SkillPromptStatus status,
        int attemptCount,
        Instant lastAttemptAt,
        /**
         * Derniere production du candidat sur ce sujet, ou {@code null} s'il n'y
         * en a aucune. Meme source que {@code SkillPromptDto.lastAttemptId} : la
         * tentative deja chargee pour deriver {@link #status} — <b>aucune requete
         * de plus</b>, alors qu'une liste de competence en compte 15 et qu'un
         * ecran en charge 24.
         *
         * <p>Sans lui, la liste ne pouvait pointer que vers l'ecran de
         * production : le candidat n'avait aucun moyen de relire le rapport
         * qu'il venait de payer avec une de ses analyses. Il peut valoir
         * {@code null} sur un sujet pourtant marque traite (ligne heritee) — les
         * fronts retombent alors sur l'entree directe en production, jamais sur
         * un bouton mort.
         */
        UUID lastAttemptId,
        /**
         * {@code true} quand ce candidat <b>ne peut pas produire</b> sur ce
         * sujet. C'est ici que se voit la règle « seuls les 2 premiers sujets
         * d'une compétence ouverte le sont » : sans ce champ, le candidat ne
         * découvrirait le verrou qu'en ouvrant le sujet. Toujours {@code false}
         * pour un abonné TCF ; décidé par {@code SkillAccessService}, jamais
         * recalculé par un front.
         */
        boolean locked
) {
}
