package com.sejourfr.app.enums;

/** Pourquoi le candidat qui demandait l'examinateur s'enregistre seul (V090, {@code realtime_fallbacks}). */
public enum RealtimeFallbackReason {
    /** Plus de session temps réel sur le pass (ou pass non éligible). */
    QUOTA,
    /** Fournisseur non configuré (clé absente). */
    NOT_CONFIGURED,
    /** Émission du token refusée par le fournisseur. */
    MINT_FAILED,
    /** Reprise après coupure : émission du token de reprise refusée. */
    RESUME_MINT_FAILED
}
