package com.sejourfr.app.enums;

/**
 * L'unité d'une échelle des écrans de progression — ce que « / max » veut dire.
 *
 * <p>🛑 Trois échelles qui ne se comparent pas et ne se moyennent jamais entre
 * elles (d'où l'absence de tout score global TCF, arbitrage D6 du 2026-09-24).
 */
public enum ProgressionUnite {

    /**
     * CO / CE : <b>score de PROGRESSION</b> 100-499
     * ({@code TcfLevelEstimatorService.calibratedScore}). 🛑 Aucune bande CECRL :
     * aucun palier ne dérive de ce nombre depuis le 2026-09-20.
     */
    PROGRESSION_499,

    /**
     * EE / EO : <b>note d'épreuve /20</b>, échelle officielle du TCF, avec ses
     * bandes officielles ({@link BandeNoteTcf}).
     */
    NOTE_20,

    /**
     * Civique : <b>bonnes réponses</b> sur les questions de l'examen
     * (20 pour un examen de thème, 40 pour un examen global).
     */
    QUESTIONS
}
