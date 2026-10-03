package com.sejourfr.app.enums;

/**
 * Périodes prédéfinies de la liste admin des productions, en jours
 * Europe/Paris glissants, aujourd'hui inclus. Exclusif de {@code from}/{@code to}.
 */
public enum AdminProductionPeriode {
    TODAY(1),
    LAST_7_DAYS(7),
    LAST_30_DAYS(30);

    private final int jours;

    AdminProductionPeriode(int jours) {
        this.jours = jours;
    }

    public int jours() {
        return jours;
    }
}
