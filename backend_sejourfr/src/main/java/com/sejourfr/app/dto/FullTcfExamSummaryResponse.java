package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.time.Instant;
import java.util.UUID;

/**
 * Résumé d'un examen blanc TCF complet pour les listes d'historique
 * ({@code GET /api/me/full-tcf-exams}). Sans les détails par sous-attempt
 * pour rester compact — le détail s'obtient via {@code GET /api/full-tcf-exams/{id}}.
 */
public record FullTcfExamSummaryResponse(
        UUID id,
        Instant startedAt,
        Instant finishedAt,
        NiveauCecrl finalCecrlLevel,
        FullTcfExamResponse.FullTcfExamStatus status
) {
}
