package com.sejourfr.app.enums;

/**
 * Ou se situe une etape du chemin par rapport a l'avancee du candidat.
 *
 * <p>Un enum plutot que deux booleens : « faite » et « en cours » ne peuvent pas
 * etre vraies ensemble, et un couple de booleens laisserait cet etat impossible
 * representable.
 */
public enum PlanPathStepStatus {

    /** Deja franchie. */
    DONE,

    /** L'etape en cours ; il n'y en a jamais plus d'une. */
    CURRENT,

    /** A venir. */
    UPCOMING
}
