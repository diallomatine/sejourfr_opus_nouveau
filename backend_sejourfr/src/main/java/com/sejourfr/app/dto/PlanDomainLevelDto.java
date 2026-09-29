package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.TargetLevel;

import java.util.UUID;

/**
 * Un palier d'un domaine de <b>comprehension</b> : ou en est le candidat sur
 * {@code CO-A2}, {@code CO-B1}, {@code CO-B2} (ou leurs jumelles CE).
 *
 * <p>C'est l'etat de maitrise de la competence de ce palier, tel que
 * {@code SkillMasteryEngine} le calcule — <b>jamais un pourcentage</b> : le
 * score interne du moteur n'est expose a aucun front, et il n'a pas cesse de
 * l'etre ici.
 *
 * <p>{@code masteryState == null} veut dire « jamais observe » : on n'invente
 * pas un etat pour un palier que personne n'a mesure.
 *
 * @param niveau       {@code A2} | {@code B1} | {@code B2}
 * @param skillId      la competence du palier — le front ouvre sa serie ciblee
 * @param skillCode    {@code CO-B1}, {@code CE-A2}...
 * @param masteryState etat agrege, {@code null} si rien n'a ete observe
 * @param blocking     ce palier est le <b>premier</b> non consolide du domaine :
 *                     c'est lui qui empeche de compter les paliers superieurs
 *                     (regle de {@code ComprehensionLevelResolver}, jamais
 *                     recopiee ici)
 */
public record PlanDomainLevelDto(
        TargetLevel niveau,
        UUID skillId,
        String skillCode,
        SkillMasteryState masteryState,
        boolean blocking
) {}
