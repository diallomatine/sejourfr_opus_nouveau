package com.sejourfr.app.enums;

/**
 * Plans facturés via Stripe. Mappés vers les codes Plan en base
 * (PREMIUM_MONTHLY / PREMIUM_YEARLY).
 */
public enum BillingPlan {
    MENSUEL("PREMIUM_MONTHLY"),
    ANNUEL("PREMIUM_YEARLY");

    private final String planCode;

    BillingPlan(String planCode) {
        this.planCode = planCode;
    }

    public String planCode() {
        return planCode;
    }
}
