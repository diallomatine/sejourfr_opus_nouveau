package com.sejourfr.app.enums;

public enum BillingCycle {
    NONE,
    THREE_MONTHS,
    // Conservés pour compatibilité historique (anciens plans MONTHLY/YEARLY).
    // Les nouveaux plans utilisent THREE_MONTHS (paiement one-shot).
    MONTHLY,
    YEARLY
}
