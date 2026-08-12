package com.sejourfr.app.enums;

/**
 * Nature d'un événement agrégé d'audience ou de funnel. Aucune constante ne
 * transporte d'identifiant de visiteur : les compteurs restent anonymes.
 */
public enum PageViewEvent {
    /** La page a été affichée. */
    VIEW,
    /** L'appel à l'action principal a été cliqué. */
    CTA,
    DIAGNOSTIC_VIEWED,
    DIAGNOSTIC_STARTED,
    DIAGNOSTIC_WRITTEN_COMPLETED,
    DIAGNOSTIC_ORAL_COMPLETED,
    DIAGNOSTIC_COMPLETED,
    DIAGNOSTIC_RESULT_VIEWED,
    /**
     * Le visiteur a produit ses deux réponses sans compte et atteint l'écran qui
     * en demande un. C'est LA mesure de conversion du parcours invité : tout ce
     * qui est compté avant est joué hors base, cet événement est le premier
     * point où l'on sait combien de visiteurs vont jusqu'au bout.
     */
    DIAGNOSTIC_ACCOUNT_REQUIRED,
    PLAN_OPENED,
    PLAN_RECOMMENDED_EXERCISE_STARTED,
    SOCIAL_LANDING_DIAGNOSTIC_CLICKED,
    DIAGNOSTIC_TO_PREMIUM_CLICKED
}
