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
 * <p>{@link #finalCecrlLevel} est le niveau plancher des 4 sous-épreuves
 * (règle officielle TCF IRN). NULL tant que toutes les évaluations IA
 * (EE/EO) ne sont pas EVALUATED, ou tant que l'examen n'a pas été finalisé.
 */
public record FullTcfExamResponse(
        UUID id,
        Instant startedAt,
        Instant finishedAt,
        NiveauCecrl finalCecrlLevel,
        FullTcfExamStatus status,
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
     * @param cecrlLevel          niveau CECRL atteint sur cette épreuve
     *                            (CO/CE : dérivé du score pondéré, EE/EO : plancher
     *                            des submissions EVALUATED). NULL si pas encore calculable.
     * @param score               CO/CE uniquement : weightedScore (X / maxScore)
     * @param maxScore            CO/CE uniquement
     * @param submissionsCount    EE/EO uniquement : submissions EVALUATED (sur 3 attendues)
     * @param failedSubmissionIds EE/EO uniquement : ids des submissions FAILED — le mobile
     *                            peut les retry via POST /api/production-submissions/{id}/retry
     */
    public record SubAttempt(
            UUID attemptId,
            EpreuveType epreuve,
            Instant finishedAt,
            NiveauCecrl cecrlLevel,
            Integer score,
            Integer maxScore,
            Integer submissionsCount,
            List<UUID> failedSubmissionIds
    ) {
    }
}
