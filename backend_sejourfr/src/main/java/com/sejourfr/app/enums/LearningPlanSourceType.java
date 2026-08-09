package com.sejourfr.app.enums;

/**
 * Source d'une observation du Plan. CO/CE sont reserves des maintenant pour
 * que leur integration future ne demande pas de remodeler l'historique.
 */
public enum LearningPlanSourceType {
    DIAGNOSTIC_EE,
    DIAGNOSTIC_EO,
    PRODUCTION_EE,
    PRODUCTION_EO,
    SKILL_TRAINING,
    TCF_CO,
    TCF_CE
}
