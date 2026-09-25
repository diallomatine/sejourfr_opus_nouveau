package com.sejourfr.app.service.email;

/** Ce qu'est devenue une demande d'envoi. */
public enum EmailOutcome {
    /** Parti (ligne SENT). */
    SENT,
    /** Toutes les tentatives immediates ont echoue (ligne FAILED). */
    FAILED,
    /** Ligne PENDING ecrite, l'envoi part sur l'executor email. */
    QUEUED,
    /** L'executor a refuse la tache (ligne FAILED « rejected »). */
    REJECTED,
    /** ENGAGEMENT refuse par la preference du compte. */
    SKIPPED_PREFERENCE,
    /** Destinataire hors liste blanche de dev (ligne SKIPPED). */
    SKIPPED_ALLOWLIST,
    /** Plafond ENGAGEMENT du jour atteint : rien d'ecrit, reevalue demain. */
    CAPPED,
    /** Cle deja occupee (PENDING, SENT ou SKIPPED) : rien d'ecrit. */
    DUPLICATE,
    /** La cle a epuise ses tentatives (1 + relances differees). */
    EXHAUSTED,
    /** Aucun destinataire exploitable. */
    NO_RECIPIENT
}
