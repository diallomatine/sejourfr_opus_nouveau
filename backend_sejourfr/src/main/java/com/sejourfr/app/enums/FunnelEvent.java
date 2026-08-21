package com.sejourfr.app.enums;

/**
 * Les seules etapes du funnel d'acquisition qui ne se lisent PAS sur une vraie
 * table.
 *
 * <p>Tout le reste — inscription, diagnostic commence, diagnostic termine,
 * paiement — vit deja dans {@code users}, {@code diagnostic_sessions} et
 * {@code user_subscriptions}, et s'y lit exactement. Ajouter un evenement pour
 * ces etapes-la creerait une seconde verite, condamnee a diverger de la
 * premiere le jour ou un client oublie de l'emettre. Ne pas etendre cet enum
 * sans avoir verifie qu'aucune table ne porte deja l'information.
 *
 * <p>Une valeur ajoutee ici doit l'etre aussi dans le CHECK
 * {@code chk_user_funnel_event} (V036) : la base refuse ce qu'elle ne connait
 * pas, et c'est voulu.
 */
public enum FunnelEvent {

    /** L'ecran Premium a ete affiche au candidat (paywall, page de passes). */
    PAYWALL_VIEWED,

    /** Le candidat a clique sur l'achat d'un pass, avant toute redirection. */
    SUBSCRIBE_CLICKED,

    /**
     * Une session de paiement a reellement ete creee cote fournisseur. Pose par
     * le SERVEUR (jamais par un client) : c'est le dernier point verifiable
     * avant que le candidat quitte notre domaine.
     */
    CHECKOUT_STARTED
}
