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
    PLAN_OPENED,
    PLAN_RECOMMENDED_EXERCISE_STARTED,
    SOCIAL_LANDING_DIAGNOSTIC_CLICKED,
    DIAGNOSTIC_TO_PREMIUM_CLICKED
}
