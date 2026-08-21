package com.sejourfr.app.enums;

/**
 * Les etapes du funnel d'acquisition, dans l'ordre du parcours reel.
 *
 * <p>Leur origine differe volontairement : {@link #SIGNUP},
 * {@link #DIAGNOSTIC_STARTED}, {@link #DIAGNOSTIC_COMPLETED} et
 * {@link #PURCHASE} se lisent sur les vraies tables ; les trois autres sont des
 * {@link FunnelEvent}. C'est la meme echelle pour le lecteur, deux sources pour
 * le serveur — et c'est ce qui rend les chiffres vrais plutot qu'estimes.
 */
public enum FunnelStage {

    /** Compte cree (table {@code users}). */
    SIGNUP,

    /** Session de diagnostic creee (table {@code diagnostic_sessions}). */
    DIAGNOSTIC_STARTED,

    /** Session de diagnostic terminee et analysee. */
    DIAGNOSTIC_COMPLETED,

    /** Ecran Premium affiche (evenement client). */
    PAYWALL_VIEWED,

    /** Clic sur l'achat d'un pass (evenement client). */
    SUBSCRIBE_CLICKED,

    /** Session de paiement creee (evenement pose par le serveur). */
    CHECKOUT_STARTED,

    /** Au moins une ligne {@code user_subscriptions} de statut autre que PENDING. */
    PURCHASE
}
