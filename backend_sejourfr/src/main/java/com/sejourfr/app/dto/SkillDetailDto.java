package com.sejourfr.app.dto;

import java.util.List;

/**
 * Detail d'une competence : sa fiche et ses petits sujets, dans l'ordre
 * d'affichage. C'est l'ecran « niveau 4 » du parcours (une competence).
 *
 * <p>⚠️ La <b>trajectoire</b> (la frise des observations) a ete retiree le
 * 2026-08-16 : la section « Ton parcours sur cette competence » n'apportait
 * rien au candidat, et la servir coutait une requete a chaque ouverture d'une
 * competence. Ne pas la reintroduire sans un ecran qui la lise vraiment.
 */
public record SkillDetailDto(
        SkillDto skill,
        List<SkillPromptSummaryDto> prompts
) {
}
