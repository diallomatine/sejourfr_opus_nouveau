package com.sejourfr.app.enums;

/**
 * Quel écran de rapport ouvre le « Voir → » d'une ligne d'examen.
 *
 * <p>🛑 Servi pour que la destination ne se déduise jamais d'une route ni
 * d'une épreuve côté front (patron de {@code PlanDomainAssessmentDto}).
 */
public enum ProgressionRapport {

    /** Rapport d'une session QCM (CO, CE, civique) — l'attempt lui-même. */
    QCM,

    /** Bilan d'une session de production (EE, EO) passée seule. */
    PRODUCTION,

    /** Bilan d'un examen blanc TCF complet — l'attempt PARENT. */
    EXAMEN_COMPLET
}
