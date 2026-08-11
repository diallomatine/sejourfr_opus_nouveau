package com.sejourfr.app.service;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Progression d'un candidat sur les sujets de competences quelconques.
 *
 * <p>Deux compteurs par competence, <b>cote a cote et jamais confondus</b> :
 * <ul>
 *   <li>la <b>competence</b> ({@link SkillProgress}) — tous ses sujets actifs,
 *       exactement la semantique de {@code SkillDto} du module Competences ;</li>
 *   <li>l'<b>etape du Plan</b> ({@link LearningPlanStep.Progress}) — ses
 *       {@value LearningPlanStep#PROMPTS_PAR_ETAPE} premiers sujets seulement.</li>
 * </ul>
 * Les deux sortent du meme parcours et de la meme addition
 * ({@link SkillProgressTally}, statut derive par {@link SkillStatusResolver}) :
 * il n'existe pas deux definitions de « tente » ou « valide ».
 *
 * <p><b>Deux requetes, quel que soit le nombre de competences</b> : le Plan en
 * demande jusqu'a onze d'un coup (1 priorite + 2 suivantes + 8 observees), une
 * requete par competence y serait un N+1. Les sujets sont charges en liste
 * plutot que comptes en SQL — c'est ce qui permet de servir les deux perimetres
 * sans une requete de plus, la liste etant deja triee par rang d'affichage.
 */
@Component
@RequiredArgsConstructor
public class SkillProgressCounter {

    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final SkillStatusResolver statusResolver;

    /**
     * Compteurs indexes par competence. Toutes les competences demandees sont
     * <b>presentes</b>, a zero si elles n'ont aucun sujet actif : un ecran ne
     * doit jamais avoir a distinguer « pas de donnee » de « rien fait ».
     */
    public Map<UUID, SkillProgress> bySkillIds(UUID userId, Collection<UUID> skillIds) {
        Map<UUID, SkillProgress> out = new HashMap<>();
        for (UUID id : skillIds) {
            out.put(id, SkillProgress.EMPTY);
        }
        if (skillIds.isEmpty()) return out;

        // Un sujet retire du catalogue sort du denominateur ET du numerateur :
        // findActiveBySkillIds ne rend que les sujets actifs de competences
        // actives, donc parcourir SES lignes suffit a garantir « jamais 6 sur 5 ».
        Map<UUID, List<SkillPrompt>> promptsBySkill = promptManager.findActiveBySkillIds(skillIds);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptBySkillIds(userId, skillIds);

        for (UUID skillId : skillIds) {
            List<SkillPrompt> prompts = promptsBySkill.getOrDefault(skillId, List.of());
            List<SkillPrompt> stepPrompts = LearningPlanStep.scope(prompts);
            Set<UUID> stepPromptIds = new HashSet<>(stepPrompts.size());
            stepPrompts.forEach(prompt -> stepPromptIds.add(prompt.getId()));

            SkillProgressTally skillTally = new SkillProgressTally();
            SkillProgressTally stepTally = new SkillProgressTally();
            for (SkillPrompt prompt : prompts) {
                UserSkillAttempt latest = latestByPrompt.get(prompt.getId());
                if (latest == null) continue;
                SkillPromptStatus status = statusResolver.resolve(latest);
                skillTally.add(status);
                if (stepPromptIds.contains(prompt.getId())) stepTally.add(status);
            }

            out.put(skillId, new SkillProgress(
                    prompts.size(),
                    skillTally.attempted(),
                    skillTally.validated(),
                    skillTally.toReinforce(),
                    new LearningPlanStep.Progress(
                            stepPrompts.size(), stepTally.attempted(), stepTally.validated())));
        }
        return out;
    }

    /**
     * Progression d'une competence : sujets actifs, tentes, valides, a renforcer
     * — et, a cote, la progression sur les seuls sujets de l'etape du Plan.
     */
    public record SkillProgress(
            int promptCount,
            int attemptedCount,
            int validatedCount,
            int toReinforceCount,
            LearningPlanStep.Progress step) {

        public static final SkillProgress EMPTY =
                new SkillProgress(0, 0, 0, 0, LearningPlanStep.Progress.EMPTY);
    }
}
