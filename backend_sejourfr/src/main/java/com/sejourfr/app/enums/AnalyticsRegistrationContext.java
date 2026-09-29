package com.sejourfr.app.enums;

/**
 * A quel moment du parcours le visiteur a commence a creer son compte.
 *
 * <p>Repond a « le diagnostic convertit-il mieux que la landing ? ». Porte par
 * l'evenement {@code SIGNUP_STARTED} — l'inscription <i>reussie</i>, elle, se
 * lit sur {@code users.created_at}, jamais sur un evenement.
 */
public enum AnalyticsRegistrationContext {

    /** Depuis une landing, avant tout parcours. */
    LANDING,

    /** Avant d'avoir commence le diagnostic. */
    BEFORE_DIAGNOSTIC,

    /** Au milieu du diagnostic. */
    DURING_DIAGNOSTIC,

    /** Les productions sont faites, le compte est demande pour l'analyse. */
    AFTER_DIAGNOSTIC,

    /** Depuis le rapport de diagnostic. */
    DIAGNOSTIC_REPORT,

    /** Depuis la page tarifs. */
    PRICING,

    /** Depuis l'application mobile. */
    MOBILE_APP,

    /** Contexte non couvert par les precedents. */
    OTHER
}
