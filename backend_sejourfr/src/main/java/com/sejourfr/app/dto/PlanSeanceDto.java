package com.sejourfr.app.dto;

import java.util.List;

/**
 * <b>La seance du jour</b> : ce que le candidat fait maintenant, et rien de
 * plus.
 *
 * <p>C'est une <b>vue</b> du Plan, pas une seconde source de verite. Chaque item
 * reprend un exercice deja designe par les autorites existantes
 * ({@code RecommendedExerciseSelector}, {@code ReassessmentExerciseSelector},
 * {@code PlanMilestoneSelector}) : la seance n'en choisit aucun, elle decide
 * seulement lesquels tiennent dans la journee et dans quel ordre.
 *
 * <p>🛑 <b>Aucune date n'intervient nulle part.</b> « Aujourd'hui » est une
 * presentation ; la progression, elle, depend des actions du candidat. Une
 * competence entree dans la seance y reste tant que son objectif n'est pas
 * atteint, et cette stickiness est acquise <b>par construction</b> : les
 * priorites ne changent qu'a l'arrivee d'une nouvelle observation, donc a la
 * prochaine production. Rien ici ne lit l'horloge, rien n'est persiste, aucune
 * graine n'est tiree — un changement de jour ne peut donc pas faire oublier une
 * competence.
 *
 * <p><b>Une competence = un item</b>, meme quand elle demande plusieurs etapes :
 * c'est l'<b>action courante</b> qui change (petit sujet suivant, verification
 * en situation, nouvelle serie ciblee), jamais le nombre de lignes.
 *
 * @param items            au plus {@code display.todayMaxActions} (plan-config), dans
 *                         l'ordre d'execution ; jamais {@code null}, vide quand
 *                         le Plan n'a rien a proposer
 * @param estimatedMinutes somme <b>recalculee</b> des durees des items, jamais
 *                         un total ecrit quelque part ; {@code 0} sur une
 *                         seance vide
 */
public record PlanSeanceDto(
        List<PlanSeanceItemDto> items,
        int estimatedMinutes
) {

    public PlanSeanceDto {
        items = List.copyOf(items);
    }
}
