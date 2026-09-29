package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.domain.RecommendationReasonCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * <b>« Pourquoi cette recommandation ? »</b> — la réponse, en un code et une
 * ligne de log (V4.2 §46).
 *
 * <p>Un moteur qui décide sans pouvoir s'expliquer est un moteur qu'on ne peut
 * pas corriger : quand un candidat se plaint que son Plan lui redemande de l'A2,
 * il faut pouvoir dire <i>lequel</i> de ses états a produit ça, et avec quels
 * chiffres. Sans cette trace, on rejoue le moteur à la main en espérant
 * retrouver le même état — ce qui n'arrive jamais, parce que la confiance a
 * bougé entre-temps.
 *
 * <p>La ligne porte donc l'état complet, y compris {@code masteryScore} et
 * {@code confidence} : c'est un log serveur, pas une réponse HTTP, et §25 bis.2
 * n'interdit ces valeurs que vers les fronts.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressionExplanationService {

    /**
     * Le code de raison d'un palier réceptif, dans l'ordre de priorité du Plan
     * (§30).
     *
     * <p>L'ordre <b>est</b> la règle et se lit de haut en bas : une vérification
     * en attente passe avant tout le reste, un palier satisfait par le dessus ne
     * se retravaille pas, et un domaine jamais mesuré appelle une mesure — pas
     * un entraînement à l'aveugle.
     */
    public RecommendationReasonCode raison(DomainProjection projection, TargetLevel niveau) {
        ProgressionSnapshot etat = projection.levels().get(niveau);
        if (etat.status() == ProgressionStatus.WATCH) {
            return RecommendationReasonCode.WATCH_RECHECK;
        }
        if (Boolean.TRUE.equals(projection.prerequisiteSatisfied().get(niveau))) {
            return RecommendationReasonCode.VALIDATED_VIA_HIGHER_LEVEL;
        }
        if (etat.status() == ProgressionStatus.NOT_EVALUATED) {
            return RecommendationReasonCode.MISSING_ASSESSMENT;
        }
        if (etat.status() == ProgressionStatus.SOLID) {
            return RecommendationReasonCode.NEXT_LEVEL_UNLOCKED;
        }
        return RecommendationReasonCode.ACTIVE_LEVEL_NOT_CLEARED;
    }

    /** Le code de raison d'une compétence de production. */
    public RecommendationReasonCode raison(ProgressionSnapshot etat) {
        return switch (etat.status()) {
            case WATCH -> RecommendationReasonCode.WATCH_RECHECK;
            case READY_FOR_REASSESSMENT -> RecommendationReasonCode.READY_FOR_REASSESSMENT;
            case NOT_EVALUATED -> RecommendationReasonCode.MISSING_ASSESSMENT;
            case SOLID -> RecommendationReasonCode.NEXT_LEVEL_UNLOCKED;
            case FRAGILE, PROGRESSING -> RecommendationReasonCode.SKILL_FRAGILE;
        };
    }

    /**
     * §46 — la trace d'un état recalculé, avec tout ce qu'il faut pour
     * comprendre ce qu'il a produit.
     *
     * <p>Une seule ligne, et à {@code debug} : elle est écrite à chaque preuve
     * ingérée, et une trace d'observabilité ne doit pas noyer les vrais
     * incidents en {@code info}. On la remonte à la demande, quand on enquête.
     */
    public void tracer(UUID userId, ProgressionSnapshot etat, RecommendationReasonCode raison,
                       int engineVersion) {
        log.debug("Progression user={} {} status={} mastery={} confidence={} gate={} "
                        + "transfer={} direct={} qualifiantes={} contradictions={} "
                        + "visible={} cycle={} v={} raison={}",
                userId, etat.stateKey().asText(), etat.status(),
                format(etat.masteryScore()), String.format("%.4f", etat.confidence()),
                etat.qualificationGate(), etat.transferGate(), etat.directQualification(),
                etat.qualifyingEvidenceCount(), etat.recentStrongNegativeCount(),
                etat.visibleProgress(), etat.levelCycleId(), engineVersion, raison);
    }

    /** Le code de raison d'un état isolé, sans sa projection de domaine. */
    public RecommendationReasonCode raisonIsolee(ProgressionSnapshot etat) {
        if (etat.stateKey().stateType() == ProgressionStateType.PRODUCTIVE_SKILL) {
            return raison(etat);
        }
        return switch (etat.status()) {
            case WATCH -> RecommendationReasonCode.WATCH_RECHECK;
            case NOT_EVALUATED -> RecommendationReasonCode.MISSING_ASSESSMENT;
            case SOLID -> RecommendationReasonCode.NEXT_LEVEL_UNLOCKED;
            default -> RecommendationReasonCode.ACTIVE_LEVEL_NOT_CLEARED;
        };
    }

    /** {@code null} se lit « jamais mesuré », pas « 0,0000 ». */
    private static String format(Double valeur) {
        return valeur == null ? "null" : String.format("%.4f", valeur);
    }

    /** Le domaine d'un état réceptif, pour les logs. */
    static SkillSection section(ProgressionSnapshot etat) {
        return etat.stateKey().section();
    }
}
