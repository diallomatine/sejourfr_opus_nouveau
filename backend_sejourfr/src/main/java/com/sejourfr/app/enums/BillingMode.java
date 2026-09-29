package com.sejourfr.app.enums;

/**
 * Mode commercial global de la plateforme, piloté par {@code sejourfr.billing.mode}.
 *
 * <ul>
 *   <li>{@code SUBSCRIPTION} : abonnements récurrents (lots 2/3/4).</li>
 *   <li>{@code ONE_TIME} : passes d'accès à durée fixe (lot 5).</li>
 * </ul>
 *
 * <p>Ne pilote QUE les points d'entrée paiement (création checkout, type de
 * produit accepté en verify-receipt, mapping webhooks). Tout le reste (source
 * de vérité {@code user_subscriptions}, agrégation, gating) est commun aux deux
 * modes. La bascule est réversible : flag + drapeau is_active des plans, aucun
 * code supprimé. Cf. CLAUDE.md racine § Paiements (Lot 5).
 */
public enum BillingMode {
    SUBSCRIPTION,
    ONE_TIME
}
