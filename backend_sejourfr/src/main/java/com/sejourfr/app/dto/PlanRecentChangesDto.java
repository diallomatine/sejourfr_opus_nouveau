package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PlanRecentChangesWindow;

import java.time.Instant;
import java.util.List;

/**
 * <b>Ce qui a change recemment</b> dans le Plan de ce candidat.
 *
 * <p>🛑 <b>Son absence est le cas NORMAL</b> : quand rien n'a bouge, le bloc vaut
 * {@code null} et l'ecran n'affiche rien. Aucune ligne n'est jamais fabriquee
 * pour remplir, aucun message generique n'existe cote serveur — tout ce qui est
 * servi ici est une transition reellement mesuree par le moteur de maitrise, ou
 * la priorite n&deg;1 reellement designee dans la fenetre.
 *
 * <h2>Ne pas confondre avec {@code PlanChangeDto}</h2>
 * Les deux repondent a deux questions differentes et ne se croisent qu'en un
 * point, volontairement :
 * <table>
 *   <caption>Deux blocs, deux questions</caption>
 *   <tr><th></th><th>{@code PlanChangeDto}</th><th>{@code PlanRecentChangesDto}</th></tr>
 *   <tr><td>question</td><td>qu'a change <b>cette soumission</b> ?</td>
 *       <td>qu'est-ce qui a bouge <b>recemment</b> ?</td></tr>
 *   <tr><td>ecran</td><td>le detail d'une production</td><td>le Plan</td></tr>
 *   <tr><td>grain</td><td>le <b>verdict d'une observation</b>
 *       ({@code LearningPlanSkillStatus.SOLID} contextuel)</td>
 *       <td>l'<b>etat agrege</b> de la competence ({@code SkillMasteryState})</td></tr>
 * </table>
 * Ils ne peuvent pas se contredire parce qu'ils ne parlent pas de la meme
 * grandeur : une production peut tres bien constater {@code SOLID} sur une
 * competence sans que son etat agrege bascule (le moteur pese l'historique
 * entier), et l'inverse est impossible. Le seul fait qu'ils affirment tous deux
 * — <b>quelle est la priorite n&deg;1</b> — est lu chez la meme autorite,
 * {@code LearningPlanPriorityResolver}, jamais recalcule de part et d'autre :
 * c'est ce qui garantit qu'ils ne designent jamais deux etapes differentes.
 *
 * @param window      la fenetre <b>reellement appliquee</b>, choisie par le
 *                    serveur : l'ecran affiche la periode d'apres le serveur,
 *                    jamais d'apres ce que le client croit avoir demande
 * @param since       borne basse de cette fenetre
 * @param transitions transitions mesurees, de la plus recente a la plus
 *                    ancienne, bornees ; jamais {@code null}, eventuellement
 *                    vide quand seule une nouvelle priorite a ete designee
 * @param newPriority la competence devenue priorite n&deg;1 <b>dans cette
 *                    fenetre</b>, ou {@code null} — cas frequent, l'etape n&deg;1
 *                    ne change pas a chaque production
 */
public record PlanRecentChangesDto(
        PlanRecentChangesWindow window,
        Instant since,
        List<PlanMasteryTransitionDto> transitions,
        PlanSkillRefDto newPriority
) {

    public PlanRecentChangesDto {
        transitions = List.copyOf(transitions);
    }
}
