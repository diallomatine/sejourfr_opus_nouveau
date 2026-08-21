package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSeanceDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.entity.Skill;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>La seance du jour</b>, assemblee a partir de ce que le Plan a deja decide.
 *
 * <p>Elle ne choisit <b>aucun</b> exercice : chaque priorite arrive avec le sien,
 * designe par les trois autorites uniques du depot
 * ({@link RecommendedExerciseSelector}, {@link ReassessmentExerciseSelector},
 * {@link PlanMilestoneSelector}). Ce composant ne fait que trois choses —
 * ordonner, borner, et <b>recalculer</b> le total de minutes.
 *
 * <h2>Pourquoi il n'y a ni table, ni colonne, ni graine</h2>
 * La regle produit dit qu'une competence entree dans « Aujourd'hui » n'en sort
 * pas parce que la date a change : elle y reste jusqu'a ce que son objectif soit
 * atteint. <b>Cette stickiness est acquise par construction</b>, elle n'a rien a
 * mecaniser :
 * <ul>
 *   <li>les priorites sortent de {@link LearningPlanPriorityResolver}, dont
 *       l'ordre ({@code PRIORITY} avant {@code TO_REINFORCE}, puis confiance,
 *       puis date d'observation) ne depend que de <b>l'historique observe</b> ;</li>
 *   <li>une competence n'en sort que lorsque son transfert est prouve
 *       ({@code SkillMastery.transferProven()}), c'est-a-dire lorsqu'elle est
 *       <b>reussie</b> — exactement le critere du brief ;</li>
 *   <li>la seance derive de ces priorites et ne lit <b>jamais</b> l'horloge :
 *       aucune methode de cette classe ne recoit de {@code Clock} ni de
 *       {@code LocalDate}, et les {@code Instant} qu'elle recopie sont des
 *       <b>faits d'historique</b> (« derniere activite le … »), jamais l'heure
 *       courante. Deux lectures a deux dates differentes, sans action du
 *       candidat, rendent la meme seance.</li>
 * </ul>
 * Persister des « items du jour » aurait au contraire cree une seconde source de
 * verite a reconcilier avec les priorites a chaque observation — le defaut que
 * le depot a deja paye sur le niveau TCF estime.
 *
 * <h2>Une competence = un item</h2>
 * {@code latestObservedBySkill} ne garde qu'une observation par competence, donc
 * deux priorites ne designent jamais la meme : la regle « 1 competence = 1 slot »
 * est heritee, pas ajoutee. Ce qui change quand une competence demande plusieurs
 * etapes, c'est son {@code exercise}, jamais le nombre de lignes.
 */
@Component
public class PlanSeanceBuilder {

    /**
     * Entrainements d'une seance. Trois, comme les priorites visibles : au-dela
     * la seance cesse d'etre une journee de travail et redevient une liste de
     * choses a faire, ce que le Plan existe justement pour eviter.
     */
    public static final int MAX_ITEMS = 3;

    /**
     * La seance, du jalon aux priorites.
     *
     * <p><b>Le jalon passe devant</b> quand il existe : c'est le moment ou le
     * Plan change son action principale (« vous avez consolide les competences
     * de ce palier, verifions vos progres dans les conditions du TCF »). Il
     * occupe un slot comme les autres — la seance reste bornee a
     * {@value #MAX_ITEMS}.
     *
     * <p>Une priorite <b>sans exercice</b> est ecartee : une competence dont
     * aucun sujet n'est publie n'offre rien a faire, et un item sans action
     * n'est pas un entrainement. Cas normal, jamais une erreur.
     *
     * @param priorities priorites <b>deja ordonnees</b>, exercice compris
     * @param skills     competences des priorites, indexees par identifiant :
     *                   elles portent le palier travaille, qui ne vit pas sur le
     *                   DTO de priorite
     * @param lastActivity derniere activite de chaque competence
     *                   ({@code LearningPlanPriorityResolver.lastActivityBySkill},
     *                   autorite unique) : un <b>fait</b> recopie tel quel sur
     *                   l'item, que les fronts comparent a leur journee courante
     *                   pour cocher ce qui a ete fait aujourd'hui. Ce n'est
     *                   <b>pas</b> une horloge : rien ici ne le compare a
     *                   maintenant, et une competence absente de la carte rend
     *                   simplement {@code null}
     * @param milestone  le jalon du parcours, ou {@code null} — le cas normal
     */
    public PlanSeanceDto build(
            List<LearningPlanPriorityDto> priorities,
            Map<UUID, Skill> skills,
            Map<UUID, Instant> lastActivity,
            PlanRecommendedExerciseDto milestone) {
        List<PlanSeanceItemDto> items = new ArrayList<>(MAX_ITEMS);
        if (milestone != null) items.add(jalon(milestone));
        for (LearningPlanPriorityDto priority : priorities) {
            if (items.size() >= MAX_ITEMS) break;
            if (priority.recommendedExercise() == null) continue;
            items.add(etape(priority, skills.get(priority.skillId()),
                    lastActivity.get(priority.skillId())));
        }
        int minutes = items.stream().mapToInt(item -> item.exercise().estimatedMinutes()).sum();
        return new PlanSeanceDto(items, minutes);
    }

    /**
     * Un jalon : l'examen blanc porte l'action, mais aucune competence — il ne
     * travaille pas un moyen precis, il verifie ce qui a ete travaille.
     */
    private static PlanSeanceItemDto jalon(PlanRecommendedExerciseDto exercise) {
        return new PlanSeanceItemDto(
                exercise, null, null, null, null, null, null,
                0, 0, 0, false, false, exercise.locked(), null);
    }

    /**
     * Une etape : les compteurs servis sont ceux de l'<b>etape</b> (5 sujets),
     * jamais ceux de la competence (15) — c'est ce couple que l'anneau de
     * progression affiche.
     */
    private static PlanSeanceItemDto etape(
            LearningPlanPriorityDto priority, Skill skill, Instant lastActivity) {
        return new PlanSeanceItemDto(
                priority.recommendedExercise(),
                priority.skillId(), priority.skillCode(), priority.title(), priority.section(),
                skill == null ? null : skill.getTargetLevel(),
                priority.masteryState(),
                priority.stepPromptCount(), priority.stepAttemptedCount(),
                priority.stepValidatedCount(), priority.stepCompleted(),
                priority.readyForReassessment(), priority.locked(), lastActivity);
    }
}
