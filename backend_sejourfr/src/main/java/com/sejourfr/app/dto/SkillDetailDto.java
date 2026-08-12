package com.sejourfr.app.dto;

import java.util.List;

/**
 * Detail d'une competence : sa fiche, ses petits sujets dans l'ordre
 * d'affichage, et sa <b>trajectoire</b>. C'est l'ecran « niveau 4 » du parcours
 * (une competence).
 *
 * <p>La trajectoire est servie ici plutot que sur une route dediee : l'ecran
 * l'affiche en meme temps que la fiche, un second aller-retour reseau n'aurait
 * apporte qu'une latence. Elle est <b>vide</b>, jamais nulle, tant que rien n'a
 * ete observe.
 */
public record SkillDetailDto(
        SkillDto skill,
        List<SkillPromptSummaryDto> prompts,
        /**
         * Les observations probantes de cette competence, <b>de la plus ancienne
         * a la plus recente</b> — le sens dans lequel une frise se lit. L'etat
         * agrege qu'elles produisent est sur {@link SkillDto#masteryState()}.
         */
        List<SkillObservationPointDto> trajectory
) {
}
