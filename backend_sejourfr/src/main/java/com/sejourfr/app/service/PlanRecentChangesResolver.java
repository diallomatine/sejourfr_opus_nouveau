package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanMasteryTransitionDto;
import com.sejourfr.app.dto.PlanRecentChangesDto;
import com.sejourfr.app.dto.PlanSkillRefDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.PlanRecentChangesWindow;
import com.sejourfr.app.enums.SkillMasteryState;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * « Ce qui a change » — <b>mesure</b>, jamais redaction.
 *
 * <h2>Comment une transition se prouve</h2>
 * Le moteur de maitrise est une fonction pure de (historique, instant). Il
 * suffit donc de le faire tourner <b>deux fois</b> sur les memes lignes : une
 * fois sur l'historique arrete au debut de la fenetre et evalue a cet
 * instant-la, une fois sur l'historique complet evalue maintenant. La difference
 * des deux etats <b>est</b> le changement, avec la meme definition de la
 * maitrise que partout ailleurs — aucune regle n'est reecrite ici, aucun seuil
 * n'est duplique, et une recalibration dans {@code application.yaml} se
 * repercute d'elle-meme.
 *
 * <p><b>Zero requete.</b> L'historique est celui que {@link LearningPlanService}
 * a deja charge pour ordonner ses priorites, et l'etat courant celui qu'il a
 * deja calcule pour ses cartes. Tout se joue en memoire.
 *
 * <h2>Ce qui n'est jamais servi</h2>
 * <ul>
 *   <li><b>Une premiere mesure.</b> Un etat qui passe de « rien » a
 *       {@code PRIORITY} n'est pas un changement : c'est le diagnostic. Sans
 *       cette regle, le bloc serait plein de bruit le jour meme ou le candidat
 *       decouvre son niveau.</li>
 *   <li><b>Un changement que le temps seul a produit.</b> Une competence n'est
 *       examinee que si elle porte une observation <b>probante</b> dans la
 *       fenetre. Le score du moteur decroit avec la recence, donc une maitrise
 *       peut theoriquement s'eroder sans que le candidat ait rien fait : annoncer
 *       « Solide &rarr; En consolidation » a quelqu'un qui n'a rien fait serait
 *       une punition inventee, et le depot interdit par ailleurs qu'un jour qui
 *       passe change ce que le candidat a acquis.</li>
 *   <li><b>Un message d'encouragement.</b> Il n'y a aucun texte ici. Quand rien
 *       n'a bouge, le bloc est absent.</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class PlanRecentChangesResolver {

    /**
     * Transitions rendues, les plus recentes. Meme ordre de grandeur que les
     * etapes franchies republiees par le Plan : de quoi montrer que quelque
     * chose bouge, pas de quoi faire un journal — l'historique complet reste
     * l'affaire de l'ecran Progression.
     */
    public static final int MAX_TRANSITIONS = 5;

    private final SkillMasteryEngine engine;

    /**
     * Ce qui a change, sur la <b>plus courte</b> fenetre qui contienne quelque
     * chose de reel. Vide quand rien n'a bouge — le cas normal.
     *
     * @param observations   tout l'historique du candidat, deja charge
     * @param masteryNow     etats courants, deja calcules, indexes par competence
     * @param currentPriority observation qui porte la priorite n&deg;1, ou
     *                        {@code null}. Elle vient de
     *                        {@link LearningPlanPriorityResolver}, seule autorite
     *                        sur l'ordre des priorites : ce bloc ne le recalcule
     *                        pas, il le lit.
     * @param now            instant de reference
     */
    public Optional<PlanRecentChangesDto> resolve(
            List<LearningPlanObservation> observations,
            Map<UUID, SkillMasteryEngine.SkillMastery> masteryNow,
            LearningPlanObservation currentPriority,
            Instant now) {
        if (observations == null || observations.isEmpty()) return Optional.empty();
        Map<UUID, List<LearningPlanObservation>> bySkill = groupBySkill(observations);

        for (PlanRecentChangesWindow window : PlanRecentChangesWindow.values()) {
            Instant since = now.minus(Duration.ofDays(window.getDays()));
            List<PlanMasteryTransitionDto> transitions =
                    transitions(bySkill, masteryNow, since);
            PlanSkillRefDto nouvelle = nouvellePriorite(currentPriority, since);
            if (transitions.isEmpty() && nouvelle == null) continue;
            return Optional.of(new PlanRecentChangesDto(window, since, transitions, nouvelle));
        }
        return Optional.empty();
    }

    /**
     * Les competences dont l'etat agrege differe entre le debut de la fenetre et
     * maintenant, de la plus recemment observee a la plus ancienne.
     */
    private List<PlanMasteryTransitionDto> transitions(
            Map<UUID, List<LearningPlanObservation>> bySkill,
            Map<UUID, SkillMasteryEngine.SkillMastery> masteryNow,
            Instant since) {
        List<PlanMasteryTransitionDto> out = new ArrayList<>();
        for (Map.Entry<UUID, List<LearningPlanObservation>> entry : bySkill.entrySet()) {
            List<LearningPlanObservation> history = entry.getValue();
            LearningPlanObservation derniere = derniereProbanteDansLaFenetre(history, since);
            // Aucune preuve nouvelle : le temps seul ne fait pas un changement.
            if (derniere == null) continue;

            SkillMasteryEngine.SkillMastery apres = masteryNow.get(entry.getKey());
            if (apres == null || apres.state() == null) continue;

            List<LearningPlanObservation> avantLaFenetre = history.stream()
                    .filter(item -> item.getObservedAt() != null
                            && item.getObservedAt().isBefore(since))
                    .toList();
            SkillMasteryState avant = engine.evaluate(avantLaFenetre, since).state();
            // Une premiere mesure n'est pas une transition.
            if (avant == null || avant == apres.state()) continue;

            Skill skill = derniere.getSkill();
            out.add(new PlanMasteryTransitionDto(
                    skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                    avant, apres.state(), rang(apres.state()) > rang(avant),
                    derniere.getObservedAt()));
        }
        out.sort(Comparator
                .comparing(PlanMasteryTransitionDto::observedAt, Comparator.reverseOrder())
                .thenComparing(PlanMasteryTransitionDto::skillCode));
        return out.size() <= MAX_TRANSITIONS ? out : out.subList(0, MAX_TRANSITIONS);
    }

    /**
     * La priorite n&deg;1 <b>si elle a ete designee dans la fenetre</b>. Sinon
     * elle n'a pas change, et le candidat l'a deja sous les yeux : la republier
     * comme une nouveaute serait un faux evenement.
     */
    private static PlanSkillRefDto nouvellePriorite(
            LearningPlanObservation currentPriority, Instant since) {
        if (currentPriority == null || currentPriority.getObservedAt() == null) return null;
        if (currentPriority.getObservedAt().isBefore(since)) return null;
        Skill skill = currentPriority.getSkill();
        return new PlanSkillRefDto(
                skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection());
    }

    private static LearningPlanObservation derniereProbanteDansLaFenetre(
            List<LearningPlanObservation> history, Instant since) {
        for (LearningPlanObservation item : history) {
            if (!item.isObserved() || item.getObservedAt() == null) continue;
            if (item.getObservedAt().isBefore(since)) continue;
            return item;
        }
        return null;
    }

    /**
     * Historique par competence, chacun de la plus recente a la plus ancienne —
     * l'ordre dans lequel le Plan charge deja ses observations, reaffirme ici
     * pour ne dependre d'aucun appelant.
     */
    private static Map<UUID, List<LearningPlanObservation>> groupBySkill(
            List<LearningPlanObservation> observations) {
        Map<UUID, List<LearningPlanObservation>> bySkill = new LinkedHashMap<>();
        observations.stream()
                .filter(item -> item.getSkill() != null && item.getObservedAt() != null)
                .sorted(Comparator.comparing(
                        LearningPlanObservation::getObservedAt, Comparator.reverseOrder()))
                .forEach(item -> bySkill
                        .computeIfAbsent(item.getSkill().getId(), key -> new ArrayList<>())
                        .add(item));
        return bySkill;
    }

    /**
     * L'echelle de maitrise, ecrite <b>une fois</b> : elle sert le
     * {@code progress} du DTO pour qu'aucun front n'ait a coder l'ordre des
     * quatre etats. Volontairement un {@code switch} et non un {@code ordinal()},
     * qui ferait dependre le sens d'une fleche de l'ordre de declaration d'un
     * enum.
     */
    private static int rang(SkillMasteryState state) {
        return switch (state) {
            case PRIORITY -> 0;
            case TO_REINFORCE -> 1;
            case CONSOLIDATING -> 2;
            case SOLID -> 3;
        };
    }
}
