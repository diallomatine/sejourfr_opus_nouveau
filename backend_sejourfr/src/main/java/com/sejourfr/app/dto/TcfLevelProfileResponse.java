package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Profil de niveau TCF par épreuve : le DERNIER passage de chacune des 4
 * épreuves (CO / CE / EE / EO) pris indépendamment, plus le niveau global.
 *
 * <p>Le niveau global est le <b>plancher</b> (le plus faible) des épreuves
 * renseignées — jamais une moyenne : c'est la lecture qu'en fait la préfecture
 * pour le TCF IRN. Tous les niveaux sont plafonnés à B2.
 */
public record TcfLevelProfileResponse(
        EpreuveLevel co,
        EpreuveLevel ce,
        EpreuveLevel ee,
        EpreuveLevel eo,
        NiveauCecrl globalLevel
) {
    /**
     * Résultat d'une épreuve. CO/CE renseignent {@code calibratedScore}
     * (100-499) + {@code weightedScore}/{@code maxWeightedScore} (X/50) ;
     * EE/EO renseignent {@code note20} (moyenne /20 du dernier passage).
     * {@code level} est null si l'épreuve n'a jamais été passée / pas encore
     * évaluée.
     */
    public record EpreuveLevel(
            EpreuveType epreuve,
            NiveauCecrl level,
            Integer calibratedScore,
            Integer weightedScore,
            Integer maxWeightedScore,
            BigDecimal note20,
            Instant lastAttemptAt
    ) {
        /** Épreuve jamais passée : niveau et scores à null. */
        public static EpreuveLevel empty(EpreuveType epreuve) {
            return new EpreuveLevel(epreuve, null, null, null, null, null, null);
        }
    }
}
