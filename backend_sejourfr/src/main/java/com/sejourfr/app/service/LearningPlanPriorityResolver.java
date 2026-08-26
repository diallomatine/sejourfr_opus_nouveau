package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * L'ordre des priorites du Plan, <b>ecrit une seule fois</b>.
 *
 * <p>Il a deux lecteurs qui doivent dire exactement la meme chose :
 * {@link LearningPlanService}, qui rend les priorites au candidat, et
 * {@link PlanFocusResolver}, dont {@link SkillAccessService} tire la competence
 * ouverte d'office a un compte sans acces TCF. Deux implementations auraient fini
 * par diverger, et le candidat aurait vu son etape n&deg;1 cadenassee —
 * exactement ce que l'ouverture de cette competence cherche a eviter.
 *
 * <p>⚠️ <b>« Priorite n&deg;1 » ne veut plus dire « premiere fragilite »</b>
 * depuis que le Plan sait aussi <b>enseigner</b> : la premiere carte peut etre
 * une competence a <b>acquerir</b>, que ce resolveur ne voit pas — elle n'a
 * aucune ligne d'historique. C'est {@link PlanFocusResolver} qui repond a
 * « quelle competence occupe la premiere place », et lui seul.
 */
@Component
@RequiredArgsConstructor
public class LearningPlanPriorityResolver {

    private final LearningPlanObservationManager observationManager;

    /**
     * Le moteur de maitrise, <b>seule autorite</b> sur « le transfert est-il
     * prouve ? ». Il travaille sur l'historique <b>deja charge</b>
     * ({@code fromObservations}) : cette dependance ne coute pas une requete.
     */
    private final SkillMasteryResolver masteryResolver;

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
     * <b>La derniere activite de chaque competence</b>, sur un historique
     * <b>deja charge</b> : aucune requete, une seule passe.
     *
     * <p>Elle repond a « quand ce candidat a-t-il travaille cette competence
     * pour la derniere fois ? », et c'est ce <b>fait</b> que la seance publie
     * pour que les fronts cochent ce qui a ete fait aujourd'hui. Le serveur ne
     * calcule pas ce booleen : il n'a pas d'horloge dans la construction de la
     * seance, et une reponse « fait aujourd'hui » figee a la lecture serait
     * fausse des le lendemain sans nouvel appel.
     *
     * <p><b>Toutes les observations comptent</b>, {@code NOT_OBSERVED} compris —
     * c'est la difference avec {@link #latestObservedBySkill}. « Le correcteur
     * n'a rien pu observer » ne veut pas dire « le candidat n'a rien fait » : la
     * ligne existe parce qu'une production a ete rendue, et la masquer ferait
     * disparaitre la coche d'un travail reel.
     *
     * @param observations tout l'historique, <b>de la plus recente a la plus
     *                     ancienne</b> — la premiere ligne de chaque competence
     *                     fait donc foi.
     */
    public Map<UUID, Instant> lastActivityBySkill(List<LearningPlanObservation> observations) {
        Map<UUID, Instant> latest = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            latest.putIfAbsent(observation.getSkill().getId(), observation.getObservedAt());
        }
        return latest;
    }

    /**
     * <b>TOUTES</b> les priorites, deja ordonnees : {@code PRIORITY} avant
     * {@code TO_REINFORCE}, puis <b>confiance decroissante</b>, puis
     * l'observation la plus recente.
     *
     * <p>🛑 <b>Aucun plafond ici depuis le 2026-08-26.</b> Cette methode rendait
     * au plus cinq lignes, et {@code LearningPlanService} s'en servait comme
     * d'un <b>budget</b> : les places restantes bornaient ce que le Plan avait
     * le droit d'apprendre, sur les quatre domaines a la fois. Un plafond
     * d'affichage n'est pas un budget pedagogique — le moteur calcule tout,
     * l'affichage coupe ({@code plan-config}, {@code display.*}).
     *
     * <p><b>Une faiblesse observee EST une priorite derivee</b>, exactement
     * comme cote diagnostic : le correcteur range ses faiblesses en
     * {@code TO_REINFORCE} et ne pose quasiment jamais {@code PRIORITY}, si bien
     * qu'exiger ce seul statut laisserait un Plan {@code ACTIVE} sans rien a
     * faire. {@code SOLID} et {@code NOT_OBSERVED} n'en deviennent jamais une :
     * zero faiblesse observee donne zero priorite, et c'est legitime.
     *
     * <p><b>Une competence dont le transfert est prouve sort des priorites</b>,
     * quel que soit son statut le plus recent — et « transfert prouve » se lit
     * chez {@code SkillMasteryEngine}
     * ({@code SkillMastery.transferProven()}), <b>jamais ici</b>. « Une fois
     * reussi, on passe a la competence suivante » : c'est ce qui fait avancer le
     * Plan d'une etape.
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
        return actionable(observations, mastery(observations));
    }

    /**
     * Meme regle, sur des etats de maitrise <b>deja calcules</b> — ce que fait
     * {@link LearningPlanService}, qui a besoin des memes etats pour ses cartes,
     * ses jalons et sa bascule de verification. Sans cette surcharge le meme
     * calcul tournerait deux fois par lecture du Plan.
     */
    public List<LearningPlanObservation> actionable(
            List<LearningPlanObservation> observations,
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery) {
        return latestObservedBySkill(observations).values().stream()
                .filter(item -> !transfertProuve(mastery, item))
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.PRIORITY
                        || item.getStatus() == LearningPlanSkillStatus.TO_REINFORCE)
                .sorted(Comparator
                        .comparingInt((LearningPlanObservation item) ->
                                item.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
                        .thenComparingInt(item -> -confidenceRank(item.getConfidence()))
                        .thenComparing(LearningPlanObservation::getObservedAt,
                                Comparator.reverseOrder()))
                .toList();
    }

    /**
     * Les <b>etapes franchies</b> : la derniere observation probante de chaque
     * competence dont le transfert est prouve, <b>de la plus recente a la plus
     * ancienne</b> et departagee par code pour rester deterministe.
     *
     * <p>Exactement le complement de {@link #actionable} : ce que l'une ecarte,
     * l'autre le rend. Une competence franchie ne <b>disparait</b> donc plus du
     * parcours — le candidat garde la trace de ce qu'il a passe, et c'est aux
     * fronts de la cocher. Le bornage a l'affichage appartient a
     * {@link LearningPlanService}, pas ici : la regle n'est pas une question de
     * place a l'ecran.
     */
    public List<LearningPlanObservation> franchies(
            List<LearningPlanObservation> observations,
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery) {
        return latestObservedBySkill(observations).values().stream()
                .filter(item -> transfertProuve(mastery, item))
                .sorted(Comparator
                        .comparing(LearningPlanObservation::getObservedAt,
                                Comparator.reverseOrder())
                        .thenComparing(item -> item.getSkill().getCode()))
                .toList();
    }

    /**
     * « Le transfert de cette competence est-il prouve ? » — <b>lu</b> chez
     * {@code SkillMasteryEngine}, jamais recalcule.
     *
     * <p><b>Ce qui a change le 2026-08-15, et pourquoi.</b> Cette classe portait
     * sa propre definition : « la <b>derniere</b> observation issue d'une
     * production contextualisee vaut {@code SOLID} ». Deux lectures du meme
     * historique coexistaient donc, et elles se sont contredites en production —
     * un candidat ayant prouve son transfert <b>trois fois</b> en situation puis
     * rendu une production moins bonne restait priorite n&deg;1 pour cette regle,
     * pendant que le moteur le declarait {@code SOLID} et fermait, pour cette
     * raison meme, le signal de verification. Ni sortie de priorite, ni bouton
     * de verification : blocage <b>definitif</b>, aucun micro-entrainement ne
     * pouvant en sortir (la voie ciblee n'ecrit jamais d'observation
     * contextualisee).
     *
     * <p>L'ancienne regle avait de surcroit une tolerance <b>nulle</b> la ou le
     * moteur en accorde {@code fragility-tolerance}, et comptait comme
     * revocatrice une observation {@code TO_REINFORCE} que le moteur ne tient
     * meme pas pour une fragilite. C'est le moteur qui a raison : il lit la
     * fenetre glissante, les ponderations et la tolerance. Il ne reste donc
     * qu'une definition, et elle vit chez lui.
     */
    private static boolean transfertProuve(
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery,
            LearningPlanObservation observation) {
        SkillMasteryEngine.SkillMastery state = mastery.get(observation.getSkill().getId());
        return state != null && state.transferProven();
    }

    /** Le moteur, sur l'historique deja en main : aucune requete de plus. */
    private Map<UUID, SkillMasteryEngine.SkillMastery> mastery(
            List<LearningPlanObservation> observations) {
        return masteryResolver.fromObservations(
                observations, latestObservedBySkill(observations).keySet());
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
}
