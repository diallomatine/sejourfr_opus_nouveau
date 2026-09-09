package com.sejourfr.app.progression.domain;

/**
 * Pourquoi le Plan a recommande cette action (V4.2 §46).
 *
 * <p>Ce code est loggue avec l'etat complet qui l'a produit, pour qu'on puisse
 * repondre a « pourquoi cette recommandation ? » sans rejouer le moteur.
 */
public enum RecommendationReasonCode {

    /** Le palier actif du domaine n'est ni SOLID ni satisfait par prerequis. */
    ACTIVE_LEVEL_NOT_CLEARED,

    /** Palier considere acquis via une qualification directe superieure (§18). */
    VALIDATED_VIA_HIGHER_LEVEL,

    /** Competence de production sous le seuil de progression. */
    SKILL_FRAGILE,

    /** Competence prete a etre verifiee sur une vraie tache (§14.3). */
    READY_FOR_REASSESSMENT,

    /** Verification ciblee d'un acquis contredit une fois (§15). */
    WATCH_RECHECK,

    /** Domaine jamais mesure : le diagnostic ameliorerait la personnalisation. */
    MISSING_ASSESSMENT,

    /** Le palier vient d'etre confirme, le cycle suivant demarre (§35). */
    NEXT_LEVEL_UNLOCKED
}
