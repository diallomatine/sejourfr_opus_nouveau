package com.sejourfr.app.enums;

/**
 * Modules auxquels un plan donne accès :
 * - NONE     : plan gratuit (aucun accès Premium)
 * - CIVIQUE  : accès aux contenus civique uniquement (CSP / CR / NAT)
 * - INTEGRAL : accès civique + TCF (formule complète)
 */
public enum ModuleAccess {
    NONE,
    CIVIQUE,
    INTEGRAL;

    /** Renvoie true si ce plan donne accès au module civique. */
    public boolean hasCivique() {
        return this == CIVIQUE || this == INTEGRAL;
    }

    /** Renvoie true si ce plan donne accès au module TCF. */
    public boolean hasTcf() {
        return this == INTEGRAL;
    }
}
