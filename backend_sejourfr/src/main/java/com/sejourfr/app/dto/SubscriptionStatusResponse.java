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
        boolean oneTime,
        // Sessions d'expression orale TEMPS RÉEL restantes sur le pass courant
        // (examinateur IA, T1/T2). NULL si non concerné (compte gratuit, ou pass
        // sans accès TCF) — les fronts affichent alors le compteur uniquement
        // quand la valeur est présente. Quota configurable côté backend.
        Integer realtimeSessionsRemaining
) {
    public static SubscriptionStatusResponse notPremium() {
        return new SubscriptionStatusResponse(
                false, null, null, null, null, ModuleAccess.NONE, false, false, null);
    }

    /**
     * Statut d'un accès EFFECTIF (achats + décisions admin, {@code SubscriptionService.accesEffectif}).
     * Forme inchangée pour le mobile (GO §6, §16) :
     * <ul>
     *   <li>{@code moduleAccess} et {@code expiresAt} sont ceux de l'accès effectif ;</li>
     *   <li>{@code source}, {@code productId}, {@code status}, {@code autoRenew},
     *       {@code oneTime} viennent de l'achat qui compte s'il y en a un — sans
     *       achat (accès accordé par l'admin) : {@code source}/{@code productId}
     *       absents, {@code ACTIVE}, pas de renouvellement, {@code oneTime}.</li>
     * </ul>
     * Aucune valeur nouvelle : l'origine « admin » n'est visible que dans l'admin.
     * Sans décision admin, la réponse est identique à l'historique
     * ({@code expiresAt} = fin de l'achat qui compte).
     */
    public static SubscriptionStatusResponse from(ModuleAccess module, Instant expiresAt, UserSubscription achat) {
        if (module == null || module == ModuleAccess.NONE) {
            return notPremium();
        }
        if (achat == null) {
            return new SubscriptionStatusResponse(
                    true, null, null, expiresAt, SubscriptionStatus.ACTIVE, module, false, true, null);
        }
        boolean oneTime = achat.getPlan() != null
                && achat.getPlan().getPurchaseType() == PlanPurchaseType.ONE_TIME;
        return new SubscriptionStatusResponse(
                true,
                achat.getSource(),
                achat.getProductId(),
                expiresAt,
                achat.getStatus(),
                module,
                achat.isAutoRenew(),
                oneTime,
                null
        );
    }

    /** Copie en fixant le compteur de sessions temps réel restantes. */
    public SubscriptionStatusResponse withRealtimeSessionsRemaining(Integer remaining) {
        return new SubscriptionStatusResponse(
                isPremium, source, productId, expiresAt, status, moduleAccess,
                autoRenew, oneTime, remaining);
    }
}
