package com.sejourfr.app.entity;

import com.sejourfr.app.enums.SkillConstraintIcon;

/**
 * Une etiquette de contrainte d'un petit sujet : ce que le candidat doit
 * respecter dans sa maniere d'ecrire ou de parler, lisible d'un coup d'oeil
 * au-dessus de la zone de saisie.
 *
 * <p>Stockee en JSONB sur {@link SkillPrompt#getConstraintTags()} (1 a 3 par
 * sujet), a l'image de {@link AgentRoleCard} : un tableau d'objets plutot que
 * des colonnes, parce que le nombre d'etiquettes varie d'un sujet a l'autre et
 * qu'un editeur doit pouvoir en ajouter une sans migration.
 *
 * <p><b>Elle dit COMMENT produire, jamais COMBIEN.</b> Ni la longueur ni la
 * duree n'y ont leur place : les fronts les rendent depuis
 * {@code recommendedMinWords} / {@code recommendedMaxWords} /
 * {@code recommendedDurationSeconds}, deja en base. Les stocker deux fois,
 * c'est se garantir de les voir diverger.
 *
 * @param label texte tres court (1 a 3 mots) affiche dans la puce
 * @param icon  famille d'icone, prise dans une liste fermee — voir
 *              {@link SkillConstraintIcon}
 */
public record SkillConstraintTag(String label, SkillConstraintIcon icon) {
}
