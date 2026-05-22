package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé de progression d'un user pour un module donné, calculé côté
 * backend. Sert à alimenter l'écran Progression du mobile (hero +
 * 3 stats cards), sans que le front ait à agréger lui-même.
 *
 * <p>Une seule des deux structures (civique / tcf) est renseignée selon le
 * module demandé — l'autre est null. Mutuellement exclusif.
 */
public record ProgressionSummaryResponse(
        Module module,
        CiviqueProgression civique,
        TcfProgression tcf
) {

    /**
     * Métriques Civique — alignées sur les seuils officiels de l'examen :
     * 40 questions, seuil 32 sur l'examen blanc complet ; les examens
     * thématiques (20 Q / 1 thème) sont passés avec un seuil 16.
     *
     * <ul>
     *   <li>{@code fullExamCount} : nb d'examens blancs complets finis (themeId NULL).</li>
     *   <li>{@code latestScore} : score (0..40) du dernier examen blanc — null si jamais tenté.</li>
     *   <li>{@code bestScore} : meilleur score (0..40) sur l'historique.</li>
     *   <li>{@code examTotal} / {@code examThreshold} : constantes 40 / 32 exposées
     *       pour éviter les magic numbers côté UI.</li>
     *   <li>{@code themesConsolidated} : nb de thèmes avec ≥1 examen thématique ≥ 16/20.</li>
     *   <li>{@code themesTotal} : total thèmes officiels du module (= 5).</li>
     * </ul>
     */
    public record CiviqueProgression(
            int fullExamCount,
            Integer latestScore,
            Integer bestScore,
            int examTotal,
            int examThreshold,
            int themesConsolidated,
            int themesTotal
    ) {
    }

    /**
     * Métriques TCF — couvre les 3 épreuves QCM (CO, CE, STRUCTURE) et les
     * 2 productions IA (EE, EO).
     *
     * <ul>
     *   <li>{@code qcmEpreuvesTried} / {@code qcmEpreuvesTotal} : nb d'épreuves QCM
     *       avec ≥1 examen blanc fini, sur 3 (CO + CE + STRUCTURE).</li>
     *   <li>{@code productionsEvaluated} / {@code productionsTotal} : nb d'épreuves
     *       productives avec ≥1 submission EVALUATED, sur 2.</li>
     *   <li>{@code bestWeightedScore} / {@code bestWeightedMax} : meilleur score
     *       pondéré observé sur les examens module (typiquement /50). Null si aucun.</li>
     *   <li>{@code lastFullExam} : dernier examen blanc complet TCF (TCF_COMPLET)
     *       du user, avec breakdown des 4 épreuves IRN. Null si l'utilisateur
     *       n'en a jamais lancé — le hero mobile affiche alors une CTA pour
     *       en démarrer un. Cf. {@link LastFullExam}.</li>
     *   <li>{@code targetLevel} : niveau cible du user (dérivé de targetProcedure).
     *       Null si l'onboarding parcours n'a pas été complété.</li>
     * </ul>
     */
    public record TcfProgression(
            int qcmEpreuvesTried,
            int qcmEpreuvesTotal,
            int productionsEvaluated,
            int productionsTotal,
            Integer bestWeightedScore,
            Integer bestWeightedMax,
            LastFullExam lastFullExam,
            NiveauCecrl targetLevel
    ) {
    }

    /**
     * Snapshot du dernier examen blanc complet TCF (TCF_COMPLET) d'un user.
     *
     * <p><b>Statut</b> :
     * <ul>
     *   <li>{@code IN_PROGRESS} : sub-attempts pas tous finis (au moins 1 sans
     *       {@code finishedAt}). Mobile propose "Reprendre".</li>
     *   <li>{@code PENDING_EVALUATIONS} : tous finis mais éval IA EE/EO encore
     *       en cours (ou QCM sans weightedScore). Mobile affiche un loader.</li>
     *   <li>{@code COMPLETED} : tout finalisé. {@code finalLevel} est posé.</li>
     * </ul>
     *
     * <p><b>Niveau global</b> : {@code finalLevel} = niveau plancher des 4
     * épreuves IRN (CO + CE + EE + EO). Aligné sur la règle prefecture :
     * pour valider une procédure CSP/CR/NAT, il faut atteindre le niveau
     * requis sur chacune des 4 épreuves. Le réel TCF IRN ne délivre pas de
     * "niveau global" — on calcule ce plancher pour signaler à l'utilisateur
     * ce que sa procédure exige effectivement.
     *
     * <p>Les 4 niveaux par épreuve sont exposés pour permettre au mobile
     * d'afficher un breakdown ("CO B2 · CE B2 · EE A2 · EO B2") et de
     * signaler l'épreuve qui limite.
     */
    public record LastFullExam(
            UUID attemptId,
            Instant finishedAt,
            String status,
            NiveauCecrl finalLevel,
            NiveauCecrl coLevel,
            NiveauCecrl ceLevel,
            NiveauCecrl eeLevel,
            NiveauCecrl eoLevel
    ) {
    }
}
