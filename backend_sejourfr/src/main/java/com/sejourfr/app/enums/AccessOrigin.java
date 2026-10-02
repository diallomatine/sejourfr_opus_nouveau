package com.sejourfr.app.enums;

/** D'où vient l'état d'accès affiché pour un produit (vue admin seulement, GO §6). */
public enum AccessOrigin {
    PURCHASE_STRIPE("Achat Stripe"),
    PURCHASE_APPLE("Achat Apple"),
    PURCHASE_GOOGLE("Achat Google Play"),
    ADMIN_GRANT("Admin (accès accordé)"),
    ADMIN_REVOKE("Admin (accès retiré)");

    private final String label;

    AccessOrigin(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }

    public static AccessOrigin ofPurchase(SubscriptionSource source) {
        return switch (source) {
            case STRIPE -> PURCHASE_STRIPE;
            case APPLE -> PURCHASE_APPLE;
            case GOOGLE -> PURCHASE_GOOGLE;
        };
    }
}
