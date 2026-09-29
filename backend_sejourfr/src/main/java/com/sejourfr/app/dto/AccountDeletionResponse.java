package com.sejourfr.app.dto;

/**
 * Réponse de {@code DELETE /api/account}. La suppression côté serveur a
 * toujours lieu ({@code deleted=true}) ; les champs suivants servent à informer
 * l'utilisateur d'une action manuelle restante sur son abonnement.
 *
 * @param deleted              toujours {@code true} si l'appel aboutit (idempotent).
 * @param hasActiveSubscription un abonnement couvrant existait au moment de la
 *                              suppression — l'app le signale à l'utilisateur.
 * @param subscriptionProvider {@code STRIPE} / {@code APPLE} / {@code GOOGLE} ou
 *                              {@code null}.
 * @param manualActionMessage  message à afficher quand la résiliation ne peut
 *                              pas se faire côté serveur (Apple/Google) ;
 *                              {@code null} sinon (Stripe résilié automatiquement
 *                              ou pas d'abonnement récurrent).
 */
public record AccountDeletionResponse(
        boolean deleted,
        boolean hasActiveSubscription,
        String subscriptionProvider,
        String manualActionMessage
) {
    public static AccountDeletionResponse alreadyDeleted() {
        return new AccountDeletionResponse(true, false, null, null);
    }
}
