package com.sejourfr.app.dto;

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
        /** Lancement réel de la 1re épreuve (CO) — ancre du chrono 90 min.
         *  NULL tant que le candidat n'a pas commencé (hub de progression). */
        Instant timerStartedAt,
        Instant finishedAt,
        NiveauCecrl finalCecrlLevel,
        FullTcfExamStatus status,
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
            boolean locked
    ) {
    }
}
