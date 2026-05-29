package com.sejourfr.app.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;

import java.time.Instant;

/**
 * Statut Premium agrégé toutes sources confondues. C'est le client de vérité
 * que l'app mobile et le web lisent au démarrage et après chaque action de
 * paiement.
 *
 * <p>Quand {@code isPremium=false} les autres champs sont {@code null} (sauf
 * {@code moduleAccess=NONE}). L'app doit dans ce cas afficher le paywall —
 * mais elle ne décide PAS du statut, elle se contente de relayer ce que dit
 * cet endpoint.
 *
 * <p>{@code source} permet à l'app mobile de masquer le bouton d'achat IAP
 * quand l'utilisateur est déjà Premium via Stripe (cas anti-double-paiement).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record SubscriptionStatusResponse(
        boolean isPremium,
        SubscriptionSource source,
        String productId,
        Instant expiresAt,
        SubscriptionStatus status,
        ModuleAccess moduleAccess,
        boolean autoRenew,
        // True si l'accès courant vient d'un pass one-time (lot 5) : les fronts
        // affichent « Mon accès » (date de fin + prolonger) sans option de
        // résiliation. False pour un abonnement récurrent.
        boolean oneTime
) {
    public static SubscriptionStatusResponse notPremium() {
        return new SubscriptionStatusResponse(
                false, null, null, null, null, ModuleAccess.NONE, false, false);
    }

    public static SubscriptionStatusResponse from(UserSubscription sub) {
        boolean oneTime = sub.getPlan() != null
                && sub.getPlan().getPurchaseType() == PlanPurchaseType.ONE_TIME;
        return new SubscriptionStatusResponse(
                true,
                sub.getSource(),
                sub.getProductId(),
                sub.getEndsAt(),
                sub.getStatus(),
                sub.getPlan().getModuleAccess(),
                sub.isAutoRenew(),
                oneTime
        );
    }
}
