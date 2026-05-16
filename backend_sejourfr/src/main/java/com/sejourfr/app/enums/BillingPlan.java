package com.sejourfr.app.enums;

/**
 * Plans payants commercialisés via Stripe (Payment Links one-shot).
 * Mappés vers les codes Plan en base.
 */
public enum BillingPlan {
    CIVIQUE_3MOIS("CIVIQUE_3MOIS"),
    INTEGRAL_3MOIS("INTEGRAL_3MOIS");

    private final String planCode;

    BillingPlan(String planCode) {
        this.planCode = planCode;
    }

    public String planCode() {
        return planCode;
    }
}
