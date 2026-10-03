package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminProductionContexte;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.EtatSignalement;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionSubmissionSource;

import java.time.Instant;
import java.util.UUID;

/**
 * Une ligne de {@code GET /api/admin/productions} (et l'en-tête de la fiche).
 * DTO propre à l'admin : rien ici n'est ajouté aux DTO candidats.
 *
 * @param niveauObserve niveau observé (TÂCHE) persisté par la dernière
 *                      évaluation — jamais un « niveau final » ; {@code null}
 *                      = aucun niveau (en cours, échec, non évaluable)
 * @param annotee       au moins une note humaine de calibration existe
 */
public record AdminProductionListItemDto(
        UUID id,
        Instant submittedAt,
        UUID userId,
        String userEmail,
        boolean userInternal,
        EpreuveType epreuve,
        int tache,
        ProductionSubmissionSource source,
        AdminProductionContexte contexte,
        String contexteLabel,
        NiveauCecrl niveauObserve,
        AdminProductionStatutIa statutIa,
        String statutIaLabel,
        EtatSignalement etatSignalement,
        String etatSignalementLabel,
        boolean annotee
) {
}
