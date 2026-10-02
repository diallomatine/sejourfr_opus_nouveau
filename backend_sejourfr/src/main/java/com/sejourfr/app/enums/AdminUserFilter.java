package com.sejourfr.app.enums;

/** Filtres de la liste admin des utilisateurs (spec §4). Évalués sur l'accès EFFECTIF. */
public enum AdminUserFilter {
    ALL,
    TCF_ACTIVE,
    CIVIQUE_ACTIVE,
    NO_ACTIVE_ACCESS,
    EXPIRED,
    MANUAL_ACCESS
}
