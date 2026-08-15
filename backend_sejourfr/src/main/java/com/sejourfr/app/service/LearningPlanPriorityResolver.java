package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
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
     * <p><b>Une competence dont le transfert est prouve sort des priorites</b>,
     * quel que soit son statut le plus recent — cf.
     * {@link #transfertProuve(List)}. « Une fois reussi, on passe a la
     * competence suivante » : c'est ce qui fait avancer le Plan d'une etape.
     *
     * <p><b>La confiance departage avant la recence</b>, et ce n'est pas un
     * detail : c'est ce qui empeche cette methode et
     * {@code DiagnosticPriorityRanking} de designer deux etapes n&deg;1
     * differentes. Les deux productions du diagnostic sont observees au meme
     * instant — la recence n'y trie rien, la confiance si, et c'est le premier
     * critere de la regle du diagnostic. Deux surfaces qui repondent
     * differemment a la meme question, c'est le defaut deja corrige sur le
     * niveau TCF estime.
     *
     * @param observations tout l'historique du candidat, <b>de la plus recente a
     *                     la plus ancienne</b>. L'historique entier est
     *                     necessaire : la derniere observation d'une competence
     *                     ne dit pas si son transfert a deja ete prouve.
     */
    public List<LearningPlanObservation> actionable(List<LearningPlanObservation> observations) {
        Set<UUID> transfere = transfertProuve(observations);
        return latestObservedBySkill(observations).values().stream()
                .filter(item -> !transfere.contains(item.getSkill().getId()))
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
     * Les competences dont le transfert est <b>prouve</b> : leur derniere
     * observation issue d'une <b>production contextualisee</b> vaut
     * {@code SOLID}.
     *
     * <p><b>Pourquoi cette regle existe.</b> Le proprietaire l'a tranchee ainsi :
     * « une fois reussi, on passe a la competence suivante ». Sans elle, une
     * verification en situation reussie ne suffisait pas a faire avancer le Plan
     * — l'etape restait affichee jusqu'a ce que l'etat agrege du moteur atteigne
     * {@code SOLID}, qui reclame <b>deux</b> observations positives sur des
     * sujets differents, et un simple micro-exercice rate ensuite remettait la
     * competence en tete.
     *
     * <p><b>Contextualisee, et rien d'autre</b> ({@code PRODUCTION_EE/EO},
     * {@code MOCK_EXAM_EE/EO} — cf.
     * {@link com.sejourfr.app.enums.LearningPlanSourceType#isContextual()}) : un
     * micro-entrainement est guide vers cette seule competence et ne prouve
     * aucun transfert ; le diagnostic est la <b>baseline</b>, c'est le point de
     * depart qu'on cherche justement a depasser. Un {@code SOLID} venu de l'un
     * ou de l'autre ne sort donc jamais une competence des priorites.
     *
     * <p><b>Reversible</b> : c'est la <b>derniere</b> observation contextualisee
     * qui fait foi, pas « au moins une dans toute l'histoire ». Une production
     * ulterieure qui fragilise la competence la ramene aussitot parmi les
     * priorites. A l'inverse un micro-exercice rate ne revoque rien — meme sens
     * que {@code SkillMasteryEngine}, ou seules les fragilites contextualisees
     * peuvent defaire une maitrise prouvee en situation.
     *
     * <p>⚠️ <b>Sortir des priorites n'est pas etre {@code SOLID} au sens du
     * moteur.</b> {@code SkillMasteryEngine} et l'etat agrege
     * {@code SkillMasteryState} ne bougent pas d'un pouce : la competence peut
     * rester {@code CONSOLIDATING}, et {@code PlanMilestoneSelector} continue de
     * compter exactement les memes competences {@code SOLID} qu'avant. C'est
     * voulu et honnete : une preuve n'est pas une maitrise installee.
     */
    private static Set<UUID> transfertProuve(List<LearningPlanObservation> observations) {
        Map<UUID, LearningPlanObservation> derniereEnSituation = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            if (!observation.isObserved()) continue;
            LearningPlanSourceType source = observation.getSourceType();
            if (source == null || !source.isContextual()) continue;
            derniereEnSituation.putIfAbsent(observation.getSkill().getId(), observation);
        }
        Set<UUID> prouve = new LinkedHashSet<>();
        derniereEnSituation.forEach((skillId, observation) -> {
            if (observation.getStatus() == LearningPlanSkillStatus.SOLID) prouve.add(skillId);
        });
        return prouve;
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
     * <p><b>Elle se deplace quand une competence est reussie</b> : des que le
     * transfert d'une competence est prouve, elle sort des priorites et c'est la
     * suivante que ce verrou ouvre a un compte gratuit. Coherent avec ce que le
     * Plan affiche — le candidat lit « a faire maintenant » et trouve ce
     * sujet-la ouvert.
     *
     * <p><b>On n'exige pas ici de diagnostic termine</b>, alors que le Plan ne
     * rend ses priorites qu'une fois le diagnostic {@code COMPLETED} : une
     * observation probante venue d'une correction de production suffit. Le pire
     * cas est une competence ouverte de plus, jamais une competence fermee a
     * tort — et c'est le bon sens de l'erreur pour un verrou commercial.
     */
    @Transactional(readOnly = true)
    public Optional<UUID> currentPrioritySkillId(UUID userId) {
        return actionable(observationManager.findAllByUserWithSkill(userId)).stream()
                .findFirst()
                .map(observation -> observation.getSkill().getId());
    }
}
