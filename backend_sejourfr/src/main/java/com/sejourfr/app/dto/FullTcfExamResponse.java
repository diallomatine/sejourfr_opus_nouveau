package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ContinuiteSimulation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Vue complète d'un examen blanc TCF (les 4 épreuves enchaînées : CO + CE +
 * EE + EO). Le parent porte {@code epreuve = TCF_COMPLET} et n'a pas de
 * questions propres — chaque sous-attempt vit indépendamment et est référencé
 * dans {@link #subAttempts}.
 *
 * <p>{@link #finalCecrlLevel} est le niveau plancher des sous-épreuves
 * <b>réellement passées</b> (règle officielle TCF IRN). NULL tant que toutes
 * les évaluations IA (EE/EO) ne sont pas EVALUATED, ou tant que l'examen n'a
 * pas été finalisé. Sont hors périmètre : une épreuve {@link SubAttempt#locked
 * verrouillée} par le freemium (jamais passée) et une épreuve dont le niveau
 * est resté inconnu (évaluations IA échouées). Le périmètre effectif est
 * publié via {@link #epreuvesCountedInFinalLevel} / {@link #finalLevelPartial}
 * — les fronts doivent s'en servir plutôt que d'affirmer « le plus bas de tes
 * 4 épreuves » en dur.
 */
public record FullTcfExamResponse(
        UUID id,
        Instant startedAt,
        /** Lancement réel de la 1re épreuve — <b>trace du début de l'examen</b>,
         *  plus l'ancre d'un décompte : l'enveloppe globale de 90 min a été
         *  supprimée (chaque épreuve porte sa durée, rien ne se transfère de
         *  l'une à l'autre, et l'abandon-reprise entre épreuves est supporté).
         *  Les fronts n'en dérivent aucun compte à rebours — ils lisent
         *  {@link SubAttempt#timerStartedAt} / {@link SubAttempt#deadlineAt}.
         *  NULL tant que le candidat n'a pas commencé (hub de progression). */
        Instant timerStartedAt,
        Instant finishedAt,
        NiveauCecrl finalCecrlLevel,
        FullTcfExamStatus status,
        /** Examen enchaîné d'une traite, ou repris entre plusieurs épreuves ?
         *  Dérivé serveur, jamais persisté (cf. {@link ContinuiteSimulation}).
         *  NULL tant que l'examen n'est pas terminé — la question ne se pose
         *  qu'au moment de restituer le résultat. À ne pas confondre avec
         *  {@link #finalLevelPartial}, qui dit tout autre chose : sur combien
         *  d'épreuves porte le niveau. */
        ContinuiteSimulation continuite,
        /** Nombre d'épreuves qui portent un niveau et entrent réellement dans
         *  le plancher {@link #finalCecrlLevel} (0..{@link #epreuvesExpected}). */
        int epreuvesCountedInFinalLevel,
        /** Épreuves attendues dans un examen complet : toujours 4 (CO/CE/EE/EO).
         *  Publié pour que les fronts ne codent pas la constante en dur. */
        int epreuvesExpected,
        /** {@code epreuvesCountedInFinalLevel < epreuvesExpected} : le plancher
         *  ne porte pas sur les 4 épreuves — bilan PARTIEL. Les fronts doivent
         *  alors dire sur combien d'épreuves porte le niveau, et ne pas
         *  présenter ce bilan comme un résultat d'examen complet. */
        boolean finalLevelPartial,
        List<SubAttempt> subAttempts
) {

    /**
     * Statut global de l'examen blanc complet :
     * <ul>
     *   <li>{@code IN_PROGRESS} : au moins un sous-attempt n'est pas encore terminé.</li>
     *   <li>{@code PENDING_EVALUATIONS} : tous les sous-attempts sont terminés, mais
     *       au moins une évaluation IA EE/EO est toujours en cours.</li>
     *   <li>{@code COMPLETED} : tout est terminé et évalué, {@code finalCecrlLevel} est posé.</li>
     * </ul>
     */
    public enum FullTcfExamStatus {
        IN_PROGRESS,
        PENDING_EVALUATIONS,
        COMPLETED
    }

    /**
     * Description compacte d'un des 4 sous-attempts (TCF_CO, TCF_CE, TCF_EE,
     * TCF_EO) avec son état d'avancement et son résultat partiel.
     *
     * @param attemptId           id du sous-attempt
     * @param epreuve             TCF_CO | TCF_CE | TCF_EE | TCF_EO
     * @param finishedAt          null tant que non terminé
     * @param cecrlLevel          niveau CECRL atteint sur cette épreuve. CO/CE :
     *                            dérivé du score pondéré. EE/EO : moyenne pondérée
     *                            des compétences des 3 tâches
     *                            ({@code ProductionBilanService.bilanEpreuve}) —
     *                            ce n'est plus le plancher des submissions
     *                            EVALUATED. NULL quand le niveau n'est pas
     *                            calculable : évaluations encore en vol, en échec
     *                            (cf. {@code failedSubmissionIds}), ou épreuve
     *                            {@code locked}. Un NULL n'est jamais un mauvais
     *                            niveau — c'est un niveau inconnu.
     * @param score               CO/CE uniquement : weightedScore (X / maxScore)
     * @param maxScore            CO/CE uniquement
     * @param submissionsCount    EE/EO uniquement : submissions EVALUATED (sur 3 attendues)
     * @param failedSubmissionIds EE/EO uniquement : ids des submissions FAILED — le mobile
     *                            peut les retry via POST /api/production-submissions/{id}/retry
     * @param locked              EE/EO uniquement : true quand l'épreuve est verrouillée
     *                            (compte gratuit ayant déjà consommé l'EE/EO offerte une
     *                            fois). L'épreuve est pré-terminée et n'a <b>pas</b> de
     *                            niveau ({@code cecrlLevel} NULL) : elle est exclue du
     *                            plancher global. Un verrou commercial n'est pas un
     *                            verdict de langue. Les fronts affichent un cadenas +
     *                            invitation à l'abonnement. Toujours false pour CO/CE.
     * @param timeLimitSeconds    durée de CETTE épreuve, en secondes (CO 1200, CE 2100,
     *                            EE 1800). <b>NULL pour l'expression orale</b>, qui n'a
     *                            volontairement pas de chrono d'épreuve : son temps se
     *                            compte par tâche, et ne démarre qu'au lancement de la
     *                            tâche ({@code production_tasks.dureeMaxSec}). C'est le
     *                            <b>seul</b> endroit où lire la durée d'une épreuve :
     *                            les fronts affichent « CE · 35 min » depuis ce champ,
     *                            jamais depuis une constante locale (elles avaient déjà
     *                            divergé — 30 min dans un écran, 35 dans un autre).
     * @param timerStartedAt      instant où le candidat a <b>lancé</b> l'épreuve
     *                            ({@code POST /api/full-tcf-exams/{id}/begin}). NULL tant
     *                            qu'elle n'a pas été lancée : les 4 sous-attempts sont
     *                            créés d'un bloc au démarrage de l'examen, leur
     *                            {@code startedAt} ne dit donc rien du moment où le
     *                            candidat les ouvre. Tant qu'il est NULL, l'épreuve n'a
     *                            pas d'échéance.
     * @param deadlineAt          échéance effective = {@code timerStartedAt +
     *                            timeLimitSeconds}, calculée serveur pour que les fronts
     *                            n'aient pas à la recomposer. NULL quand l'épreuve n'a
     *                            pas de chrono (EO) ou n'a pas encore été lancée. Le
     *                            temps court pendant l'absence : quitter ne suspend
     *                            rien, et passé cette échéance l'épreuve est clôturée
     *                            automatiquement avec ce qui avait été enregistré.
     */
    public record SubAttempt(
            UUID attemptId,
            EpreuveType epreuve,
            Instant finishedAt,
            NiveauCecrl cecrlLevel,
            Integer score,
            Integer maxScore,
            Integer submissionsCount,
            List<UUID> failedSubmissionIds,
            boolean locked,
            Integer timeLimitSeconds,
            Instant timerStartedAt,
            Instant deadlineAt
    ) {
    }
}
