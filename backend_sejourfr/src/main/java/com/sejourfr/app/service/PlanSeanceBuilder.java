package com.sejourfr.app.service;

import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSeanceDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.service.plan.PlanConfig;
import lombok.RequiredArgsConstructor;
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
 * designe par les autorites uniques du depot
 * ({@link RecommendedExerciseSelector}, {@link ReassessmentExerciseSelector},
 * {@link PlanMilestoneSelector}, {@link PlanAcquisitionSelector}), et la mesure
 * manquante par {@link PlanDomainAssessmentResolver}. Ce composant ne fait que
 * trois choses — ordonner, borner, et <b>recalculer</b> le total de minutes.
 *
 * <h2>L'ordre de choix des actions</h2>
 * <ol>
 *   <li><b>l'evaluation manquante indispensable</b> : le candidat a produit sur
 *       ce domaine et le correcteur n'a rien pu observer. Tant qu'on ne l'a pas
 *       mesure, tout le reste travaille a l'aveugle ;</li>
 *   <li><b>les competences reellement fragiles</b>, puis celles <b>pretes a etre
 *       verifiees</b> — dans l'ordre que {@link LearningPlanPriorityResolver} a
 *       deja decide, qui n'est pas recalcule ici ;</li>
 *   <li><b>les competences du palier a acquerir</b>, qui arrivent a la suite des
 *       priorites ;</li>
 *   <li><b>le jalon</b> en dernier. Il ouvrait la seance jusqu'au 2026-08-21 ;
 *       il passe derriere parce qu'un examen blanc de 30 a 60 minutes n'a rien a
 *       prouver tant qu'une mesure manque ou qu'une fragilite bloque — et parce
 *       qu'a trois slots, le mettre en tete chassait le vrai travail de la
 *       journee.</li>
 * </ol>
 *
 * <h2>🛑 Le plafond de la seance est un plafond, jamais un quota</h2>
 * Rien n'est fabrique pour remplir l'ecran. Une competence <b>solide</b> ou
 * <b>non observee hors du palier vise</b> ne devient jamais une action : si le
 * Plan n'a que deux choses vraies a proposer, il en propose deux. C'est aux
 * autorites en amont de ne rendre que du vrai ; ce composant ne fait que couper
 * ce qui depasse.
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
 *   <li>les competences <b>a acquerir</b> sortent du referentiel publie et de
 *       l'absence d'historique : elles ne bougent pas davantage avec le
 *       calendrier ;</li>
 *   <li>la seance derive de tout cela et ne lit <b>jamais</b> l'horloge :
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
 * deux priorites ne designent jamais la meme ; et une competence a acquerir est
 * par definition <b>absente de l'historique</b>, donc absente des priorites
 * observees. La regle « 1 competence = 1 slot » est heritee, pas ajoutee. Ce qui
 * change quand une competence demande plusieurs etapes, c'est son
 * {@code exercise}, jamais le nombre de lignes.
 */
@Component
@RequiredArgsConstructor
public class PlanSeanceBuilder {

    /**
     * Entrainements d'une seance — {@code display.todayMaxActions} de
     * {@code plan-config-vN.json}, jamais une constante Java.
     *
     * <p>Trois aujourd'hui : deux ne suffisaient plus des lors que le Plan sait
     * enseigner et pas seulement reparer. Au-dela de trois, la seance cesse
     * d'etre une journee de travail et redevient une liste de choses a faire, ce
     * que le Plan existe justement pour eviter. <b>Ce n'est pas un quota</b> :
     * il n'est jamais atteint par du remplissage.
     *
     * <p>La <b>composition</b> de cette fenetre — au plus
     * {@code display.todayMaxSecondaryDomainActions} action(s) de domaine
     * secondaire — est deja appliquee par {@link PlanActionRanker} sur le pool
     * classe. Ce composant n'a donc rien a departager : il coupe.
     */
    private final PlanConfig config;

    public int maxItems() {
        return config.display().todayMaxActions();
    }

    /**
     * La seance, de la mesure manquante au jalon.
     *
     * <p>Une priorite <b>sans exercice</b> est ecartee : une competence dont
     * aucun sujet n'est publie n'offre rien a faire, et un item sans action
     * n'est pas un entrainement. Cas normal, jamais une erreur.
     *
     * @param assessment   la mesure indispensable, ou {@code null} — le cas
     *                     normal. Elle passe <b>en tete</b> : tant qu'un domaine
     *                     travaille n'a pas pu etre observe, les exercices qui
     *                     suivent avancent a l'aveugle
     * @param priorities   priorites <b>deja ordonnees</b>, exercice compris :
     *                     fragilites puis competences a acquerir
     * @param skills       competences des priorites, indexees par identifiant :
     *                     elles portent le palier travaille, qui ne vit pas sur
     *                     le DTO de priorite
     * @param lastActivity derniere activite de chaque competence
     *                     ({@code LearningPlanPriorityResolver.lastActivityBySkill},
     *                     autorite unique) : un <b>fait</b> recopie tel quel sur
     *                     l'item, que les fronts comparent a leur journee
     *                     courante pour cocher ce qui a ete fait aujourd'hui. Ce
     *                     n'est <b>pas</b> une horloge : rien ici ne le compare a
     *                     maintenant, et une competence absente de la carte rend
     *                     simplement {@code null} — ce qui est le cas de toute
     *                     competence a acquerir
     * @param milestone    le jalon du parcours, ou {@code null} — le cas normal
     */
    public PlanSeanceDto build(
            PlanDomainAssessmentDto assessment,
            List<LearningPlanPriorityDto> priorities,
            Map<UUID, Skill> skills,
            Map<UUID, Instant> lastActivity,
            PlanRecommendedExerciseDto milestone) {
        int maxItems = maxItems();
        List<PlanSeanceItemDto> items = new ArrayList<>(maxItems);
        if (assessment != null) items.add(mesure(assessment));
        for (LearningPlanPriorityDto priority : priorities) {
            if (items.size() >= maxItems) break;
            if (priority.recommendedExercise() == null) continue;
            items.add(etape(priority, skills.get(priority.skillId()),
                    lastActivity.get(priority.skillId())));
        }
        if (milestone != null && items.size() < maxItems) items.add(jalon(milestone));
        int minutes = items.stream().mapToInt(PlanSeanceBuilder::minutes).sum();
        return new PlanSeanceDto(items, minutes);
    }

    /**
     * Une <b>mesure</b>, pas un entrainement : le seul item qui porte un
     * {@code assessment} au lieu d'un {@code exercise}, et aucune competence —
     * c'est une epreuve entiere qu'on vient observer.
     */
    private static PlanSeanceItemDto mesure(PlanDomainAssessmentDto assessment) {
        return new PlanSeanceItemDto(
                PlanActionNature.A_EVALUER, null, assessment,
                null, null, null, null, null, null,
                0, 0, 0, false, false, false, null);
    }

    /**
     * Un jalon : l'examen blanc porte l'action, mais aucune competence — il ne
     * travaille pas un moyen precis, il verifie ce qui a ete travaille.
     */
    private static PlanSeanceItemDto jalon(PlanRecommendedExerciseDto exercise) {
        return new PlanSeanceItemDto(
                PlanActionNature.A_VERIFIER, exercise, null,
                null, null, null, null, null, null,
                0, 0, 0, false, false, exercise.locked(), null);
    }

    /**
     * Une etape : les compteurs servis sont ceux de l'<b>etape</b> (5 sujets),
     * jamais ceux de la competence (15) — c'est ce couple que l'anneau de
     * progression affiche. Sur une competence <b>a acquerir</b> le nombre traite
     * vaut 0, ce qui est exact : rien n'a encore ete fait.
     */
    private static PlanSeanceItemDto etape(
            LearningPlanPriorityDto priority, Skill skill, Instant lastActivity) {
        return new PlanSeanceItemDto(
                priority.nature(), priority.recommendedExercise(), null,
                priority.skillId(), priority.skillCode(), priority.title(), priority.section(),
                skill == null ? null : skill.getTargetLevel(),
                priority.masteryState(),
                priority.stepPromptCount(), priority.stepAttemptedCount(),
                priority.stepValidatedCount(), priority.stepCompleted(),
                priority.readyForReassessment(), priority.locked(), lastActivity);
    }

    /**
     * Les minutes d'un item : celles de son exercice, ou celles de sa mesure. Une
     * mesure sans duree (le diagnostic, une production — rien n'y est chronometre
     * par epreuve) compte pour zero plutot que pour un chiffre invente.
     */
    private static int minutes(PlanSeanceItemDto item) {
        if (item.exercise() != null) return item.exercise().estimatedMinutes();
        if (item.assessment() == null || item.assessment().estimatedMinutes() == null) return 0;
        return item.assessment().estimatedMinutes();
    }
}
