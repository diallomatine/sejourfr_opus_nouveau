package com.sejourfr.app.enums;

/**
 * Provenance des frais d'un achat ({@code user_subscriptions.fee_source}).
 * {@link #ACTUAL} : lus sur la {@code balance_transaction} Stripe.
 * {@link #ESTIMATED} : formule des regles de revenus (repli Stripe, et toujours
 * pour les stores, faute de rapprochement avec leurs rapports).
 */
public enum FeeSource {
    ACTUAL,
    ESTIMATED
}
