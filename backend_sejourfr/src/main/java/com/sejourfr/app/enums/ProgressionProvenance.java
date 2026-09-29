package com.sejourfr.app.enums;

/**
 * D'où vient un examen listé sur un écran de progression.
 *
 * <p>🛑 Aucun diagnostic n'y figure (arbitrage D1 du 2026-09-24) : ces écrans
 * ne lisent que des <b>examens blancs</b>.
 */
public enum ProgressionProvenance {

    /** TCF : examen blanc de l'épreuve, passé seul. */
    EPREUVE_SEULE,

    /** TCF : l'épreuve jouée à l'intérieur d'un examen blanc complet. */
    EXAMEN_COMPLET,

    /** Civique : examen de thème (20 questions, format SejourFR). */
    EXAMEN_THEME,

    /** Civique : examen global (40 questions, format officiel). */
    EXAMEN_GLOBAL
}
