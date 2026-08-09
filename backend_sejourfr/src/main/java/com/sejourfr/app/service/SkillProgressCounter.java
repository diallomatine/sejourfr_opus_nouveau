package com.sejourfr.app.service;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Progression d'un candidat sur les sujets de competences quelconques.
 *
 * <p>Meme semantique que les compteurs de {@code SkillDto} — sujets ACTIFS
 * d'une competence ACTIVE au denominateur, statut derive par
 * {@link SkillStatusResolver}, addition par {@link SkillProgressTally}. C'est
 * volontairement le meme calcul : le Plan et le catalogue de competences
 * decrivent la meme progression, vue depuis deux ecrans.
 *
 * <p><b>Deux requetes, quel que soit le nombre de competences</b> : le Plan en
 * demande jusqu'a onze d'un coup (1 priorite + 2 suivantes + 8 observees), une
 * requete par competence y serait un N+1.
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

        Map<UUID, Long> promptCounts = promptManager.countActiveBySkillIds(skillIds);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptBySkillIds(userId, skillIds);

        Map<UUID, SkillProgressTally> tallies = new HashMap<>();
        for (UserSkillAttempt attempt : latestByPrompt.values()) {
            SkillPrompt prompt = attempt.getSkillPrompt();
            // Un sujet retire du catalogue sort du denominateur : il doit aussi
            // sortir du numerateur, sinon « 6 sur 5 ».
            if (!prompt.isActive() || !prompt.getSkill().isActive()) continue;
            tallies.computeIfAbsent(prompt.getSkill().getId(), k -> new SkillProgressTally())
                    .add(statusResolver.resolve(attempt));
        }

        for (UUID skillId : skillIds) {
            SkillProgressTally tally = tallies.getOrDefault(skillId, new SkillProgressTally());
            out.put(skillId, new SkillProgress(
                    promptCounts.getOrDefault(skillId, 0L).intValue(),
                    tally.attempted(),
                    tally.validated(),
                    tally.toReinforce()));
        }
        return out;
    }

    /** Progression d'une competence : sujets actifs, tentes, valides, a renforcer. */
    public record SkillProgress(
            int promptCount,
            int attemptedCount,
            int validatedCount,
            int toReinforceCount) {

        public static final SkillProgress EMPTY = new SkillProgress(0, 0, 0, 0);
    }
}
