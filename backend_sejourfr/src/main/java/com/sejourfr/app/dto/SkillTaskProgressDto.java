package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

/**
 * Resume d'une tache TCF pour l'ecran « choix de la tache ». Trois entrees par
 * epreuve, toujours renvoyees meme si aucune competence n'est encore publiee :
 * une tache vide s'affiche a zero, elle ne disparait pas.
 *
 * <p>{@code title} et {@code targetLevel} viennent de l'enum
 * {@link SkillTaskCode} — les 6 taches sont un referentiel officiel fige, pas du
 * contenu editable.
 */
public record SkillTaskProgressDto(
        SkillTaskCode taskCode,
        SkillSection section,
        String title,
        String targetLevel,
        /** Competences actives de la tache (8 une fois le contenu publie). */
        int skillCount,
        /** Petits sujets actifs de la tache (40 une fois le contenu publie). */
        int promptCount,
        /** Sujets sur lesquels le candidat a produit au moins une fois. */
        int attemptedCount,
        int validatedCount,
        int toReinforceCount
) {
}
