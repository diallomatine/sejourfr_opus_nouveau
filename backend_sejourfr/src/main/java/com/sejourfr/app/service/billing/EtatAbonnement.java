package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.FeeSource;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PurchaseOrigin;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * Photo de l'état <b>métier</b> d'une {@link UserSubscription} : tout ce que la
 * ligne porte de significatif, <b>sauf {@code updated_at}</b> — qui n'est pas un
 * fait métier mais la trace du dernier vrai changement.
 *
 * <p>Autorité unique de la doctrine « un webhook ou un re-fetch ne sauvegarde
 * que si l'état métier a changé ». Stripe, Apple et Google reçoivent tous les
 * trois plusieurs notifications pour un même événement métier (Pub/Sub est
 * at-least-once par design, Stripe émet plusieurs events par cycle) : la dédup
 * par {@code event_id} / {@code notificationUUID} / {@code messageId} ne dit que
 * « ce message-là a déjà été vu », jamais « cet état-là est déjà en base ». Sans
 * la comparaison, chaque message rejouait un {@code UPDATE} et l'entité voyait
 * son {@code @PreUpdate} avancer {@code updated_at} sans qu'aucun champ ne
 * bouge — la colonne « mise à jour » de la console admin devenait illisible.
 *
 * <p>Deux usages, complémentaires :
 * <ul>
 *   <li>{@link #de(UserSubscription)} + {@link #identiqueA(UserSubscription)} :
 *       on photographie AVANT d'appliquer l'état entrant, on compare APRÈS, et
 *       on n'appelle {@code save()} que si quelque chose a bougé.</li>
 *   <li>{@link #poser(Object, Supplier, Consumer)} : on n'appelle le setter que
 *       si la valeur change vraiment. Le dirty-checking par défaut d'Hibernate
 *       compare l'état au snapshot de chargement (une ré-affectation identique
 *       ne salit donc pas l'entité), mais cette garantie dépend d'un réglage —
 *       un dirty-tracking par bytecode suivrait l'appel du setter, pas la
 *       valeur. On ne fait pas reposer une règle de facturation là-dessus.</li>
 * </ul>
 *
 * <p>🛑 Toute nouvelle colonne métier de {@code user_subscriptions} s'ajoute
 * ici : un champ oublié serait un changement réel qui ne déclencherait aucune
 * sauvegarde.
 */
record EtatAbonnement(
        UUID planId,
        SubscriptionStatus status,
        Instant startsAt,
        Instant endsAt,
        SubscriptionSource source,
        String externalTransactionId,
        String originalTransactionId,
        String productId,
        boolean autoRenew,
        String stripeCustomerId,
        String stripeSubscriptionId,
        Instant expiryRemindedAt,
        int realtimeEoSessionsRemaining,
        Integer amountCents,
        String currency,
        Integer amountEurCents,
        BigDecimal fxRateToEur,
        Instant purchasedAt,
        Integer vatCents,
        Integer providerFeeCents,
        Integer netAfterFeeCents,
        Integer netExVatCents,
        FeeSource feeSource,
        Integer revenueRulesVersion,
        PurchaseOrigin origin,
        UUID diagnosticRunId,
        UUID journeyId,
        UUID purchaseIntentId,
        PaymentStatus paymentStatus) {

    /** Le plan se compare par son identifiant : c'est lui qui est persisté. */
    static EtatAbonnement de(UserSubscription sub) {
        return new EtatAbonnement(
                sub.getPlan() != null ? sub.getPlan().getId() : null,
                sub.getStatus(),
                sub.getStartsAt(),
                sub.getEndsAt(),
                sub.getSource(),
                sub.getExternalTransactionId(),
                sub.getOriginalTransactionId(),
                sub.getProductId(),
                sub.isAutoRenew(),
                sub.getStripeCustomerId(),
                sub.getStripeSubscriptionId(),
                sub.getExpiryRemindedAt(),
                sub.getRealtimeEoSessionsRemaining(),
                sub.getAmountCents(),
                sub.getCurrency(),
                sub.getAmountEurCents(),
                sub.getFxRateToEur(),
                sub.getPurchasedAt(),
                sub.getVatCents(),
                sub.getProviderFeeCents(),
                sub.getNetAfterFeeCents(),
                sub.getNetExVatCents(),
                sub.getFeeSource(),
                sub.getRevenueRulesVersion(),
                sub.getOrigin(),
                sub.getDiagnosticRunId(),
                sub.getJourneyId(),
                sub.getPurchaseIntentId(),
                sub.getPaymentStatus());
    }

    /** {@code true} si la souscription porte toujours exactement cet état. */
    boolean identiqueA(UserSubscription sub) {
        return this.equals(de(sub));
    }

    /** Affecte {@code valeur} uniquement si elle diffère de ce qui est déjà là. */
    static <T> void poser(T valeur, Supplier<T> lecture, Consumer<T> ecriture) {
        if (!Objects.equals(lecture.get(), valeur)) {
            ecriture.accept(valeur);
        }
    }

    /**
     * 🛑 {@code null} = inconnu, jamais mauvais — appliqué aux identifiants
     * servis par un store. Un event peut arriver avant que le store n'ait
     * l'identifiant (Stripe émet des {@code customer.subscription.updated} dont
     * le {@code latest_invoice} est encore {@code null}, Play ne rend pas
     * toujours un {@code latestOrderId}) : l'absence ne veut pas dire « cette
     * souscription n'a plus de facture ». On garde alors celui déjà connu —
     * sinon la ligne perd sa traçabilité, et l'aller-retour
     * {@code null ⇄ in_xxx} fait avancer {@code updated_at} deux fois sans le
     * moindre changement métier.
     *
     * <p>C'est la même convention que les {@code toInstant(valeur, fallback)} /
     * {@code parseExpiry(valeur, fallback)} / {@code deriveAutoRenew(info,
     * fallback)} déjà en place sur les autres champs.
     */
    static String connuOu(String valeur, String existant) {
        return (valeur == null || valeur.isBlank()) ? existant : valeur;
    }
}
