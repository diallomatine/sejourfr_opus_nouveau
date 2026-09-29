package com.sejourfr.app.enums;

/**
 * Origine d'un {@code UserSubscription}. UserSubscription doit être la source
 * de vérité unique du statut Premium — alimentée par 3 canaux qui ne doivent
 * jamais se contredire. Le {@code source} indique qui a payé, jamais ce que
 * l'app affiche : c'est l'agrégateur ({@code SubscriptionStatusService}) qui
 * tranche en cas de cumul.
 *
 * <ul>
 *   <li>{@code STRIPE} — paiement web (Checkout Sessions / Payment Links).</li>
 *   <li>{@code APPLE}  — achat iOS via App Store (StoreKit / IAP).</li>
 *   <li>{@code GOOGLE} — achat Android via Google Play Billing.</li>
 * </ul>
 *
 * <p>Sert aussi de discriminant dans {@code processed_external_events.provider}
 * pour l'idempotence des webhooks. Mapping conventionnel :
 * {@link #name()} en lowercase ({@code "stripe"} / {@code "apple"} / {@code "google"}).
 */
public enum SubscriptionSource {
    STRIPE,
    APPLE,
    GOOGLE;

    /** Provider key utilisée dans {@code processed_external_events.provider}. */
    public String providerKey() {
        return name().toLowerCase();
    }
}
