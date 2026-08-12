package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Le chargement du moteur de maitrise : <b>une requete, quel que soit le nombre
 * de competences</b>.
 *
 * <p>Un ecran de competences en affiche 24, le Plan en demande une dizaine
 * (3 priorites + 8 observees). Interroger l'historique competence par competence
 * serait un N+1 pur — c'est exactement la raison d'etre de
 * {@link #bySkillIds}, et de l'index {@code idx_learning_plan_user_skill_recent}
 * qui existait deja sans qu'aucune requete ne l'emprunte.
 *
 * <p>Deux entrees, jamais deux calculs : {@link #bySkillIds} charge, et
 * {@link #fromObservations} se branche sur un historique <b>deja en memoire</b>
 * — le Plan lit deja toutes les observations du candidat pour ordonner ses
 * priorites, il n'a aucune raison de les relire. Les deux passent par le meme
 * {@link SkillMasteryEngine} : il n'existe qu'une definition de la maitrise.
 */
@Component
@RequiredArgsConstructor
public class SkillMasteryResolver {

    /**
     * Points rendus sur la frise d'une competence. Bien au-dela de ce qu'un
     * ecran affiche : la borne existe pour qu'aucune requete ne soit non bornee,
     * pas pour tronquer un parcours reel.
     */
    public static final int TRAJECTORY_LIMIT = 50;

    private final LearningPlanObservationManager observationManager;
    private final SkillMasteryEngine engine;
    private final LearningPlanProperties properties;

    /**
     * L'etat de maitrise de chaque competence demandee. Toutes sont
     * <b>presentes</b> dans la reponse, a
     * {@link SkillMasteryEngine.SkillMastery#NONE} quand rien n'a jamais ete
     * observe : un ecran ne doit pas avoir a distinguer « pas de donnee » de
     * « rien vu ».
     */
    @Transactional(readOnly = true)
    public Map<UUID, SkillMasteryEngine.SkillMastery> bySkillIds(
            UUID userId, Collection<UUID> skillIds) {
        Set<UUID> ids = new LinkedHashSet<>(skillIds);
        if (ids.isEmpty()) return Map.of();
        Instant now = Instant.now();
        List<LearningPlanObservation> observations = observationManager.findByUserAndSkillsSince(
                userId, ids, now.minus(Duration.ofDays(properties.getMastery().getWindowDays())));
        return evaluate(observations, ids, now);
    }

    /**
     * Meme calcul, <b>sans une requete de plus</b>, a partir d'un historique
     * deja charge. Les observations etrangeres aux competences demandees sont
     * ignorees.
     */
    public Map<UUID, SkillMasteryEngine.SkillMastery> fromObservations(
            Collection<LearningPlanObservation> observations, Collection<UUID> skillIds) {
        Set<UUID> ids = new LinkedHashSet<>(skillIds);
        if (ids.isEmpty()) return Map.of();
        return evaluate(observations, ids, Instant.now());
    }

    /**
     * La suite datee des observations probantes d'une competence, <b>de la plus
     * ancienne a la plus recente</b> : c'est le sens dans lequel une frise se
     * lit.
     */
    @Transactional(readOnly = true)
    public List<LearningPlanObservation> trajectory(UUID userId, UUID skillId) {
        List<LearningPlanObservation> recentFirst =
                new ArrayList<>(observationManager.findTrajectory(userId, skillId, TRAJECTORY_LIMIT));
        return recentFirst.reversed();
    }

    private Map<UUID, SkillMasteryEngine.SkillMastery> evaluate(
            Collection<LearningPlanObservation> observations, Set<UUID> skillIds, Instant now) {
        Map<UUID, List<LearningPlanObservation>> bySkill = new HashMap<>();
        for (UUID id : skillIds) {
            bySkill.put(id, new ArrayList<>());
        }
        for (LearningPlanObservation observation : observations) {
            List<LearningPlanObservation> bucket = bySkill.get(observation.getSkill().getId());
            if (bucket != null) bucket.add(observation);
        }
        Map<UUID, SkillMasteryEngine.SkillMastery> out = new HashMap<>(skillIds.size());
        bySkill.forEach((skillId, items) -> out.put(skillId, engine.evaluate(items, now)));
        return out;
    }
}
