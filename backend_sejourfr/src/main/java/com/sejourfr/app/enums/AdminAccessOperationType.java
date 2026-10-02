package com.sejourfr.app.enums;

/**
 * Action admin sur l'accès d'un compte (spec §2.6). Chaque action est traduite
 * en décisions GRANT / REVOKE par {@code AccessOverridePlanner} et tracée
 * comme UNE ligne de {@code admin_access_operations}.
 */
public enum AdminAccessOperationType {
    GRANT("Donner un accès"),
    EXTEND("Prolonger"),
    SHORTEN("Raccourcir"),
    END("Terminer"),
    REACTIVATE("Réactiver"),
    CORRECT_PRODUCT("Corriger le produit");

    private final String label;

    AdminAccessOperationType(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
