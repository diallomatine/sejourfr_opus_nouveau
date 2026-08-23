package com.sejourfr.app.progression.engine;

import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;

/**
 * <b>La machine à états, en fonctions pures</b> (V4.2 §14, §15).
 *
 * <p>🛑 <b>Tous les seuils viennent de {@code thresholdProfile(stateType)}</b>,
 * jamais d'une constante écrite ici (invariants I14, I32). CO/CE agrège un
 * {@code result} corrigé du hasard, EE/EO des observations IA {@code 0/0.5/1} :
 * les deux échelles n'ont pas de commune mesure, et lire le profil de l'une pour
 * l'autre est la faute la plus facile à commettre et la plus dure à voir.
 *
 * <p>Deux hystérésis, pour la même raison — éviter le yo-yo :
 * <ul>
 *   <li>un {@code PROGRESSING} ne retombe en {@code FRAGILE} que sous
 *       {@code progressOut}, pas dès qu'il repasse sous {@code progressIn} ;</li>
 *   <li>un {@code SOLID} ne se perd <b>jamais</b> par franchissement marginal du
 *       seuil d'entrée : il ne sort que par le chemin {@code WATCH}, qui exige
 *       de vraies contradictions.</li>
 * </ul>
 *
 * <p>Et une non-règle qui compte autant : <b>la simple baisse de confiance avec
 * le temps ne rétrograde rien</b> (§11.2, invariant I13). Ne plus s'entraîner
 * n'est pas se tromper.
 */
final class ProgressionStateMachine {

    private ProgressionStateMachine() {
    }

    /**
     * L'état après cette preuve.
     *
     * @param precedent               l'état avant — c'est lui qui porte les
     *                                hystérésis.
     * @param contradictionQuiArrive  cette preuve-ci est-elle une contradiction
     *                                forte indépendante ? C'est ce qui fait
     *                                basculer un {@code SOLID} en
     *                                {@code WATCH}, une fois.
     * @param contradictionsRecentes  combien de contradictions fortes
     *                                indépendantes dans la fenêtre (§15).
     */
    static ProgressionStatus transition(ProgressionStatus precedent,
                                        ProgressionStateType stateType,
                                        ProgressionConfig config,
                                        Double masteryScore,
                                        double confidence,
                                        boolean qualificationGate,
                                        boolean transferGate,
                                        boolean contradictionQuiArrive,
                                        int contradictionsRecentes) {
        if (masteryScore == null) {
            return ProgressionStatus.NOT_EVALUATED;
        }
        ProgressionConfig.ThresholdProfile profil = config.thresholdProfile(stateType);
        boolean solide = conditionsSolid(
                stateType, profil, masteryScore, confidence, qualificationGate, transferGate);

        if (precedent == ProgressionStatus.SOLID && contradictionQuiArrive) {
            return ProgressionStatus.WATCH;
        }

        if (precedent == ProgressionStatus.WATCH) {
            if (solide) {
                // §15 : une vérification forte positive restaure l'acquis, et
                // réactive du même coup les prérequis qu'il inférait.
                return ProgressionStatus.SOLID;
            }
            if (sortieDeWatch(config, stateType, profil, masteryScore,
                    confidence, contradictionsRecentes)) {
                return masteryScore < profil.fragileMax()
                        ? ProgressionStatus.FRAGILE
                        : ProgressionStatus.PROGRESSING;
            }
            return ProgressionStatus.WATCH;
        }

        if (solide) {
            return ProgressionStatus.SOLID;
        }
        if (precedent == ProgressionStatus.SOLID) {
            // §14.7 — un SOLID ne se perd pas parce que le score a glissé d'un
            // cheveu sous le seuil d'entrée. Il faut passer par WATCH.
            return ProgressionStatus.SOLID;
        }

        if (stateType == ProgressionStateType.PRODUCTIVE_SKILL) {
            ProgressionConfig.ProductiveThresholds productif =
                    (ProgressionConfig.ProductiveThresholds) profil;
            if (!transferGate
                    && masteryScore >= productif.readyForReassessment()
                    && confidence >= productif.minConfidenceForReady()) {
                return ProgressionStatus.READY_FOR_REASSESSMENT;
            }
        }

        if (masteryScore >= profil.progressIn()
                && confidence >= profil.minConfidenceForProgress()) {
            return ProgressionStatus.PROGRESSING;
        }

        if (precedent == ProgressionStatus.PROGRESSING
                || precedent == ProgressionStatus.READY_FOR_REASSESSMENT) {
            // §14.6 — on ne redescend que sous progressOut, et seulement sur une
            // nouvelle preuve directe (c'est le cas : on est appelé sur une preuve).
            return masteryScore < profil.progressOut() ? ProgressionStatus.FRAGILE : precedent;
        }
        return ProgressionStatus.FRAGILE;
    }

    /** §14.4 (CO/CE) et §14.5 (EE/EO) — score, confiance <b>et</b> gate. */
    private static boolean conditionsSolid(ProgressionStateType stateType,
                                           ProgressionConfig.ThresholdProfile profil,
                                           double masteryScore,
                                           double confidence,
                                           boolean qualificationGate,
                                           boolean transferGate) {
        boolean gate = stateType == ProgressionStateType.RECEPTIVE_LEVEL
                ? qualificationGate
                : transferGate;
        return masteryScore >= profil.solidIn()
                && confidence >= profil.minConfidenceForSolid()
                && gate;
    }

    /**
     * §15 — pour rétrograder réellement, il faut <b>trois</b> choses ensemble :
     * assez de contradictions indépendantes, un score réellement retombé, et
     * assez de confiance pour que ce score veuille dire quelque chose.
     *
     * <p>La condition de confiance n'est pas une formalité : sans elle, deux
     * mauvais résultats sur une base de preuves mince suffiraient à défaire un
     * acquis, alors qu'ils ne mesurent pas grand-chose.
     */
    private static boolean sortieDeWatch(ProgressionConfig config,
                                         ProgressionStateType stateType,
                                         ProgressionConfig.ThresholdProfile profil,
                                         double masteryScore,
                                         double confidence,
                                         int contradictionsRecentes) {
        ProgressionConfig.StrongEvidence fortes = config.strongEvidence().get(stateType);
        return contradictionsRecentes >= fortes.negativeCountToDowngradeSolid()
                && masteryScore < profil.solidOut()
                && confidence >= profil.minConfidenceForSolid();
    }
}
