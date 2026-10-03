package com.sejourfr.app.enums;

/**
 * Tris de la liste admin des productions. Chacun est complété par
 * {@code submitted_at DESC, id DESC} : l'ordre est total et stable d'une page
 * à l'autre. Les lignes sans niveau finissent toujours après les autres.
 */
public enum AdminProductionTri {
    DATE_DESC,
    DATE_ASC,
    NIVEAU_DESC,
    NIVEAU_ASC,
    EPREUVE
}
