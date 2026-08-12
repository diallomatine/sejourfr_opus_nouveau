package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.util.ExerciseDuration;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Choisit LE micro-exercice a proposer sur une competence.
 *
 * <p><b>Un seul endroit</b> : le Plan ({@code LearningPlanService}) et l'ecran
 * de resultat du diagnostic ({@code DiagnosticService}) doivent proposer le
 * meme sujet a la meme seconde. Deux implementations auraient diverge, et le
 * candidat aurait vu deux « exercice recommande » differents pour une seule et
 * meme priorite.
 *
 * <p><b>Le perimetre est celui de l'ETAPE</b>, pas celui de la competence : le
 * choix se fait parmi les {@value LearningPlanStep#PROMPTS_PAR_ETAPE} premiers
 * sujets actifs ({@link LearningPlanStep#scope}). Sans cette borne, « Continuer
 * cette etape » enverrait vers un sujet hors etape, dont l'anneau « x/5 » ne
 * bougerait pas. La borne vaut pour les DEUX appelants : l'ecran de resultat du
 * diagnostic designe la competence de la priorite n&deg;1, il doit pointer dans
 * les memes cinq sujets que le Plan.
 *
 * <p><b>La regle : ca doit avancer.</b> Prendre systematiquement le premier
 * sujet de la competence — ce que faisait le code d'origine — renvoyait
 * indefiniment le sujet de rang 1 a un candidat qui l'avait deja traite dix
 * fois. L'ordre de preference est donc :
 * <ol>
 *   <li>le premier sujet <b>jamais tente</b>, par rang d'affichage croissant :
 *       du contenu neuf avant tout, et dans l'ordre de difficulte editoriale ;</li>
 *   <li>sinon le sujet <b>a renforcer</b> ({@link SkillPromptStatus#TO_REINFORCE})
 *       dont la derniere tentative est la plus ancienne — on revient sur ce qui
 *       n'est pas acquis, en commencant par ce qu'on n'a pas revu depuis le plus
 *       longtemps ;</li>
 *   <li>sinon le sujet dont la derniere tentative est la plus ancienne : tout a
 *       ete traite, on fait tourner plutot que de rejouer le dernier rendu ;</li>
 *   <li>sinon rien — la competence n'a aucun sujet actif.</li>
 * </ol>
 *
 * <p>Deterministe de bout en bout : a egalite de date, c'est le rang
 * d'affichage le plus bas qui gagne (les sujets sont parcourus dans cet ordre
 * et une comparaison stricte ne deloge jamais le premier arrive).
 */
@Component
@RequiredArgsConstructor
public class RecommendedExerciseSelector {

    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final SkillStatusResolver statusResolver;
    private final SkillAccessService accessService;

    /** Exercice recommande pour une competence, vide si elle n'a aucun sujet actif. */
    public Optional<PlanRecommendedExerciseDto> select(UUID userId, Skill skill) {
        if (skill == null) return Optional.empty();
        return Optional.ofNullable(selectAll(userId, List.of(skill)).get(skill.getId()));
    }

    /**
     * Comme {@link #selectAll(UUID, Collection, SkillAccessService.SkillAccess)},
     * en resolvant le verrou d'acces ici. A utiliser quand l'appelant n'en a pas
     * deja besoin par ailleurs.
     */
    public Map<UUID, PlanRecommendedExerciseDto> selectAll(
            UUID userId, Collection<Skill> skills) {
        return selectAll(userId, skills, accessService.resolve(userId));
    }

    /**
     * Exercice recommande pour plusieurs competences, indexe par competence.
     * Les competences sans sujet actif sont <b>absentes</b> de la map.
     *
     * <p>Deux requetes au total, quel que soit le nombre de competences : les
     * sujets et les dernieres tentatives sont chargees en lot. C'est la raison
     * d'etre de cette signature — les deux appelants ont plusieurs competences
     * candidates a evaluer d'affilee.
     *
     * <p><b>Le verrou est reporte, jamais applique a la selection</b> : un sujet
     * verrouille reste recommande, avec {@code locked = true}. Savoir quoi
     * travailler est precisement ce que le Plan apporte ; le detourner vers un
     * sujet ouvert lui ferait dire autre chose que la priorite mesuree.
     * L'{@code access} est passe par l'appelant quand il l'a deja resolu, pour
     * ne pas le recalculer deux fois sur le meme ecran.
     */
    public Map<UUID, PlanRecommendedExerciseDto> selectAll(
            UUID userId, Collection<Skill> skills, SkillAccessService.SkillAccess access) {
        Map<UUID, Skill> bySkillId = new LinkedHashMap<>();
        for (Skill skill : skills) {
            if (skill != null) bySkillId.putIfAbsent(skill.getId(), skill);
        }
        Map<UUID, PlanRecommendedExerciseDto> out = new LinkedHashMap<>();
        if (bySkillId.isEmpty()) return out;

        Collection<UUID> skillIds = new LinkedHashSet<>(bySkillId.keySet());
        Map<UUID, List<SkillPrompt>> promptsBySkill = promptManager.findActiveBySkillIds(skillIds);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptBySkillIds(userId, skillIds);

        for (Map.Entry<UUID, Skill> entry : bySkillId.entrySet()) {
            Skill skill = entry.getValue();
            // Borne d'etape : les quatre regles de preference sont intactes,
            // c'est l'ensemble sur lequel elles s'appliquent qui est reduit.
            SkillPrompt chosen = choose(
                    LearningPlanStep.scope(
                            promptsBySkill.getOrDefault(entry.getKey(), List.of())),
                    latestByPrompt);
            if (chosen == null) continue;
            out.put(entry.getKey(), PlanRecommendedExerciseDto.microTraining(
                    chosen.getId(), skill.getId(), skill.getCode(), chosen.getTitle(),
                    skill.getSection(), estimatedMinutes(chosen, skill.getSection()),
                    access.isPromptLocked(chosen.getId())));
        }
        return out;
    }

    /**
     * Duree estimee d'un micro-exercice, <b>derivee du sujet lui-meme</b> et non
     * d'une constante par epreuve. La formule vit dans {@link ExerciseDuration},
     * partagee avec la verification en situation : deux copies auraient fini par
     * annoncer deux temps differents pour un travail comparable.
     */
    static int estimatedMinutes(SkillPrompt prompt, SkillSection section) {
        return section == SkillSection.EO
                ? ExerciseDuration.oral(prompt.getRecommendedDurationSeconds())
                : ExerciseDuration.written(
                        prompt.getRecommendedMinWords(), prompt.getRecommendedMaxWords());
    }

    /**
     * Applique les quatre regles de preference documentees sur la classe. Les
     * sujets arrivent <b>deja bornes a l'etape</b> et tries par rang d'affichage
     * croissant ; les comparaisons de date sont strictes, donc le premier de ce
     * parcours gagne toute egalite.
     */
    private SkillPrompt choose(
            List<SkillPrompt> prompts, Map<UUID, UserSkillAttempt> latestByPrompt) {
        SkillPrompt oldestToReinforce = null;
        Instant oldestToReinforceAt = null;
        SkillPrompt oldest = null;
        Instant oldestAt = null;

        for (SkillPrompt prompt : prompts) {
            UserSkillAttempt latest = latestByPrompt.get(prompt.getId());
            // Regle 1 : les sujets arrivent par rang croissant, donc le premier
            // jamais tente rencontre EST le bon — inutile de parcourir la suite.
            if (latest == null) return prompt;

            Instant at = createdAt(latest);
            if (oldestAt == null || at.isBefore(oldestAt)) {
                oldest = prompt;
                oldestAt = at;
            }
            if (statusResolver.resolve(latest) == SkillPromptStatus.TO_REINFORCE
                    && (oldestToReinforceAt == null || at.isBefore(oldestToReinforceAt))) {
                oldestToReinforce = prompt;
                oldestToReinforceAt = at;
            }
        }
        return oldestToReinforce != null ? oldestToReinforce : oldest;
    }

    private static Instant createdAt(UserSkillAttempt attempt) {
        return attempt.getCreatedAt() == null ? Instant.EPOCH : attempt.getCreatedAt();
    }

}
