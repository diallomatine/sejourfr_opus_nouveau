package com.sejourfr.app.dto;

/**
 * Réponse de {@code POST /api/billing/cancel}. Deux variantes selon la source
 * de l'abonnement :
 *
 * <ul>
 *   <li>{@code action = "DONE"} — annulation traitée côté serveur (Stripe).
 *       L'app affiche {@code message} et rafraîchit le statut. Premium reste
 *       ouvert jusqu'à {@code endsAt} (cancel_at_period_end), puis bascule
 *       EXPIRED via le webhook Stripe.</li>
 *   <li>{@code action = "REDIRECT"} — Apple et Google n'autorisent pas
 *       l'annulation serveur. L'app doit ouvrir {@code redirectUrl} dans le
 *       navigateur / les Settings du store. Le statut local NE change PAS ici
 *       — c'est le webhook (Apple {@code DID_CHANGE_RENEWAL_STATUS}, Google
 *       RTDN) qui tranchera quand / si l'user confirme côté store.</li>
 * </ul>
 */
public record CancelSubscriptionResponse(
        String action,
        String message,
        String redirectUrl
) {
    public static CancelSubscriptionResponse done(String message) {
        return new CancelSubscriptionResponse("DONE", message, null);
    }

    public static CancelSubscriptionResponse redirect(String url, String message) {
        return new CancelSubscriptionResponse("REDIRECT", message, url);
    }
}
