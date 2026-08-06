package com.sejourfr.app.dto;

import java.util.List;

/**
 * Detail d'une competence : sa fiche et ses petits sujets, dans l'ordre
 * d'affichage. C'est l'ecran « niveau 4 » du parcours (une competence).
 */
public record SkillDetailDto(
        SkillDto skill,
        List<SkillPromptSummaryDto> prompts
) {
}
