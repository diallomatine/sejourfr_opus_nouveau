package com.sejourfr.app.enums;

/**
 * Filtre « Niveau » de la liste admin des productions : le niveau observé
 * (tâche) persisté par la dernière évaluation. Seules les valeurs réellement
 * produites (la notation plafonne à B2). {@code SANS_NIVEAU} = aucun niveau
 * (en cours, échec, non évaluable) — jamais confondu avec A1.
 */
public enum AdminProductionNiveauFiltre {
    A1_NON_ATTEINT,
    A1,
    A2,
    B1,
    B2,
    SANS_NIVEAU
}
