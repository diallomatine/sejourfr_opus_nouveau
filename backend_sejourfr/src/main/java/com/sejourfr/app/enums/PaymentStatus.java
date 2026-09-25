package com.sejourfr.app.enums;

/**
 * Etat d'ENCAISSEMENT d'un achat ({@code user_subscriptions.payment_status}),
 * distinct du statut d'ACCES ({@link SubscriptionStatus}).
 *
 * <p>Une ligne n'est creee qu'une fois le paiement encaisse (Stripe
 * {@code payment_status = paid}, JWS Apple verifie, Play {@code purchaseState = 0}) :
 * il n'existe donc pas d'etat « en attente ». Un remboursement partiel laisse
 * l'acces ouvert ; seul un remboursement total le retire. {@code null} = achat
 * anterieur a la mesure.
 */
public enum PaymentStatus {
    PAID,
    PARTIALLY_REFUNDED,
    REFUNDED
}
