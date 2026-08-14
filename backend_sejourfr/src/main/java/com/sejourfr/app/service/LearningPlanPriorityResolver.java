package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
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
        return latestObservedBySkill(observationManager.findAllByUserWithSkill(userId));
    }

    /**
     * Meme regle, sur un historique <b>deja charge</b>. Le Plan a besoin de la
     * liste complete pour alimenter le moteur de maitrise : sans cette surcharge
     * il aurait relu deux fois les memes lignes.
     *
     * @param observations toutes les observations du candidat, <b>de la plus
     *                     recente a la plus ancienne</b>.
     */
    public Map<UUID, LearningPlanObservation> latestObservedBySkill(
            List<LearningPlanObservation> observations) {
        Map<UUID, LearningPlanObservation> latest = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            if (!observation.isObserved()) continue;
            latest.putIfAbsent(observation.getSkill().getId(), observation);
        }
        return latest;
    }

    /**
     * Les priorites, deja ordonnees : {@code PRIORITY} avant
     * {@code TO_REINFORCE}, puis <b>confiance decroissante</b>, puis
     * l'observation la plus recente, au plus {@value #MAX_PRIORITIES}. Les
     * fronts affichent cet ordre sans le recalculer.
     *
     * <p><b>Une faiblesse observee EST une priorite derivee</b>, exactement
     * comme cote diagnostic : le correcteur range ses faiblesses en
     * {@code TO_REINFORCE} et ne pose quasiment jamais {@code PRIORITY}, si bien
     * qu'exiger ce seul statut laisserait un Plan {@code ACTIVE} sans rien a
     * faire. {@code SOLID} et {@code NOT_OBSERVED} n'en deviennent jamais une :
     * zero faiblesse observee donne zero priorite, et c'est legitime.
     *
     * <p><b>La confiance departage avant la recence</b>, et ce n'est pas un
     * detail : c'est ce qui empeche cette methode et
     * {@code DiagnosticPriorityRanking} de designer deux etapes n&deg;1
     * differentes. Les deux productions du diagnostic sont observees au meme
     * instant — la recence n'y trie rien, la confiance si, et c'est le premier
     * critere de la regle du diagnostic. Deux surfaces qui repondent
     * differemment a la meme question, c'est le defaut deja corrige sur le
     * niveau TCF estime.
     */
    public List<LearningPlanObservation> actionable(
            Collection<LearningPlanObservation> latestObserved) {
        return latestObserved.stream()
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.PRIORITY
                        || item.getStatus() == LearningPlanSkillStatus.TO_REINFORCE)
                .sorted(Comparator
                        .comparingInt((LearningPlanObservation item) ->
                                item.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
                        .thenComparingInt(item -> -confidenceRank(item.getConfidence()))
                        .thenComparing(LearningPlanObservation::getObservedAt,
                                Comparator.reverseOrder()))
                .limit(MAX_PRIORITIES)
                .toList();
    }

    /**
     * {@code HIGH} 3, {@code MEDIUM} 2, tout le reste 1 — miroir de
     * {@code DiagnosticPriorityRanking.confidenceRank}, sur l'observation
     * persistee au lieu du JSON du correcteur.
     */
    private static int confidenceRank(ObservationConfidence confidence) {
        if (confidence == null) return 1;
        return switch (confidence) {
            case HIGH -> 3;
            case MEDIUM -> 2;
            case LOW -> 1;
        };
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
