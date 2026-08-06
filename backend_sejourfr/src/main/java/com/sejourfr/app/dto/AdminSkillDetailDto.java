package com.sejourfr.app.dto;

import java.util.List;

/**
 * Ecran de detail d'une competence dans la console : la competence et tous ses
 * sujets, <b>desactives compris</b>, dans l'ordre d'affichage.
 *
 * <p>Chaque sujet arrive complet (references et compteur de tentatives) : c'est
 * ce qui permet a la liste d'afficher un badge « 3/3 » ou « A completer » sans
 * une requete par ligne.
 */
public record AdminSkillDetailDto(
        AdminSkillDto skill,
        List<AdminSkillPromptDto> prompts
) {
}
