package com.sejourfr.app.dto;

import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;

import java.math.BigDecimal;

/**
 * Vue publique d'un plan pour la landing / le paywall : prix actuel, prix
 * original barré (offre de lancement), durée en jours, modules débloqués,
 * et nature ({@code purchaseType}) — le front rend une grille de passes pour
 * ONE_TIME, le toggle de périodicité pour SUBSCRIPTION.
 *
 * <p>Expose {@code realtimeEoSessions} — le nombre de simulations orales en
 * temps réel (examinateur vocal IA) ouvertes par le pass, tel qu'il est stocké
 * en base et éditable côté admin. Les fronts l'affichent sur les cartes de
 * tarifs ; 0 = pass non éligible (Civique, Free), à rendre comme tel plutôt que
 * masqué (c'est une différence d'offre assumée entre Civique et Intégral).
 *
 * <p>Expose aussi les Product IDs store ({@code appleProductId} /
 * {@code googleProductId}) : le mobile s'en sert comme SKU à passer à
 * StoreKit / Play Billing, sans avoir à les déduire de {@code code} (les IDs
 * peuvent diverger du code, ex. après recréation d'un produit Apple). Ces IDs
 * ne sont pas sensibles (visibles dans le binaire de l'app de toute façon) et
 * restent {@code null} pour les plans web-only (Stripe).
 *
 * Pas d'identifiant interne ni de timestamp — c'est consommé par la section
 * Tarifs sans authentification.
 */
public record PlanPublicResponse(
        String code,
        String name,
        BillingCycle billingCycle,
        BigDecimal price,
        BigDecimal originalPrice,
        ModuleAccess moduleAccess,
        int durationDays,
        int realtimeEoSessions,
        PlanPurchaseType purchaseType,
        String appleProductId,
        String googleProductId
) {
}
