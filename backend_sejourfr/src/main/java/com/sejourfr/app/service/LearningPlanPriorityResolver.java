package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * L'ordre des priorites du Plan, <b>ecrit une seule fois</b>.
 *
 * <p>Il a deux lecteurs qui doivent dire exactement la meme chose :
 * {@link LearningPlanService}, qui rend les priorites au candidat, et
 * {@link SkillAccessService}, qui ouvre la competence de la priorite n&deg;1 a un
 * compte sans acces TCF. Deux implementations auraient fini par diverger, et le
 * candidat aurait vu son etape n&deg;1 cadenassee — exactement ce que
 * l'ouverture de cette competence cherche a eviter.
 */
@Component
@RequiredArgsConstructor
public class LearningPlanPriorityResolver {

    /** Le Plan ne montre jamais plus de 3 priorites : une courante, deux suivantes. */
    static final int MAX_PRIORITIES = 3;

    private final LearningPlanObservationManager observationManager;

    /**
     * La derniere observation <b>probante</b> de chaque competence, la plus
     * recente d'abord.
     *
     * <p>La requete est triee DESC : le premier signal reellement observe fait
     * foi. {@code NOT_OBSERVED} reste un evenement historique utile mais
     * signifie seulement « aucune preuve dans cette production » — il ne
     * contredit jamais une preuve anterieure.
     */
    @Transactional(readOnly = true)
    public Map<UUID, LearningPlanObservation> latestObservedBySkill(UUID userId) {
        Map<UUID, LearningPlanObservation> latest = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observationManager.findAllByUserWithSkill(userId)) {
            if (!observation.isObserved()) continue;
            latest.putIfAbsent(observation.getSkill().getId(), observation);
        }
        return latest;
    }

    /**
     * Les priorites, deja ordonnees : {@code PRIORITY} avant
     * {@code TO_REINFORCE}, puis l'observation la plus recente d'abord, au plus
     * {@value #MAX_PRIORITIES}. Les fronts affichent cet ordre sans le
     * recalculer.
     */
    public List<LearningPlanObservation> actionable(
            Collection<LearningPlanObservation> latestObserved) {
        return latestObserved.stream()
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.PRIORITY
                        || item.getStatus() == LearningPlanSkillStatus.TO_REINFORCE)
                .sorted(Comparator
                        .comparingInt((LearningPlanObservation item) ->
                                item.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
                        .thenComparing(LearningPlanObservation::getObservedAt,
                                Comparator.reverseOrder()))
                .limit(MAX_PRIORITIES)
                .toList();
    }

    /**
     * La competence de la priorite n&deg;1 de ce candidat, vide s'il n'en a
     * aucune.
     *
     * <p><b>On n'exige pas ici de diagnostic termine</b>, alors que le Plan ne
     * rend ses priorites qu'une fois le diagnostic {@code COMPLETED} : une
     * observation probante venue d'une correction de production suffit. Le pire
     * cas est une competence ouverte de plus, jamais une competence fermee a
     * tort — et c'est le bon sens de l'erreur pour un verrou commercial.
     */
    @Transactional(readOnly = true)
    public Optional<UUID> currentPrioritySkillId(UUID userId) {
        return actionable(latestObservedBySkill(userId).values()).stream()
                .findFirst()
                .map(observation -> observation.getSkill().getId());
    }
}
