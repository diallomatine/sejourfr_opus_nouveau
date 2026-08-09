package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
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

    /** Repli quand le sujet ne porte aucune donnee de duree (colonnes nullables). */
    private static final int DEFAULT_MINUTES_ORAL = 5;
    private static final int DEFAULT_MINUTES_WRITTEN = 4;

    /**
     * Une part de parole, deux parts pour lire la situation, preparer et
     * s'enregistrer : le temps de parole conseille (20 a 58 s sur le contenu
     * publie) ne represente qu'un tiers du temps passe sur l'exercice.
     */
    private static final int ORAL_PREPARATION_FACTOR = 3;

    /**
     * Mots par minute retenus a l'ecrit : rythme d'un candidat A2/B1 qui redige
     * en langue etrangere, lecture de la consigne et relecture comprises.
     */
    private static final int WRITTEN_WORDS_PER_MINUTE = 12;

    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final SkillStatusResolver statusResolver;

    /** Exercice recommande pour une competence, vide si elle n'a aucun sujet actif. */
    public Optional<PlanRecommendedExerciseDto> select(UUID userId, Skill skill) {
        if (skill == null) return Optional.empty();
        return Optional.ofNullable(selectAll(userId, List.of(skill)).get(skill.getId()));
    }

    /**
     * Exercice recommande pour plusieurs competences, indexe par competence.
     * Les competences sans sujet actif sont <b>absentes</b> de la map.
     *
     * <p>Deux requetes au total, quel que soit le nombre de competences : les
     * sujets et les dernieres tentatives sont chargees en lot. C'est la raison
     * d'etre de cette signature — les deux appelants ont plusieurs competences
     * candidates a evaluer d'affilee.
     */
    public Map<UUID, PlanRecommendedExerciseDto> selectAll(
            UUID userId, Collection<Skill> skills) {
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
            SkillPrompt chosen = choose(
                    promptsBySkill.getOrDefault(entry.getKey(), List.of()), latestByPrompt);
            if (chosen == null) continue;
            out.put(entry.getKey(), new PlanRecommendedExerciseDto(
                    chosen.getId(), skill.getId(), skill.getCode(), chosen.getTitle(),
                    skill.getSection(), estimatedMinutes(chosen, skill.getSection())));
        }
        return out;
    }

    /**
     * Duree estimee d'un micro-exercice, <b>derivee du sujet lui-meme</b> et non
     * d'une constante par epreuve.
     *
     * <p>EO : {@code recommendedDurationSeconds} x {@value #ORAL_PREPARATION_FACTOR},
     * arrondi a la minute superieure. EE : milieu de la fourchette conseillee
     * ({@code recommendedMinWords}..{@code recommendedMaxWords}) divise par
     * {@value #WRITTEN_WORDS_PER_MINUTE} mots par minute, arrondi a la minute
     * superieure ; une seule borne renseignee sert seule de reference.
     *
     * <p>Les trois colonnes sont nullables (un sujet cree en console peut naitre
     * sans conseil) : sans donnee, on retombe sur les constantes historiques,
     * {@value #DEFAULT_MINUTES_ORAL} min a l'oral et
     * {@value #DEFAULT_MINUTES_WRITTEN} min a l'ecrit. Plancher 1 minute : aucun
     * exercice ne dure zero.
     */
    static int estimatedMinutes(SkillPrompt prompt, SkillSection section) {
        if (section == SkillSection.EO) {
            Integer seconds = prompt.getRecommendedDurationSeconds();
            if (seconds == null || seconds <= 0) return DEFAULT_MINUTES_ORAL;
            return atLeastOne(ceilDiv(seconds * ORAL_PREPARATION_FACTOR, 60));
        }
        Integer min = positiveOrNull(prompt.getRecommendedMinWords());
        Integer max = positiveOrNull(prompt.getRecommendedMaxWords());
        if (min == null && max == null) return DEFAULT_MINUTES_WRITTEN;
        int words = min == null ? max : max == null ? min : (min + max) / 2;
        return atLeastOne(ceilDiv(words, WRITTEN_WORDS_PER_MINUTE));
    }

    /**
     * Applique les quatre regles de preference documentees sur la classe. Les
     * sujets arrivent tries par rang d'affichage croissant ; les comparaisons de
     * date sont strictes, donc le premier de ce parcours gagne toute egalite.
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

    private static Integer positiveOrNull(Integer value) {
        return value == null || value <= 0 ? null : value;
    }

    private static int ceilDiv(int value, int divisor) {
        return (value + divisor - 1) / divisor;
    }

    private static int atLeastOne(int minutes) {
        return Math.max(1, minutes);
    }
}
