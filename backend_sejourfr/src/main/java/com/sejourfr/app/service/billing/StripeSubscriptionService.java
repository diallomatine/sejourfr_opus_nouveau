package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.stripe.exception.EventDataObjectDeserializationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Charge;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import com.stripe.model.Subscription;
import com.stripe.model.SubscriptionItem;
import com.stripe.model.checkout.Session;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Logique d'application des évènements Stripe sur {@code user_subscriptions}.
 * Symétrique à {@link AppleSubscriptionService} et
 * {@link GoogleSubscriptionService}, sans authentification supplémentaire :
 * la vérif signature + idempotence vivent dans {@code BillingService}, on
 * reçoit ici un {@link Event} déjà validé.
 *
 * <p>Clé d'unicité : {@code (STRIPE, subscription.id)} (sub_xxx, stable sur
 * toute la chaîne de renouvellements). Les events {@code customer.subscription.*}
 * arrivant pour un subscription_id inconnu (= jamais initialisé via
 * checkout.session.completed) sont logués et ignorés.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StripeSubscriptionService {

    private static final String CHECKOUT_COMPLETED = "checkout.session.completed";
    private static final String SUBSCRIPTION_CREATED = "customer.subscription.created";
    private static final String SUBSCRIPTION_UPDATED = "customer.subscription.updated";
    private static final String SUBSCRIPTION_DELETED = "customer.subscription.deleted";
    private static final String CHARGE_REFUNDED = "charge.refunded";

    private final UserManager userManager;
    private final PlanManager planManager;
    private final UserSubscriptionManager userSubscriptionManager;

    /**
     * Entrée unique appelée par {@code BillingService.handleWebhook}. L'event
     * a déjà passé la vérif signature, l'anti-replay et l'idempotence.
     */
    public void dispatch(Event event) {
        String type = event.getType();
        switch (type) {
            case CHECKOUT_COMPLETED -> handleCheckoutCompleted(event);
            case SUBSCRIPTION_CREATED, SUBSCRIPTION_UPDATED ->
                    handleSubscriptionUpdate(event, type);
            case SUBSCRIPTION_DELETED -> handleSubscriptionDeleted(event);
            case CHARGE_REFUNDED -> handleChargeRefunded(event);
            default -> log.debug("Stripe event ignoré : {}", type);
        }
    }

    // ------------------------------------------------------------------------
    // checkout.session.completed — première activation (lie sub_xxx à userId)
    // ------------------------------------------------------------------------

    private void handleCheckoutCompleted(Event event) {
        Session session = deserialize(event, Session.class);

        // En mode SUBSCRIPTION, Stripe envoie cet event avec subscription posé.
        // Pour un éventuel ancien Payment Link one-shot (mode=PAYMENT), il n'y
        // a pas de subscription — on logue et on skip pour ne pas re-créer
        // d'historique one-shot avec le nouveau code.
        String subscriptionId = session.getSubscription();
        if (subscriptionId == null || subscriptionId.isBlank()) {
            log.warn(
                    "checkout.session.completed sans subscription (mode={}, session={}) — ignoré.",
                    session.getMode(), session.getId()
            );
            return;
        }

        UUID userId = parseUserIdOrLog(session.getClientReferenceId(), session.getId());
        if (userId == null) return;

        Subscription subscription;
        try {
            subscription = Subscription.retrieve(subscriptionId);
        } catch (StripeException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Impossible de récupérer la Subscription Stripe " + subscriptionId + " : " + e.getMessage(),
                    e
            );
        }

        upsertFromSubscription(userId, subscription, session.getCustomer());
        log.info(
                "Stripe checkout completed user={} sub={} status={}",
                userId, subscriptionId, subscription.getStatus()
        );
    }

    // ------------------------------------------------------------------------
    // customer.subscription.created / .updated — renouvellements, annulations
    // ------------------------------------------------------------------------

    private void handleSubscriptionUpdate(Event event, String type) {
        Subscription subscription = deserialize(event, Subscription.class);

        Optional<UserSubscription> existing = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.STRIPE, subscription.getId());

        if (existing.isEmpty()) {
            // Cas rare : event reçu avant le checkout.session.completed (race
            // Stripe), ou subscription créée hors UI (admin, API). On log et
            // on skip ; la prochaine update viendra avec l'historique.
            log.warn(
                    "Stripe {} pour sub={} : aucune UserSubscription locale, ignoré.",
                    type, subscription.getId()
            );
            return;
        }

        UserSubscription sub = existing.get();
        applySubscriptionState(sub, subscription);
        userSubscriptionManager.save(sub);
        log.info(
                "Stripe {} appliqué user={} sub={} status={} endsAt={} autoRenew={}",
                type, sub.getUser().getId(), subscription.getId(),
                sub.getStatus(), sub.getEndsAt(), sub.isAutoRenew()
        );
    }

    // ------------------------------------------------------------------------
    // customer.subscription.deleted — expiration immédiate
    // ------------------------------------------------------------------------

    private void handleSubscriptionDeleted(Event event) {
        Subscription subscription = deserialize(event, Subscription.class);
        userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.STRIPE, subscription.getId())
                .ifPresentOrElse(
                        sub -> {
                            sub.setStatus(SubscriptionStatus.EXPIRED);
                            sub.setAutoRenew(false);
                            sub.setEndsAt(toInstant(subscription.getCanceledAt(), sub.getEndsAt()));
                            userSubscriptionManager.save(sub);
                            log.info("Stripe subscription deleted user={} sub={}",
                                    sub.getUser().getId(), subscription.getId());
                        },
                        () -> log.warn(
                                "customer.subscription.deleted pour sub={} : aucune UserSubscription locale, ignoré.",
                                subscription.getId())
                );
    }

    // ------------------------------------------------------------------------
    // charge.refunded — remboursement
    // ------------------------------------------------------------------------

    private void handleChargeRefunded(Event event) {
        Charge charge = deserialize(event, Charge.class);
        // Pour les refunds d'abonnement, le charge porte l'invoice_id qui
        // permet de remonter à la subscription. Stripe expose cela via le
        // champ `invoice` sur le Charge.
        String invoiceId = charge.getInvoice();
        if (invoiceId == null || invoiceId.isBlank()) {
            log.debug("charge.refunded sans invoice (charge={}) — ignoré (non-subscription).", charge.getId());
            return;
        }
        // On retrouve la subscription via l'API Stripe pour identifier la
        // UserSubscription correspondante.
        try {
            com.stripe.model.Invoice invoice = com.stripe.model.Invoice.retrieve(invoiceId);
            String subscriptionId = invoice.getSubscription();
            if (subscriptionId == null || subscriptionId.isBlank()) {
                log.debug("charge.refunded invoice {} sans subscription — ignoré.", invoiceId);
                return;
            }
            userSubscriptionManager
                    .findBySourceAndOriginalTransactionId(
                            SubscriptionSource.STRIPE, subscriptionId)
                    .ifPresent(sub -> {
                        sub.setStatus(SubscriptionStatus.REFUNDED);
                        sub.setAutoRenew(false);
                        userSubscriptionManager.save(sub);
                        log.info("Stripe charge refunded user={} sub={}",
                                sub.getUser().getId(), subscriptionId);
                    });
        } catch (StripeException e) {
            log.warn("Impossible de récupérer l'invoice {} pour refund : {}",
                    invoiceId, e.getMessage());
        }
    }

    // ------------------------------------------------------------------------
    // Helpers — upsert + état
    // ------------------------------------------------------------------------

    /**
     * Crée la ligne {@code user_subscriptions} pour ce user + subscription
     * Stripe, ou la rafraîchit si elle existait déjà (re-checkout). Idempotent.
     */
    private void upsertFromSubscription(UUID userId, Subscription subscription, String customerId) {
        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.STRIPE, subscription.getId())
                .orElse(null);

        if (sub == null) {
            User user = userManager.findById(userId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "User introuvable : " + userId));
            sub = new UserSubscription();
            sub.setUser(user);
            sub.setSource(SubscriptionSource.STRIPE);
            sub.setOriginalTransactionId(subscription.getId());
            sub.setStartsAt(Instant.now());
        } else if (!sub.getUser().getId().equals(userId)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cette subscription Stripe est déjà rattachée à un autre compte."
            );
        }

        sub.setStripeCustomerId(customerId);
        sub.setStripeSubscriptionId(subscription.getId());
        applySubscriptionState(sub, subscription);
        userSubscriptionManager.save(sub);
    }

    /**
     * Synchronise les champs d'une {@code UserSubscription} avec l'état
     * Stripe courant (status, periode, autorenew, plan via price_id,
     * external_transaction_id).
     */
    private void applySubscriptionState(UserSubscription sub, Subscription subscription) {
        Plan plan = lookupPlanFromSubscription(subscription);
        if (plan != null) {
            sub.setPlan(plan);
            sub.setProductId(plan.getCode());
        }
        sub.setExternalTransactionId(subscription.getLatestInvoice());
        sub.setEndsAt(toInstant(subscription.getCurrentPeriodEnd(), sub.getEndsAt()));
        sub.setAutoRenew(!Boolean.TRUE.equals(subscription.getCancelAtPeriodEnd()));
        sub.setStatus(mapStripeStatus(
                subscription.getStatus(),
                Boolean.TRUE.equals(subscription.getCancelAtPeriodEnd()),
                sub.getStatus()
        ));
    }

    /**
     * Extrait le {@code stripe_price_id} du premier line item de la
     * subscription et remonte au Plan correspondant. Lève 400 si introuvable
     * — un attaquant ne peut pas activer un Plan inexistant.
     */
    private Plan lookupPlanFromSubscription(Subscription subscription) {
        if (subscription.getItems() == null || subscription.getItems().getData() == null) {
            return null;
        }
        List<SubscriptionItem> items = subscription.getItems().getData();
        for (SubscriptionItem item : items) {
            if (item.getPrice() == null) continue;
            String priceId = item.getPrice().getId();
            if (priceId == null) continue;
            Plan plan = planManager.findByStripePriceId(priceId).orElse(null);
            if (plan != null) return plan;
        }
        log.warn(
                "Stripe subscription {} sans Plan correspondant en DB (priceIds={}) — abonnement gardé tel quel.",
                subscription.getId(),
                items.stream()
                        .map(i -> i.getPrice() != null ? i.getPrice().getId() : "<null>")
                        .toList()
        );
        return null;
    }

    /**
     * Mappe le statut Stripe vers {@link SubscriptionStatus}.
     *
     * <ul>
     *   <li>{@code incomplete} → PENDING (paiement en attente, SCA…)</li>
     *   <li>{@code incomplete_expired} → EXPIRED</li>
     *   <li>{@code trialing} → TRIAL</li>
     *   <li>{@code active} avec cancelAtPeriodEnd → CANCELED (Premium jusqu'à
     *       current_period_end)</li>
     *   <li>{@code active} sans cancel → ACTIVE</li>
     *   <li>{@code past_due} / {@code unpaid} → IN_GRACE (Stripe Smart Retries)</li>
     *   <li>{@code canceled} → CANCELED si ends_at futur, sinon EXPIRED</li>
     *   <li>{@code paused} → EXPIRED (Stripe Billing pause)</li>
     * </ul>
     */
    private SubscriptionStatus mapStripeStatus(
            String stripeStatus, boolean cancelAtPeriodEnd, SubscriptionStatus fallback) {
        if (stripeStatus == null) return fallback;
        return switch (stripeStatus) {
            case "incomplete" -> SubscriptionStatus.PENDING;
            case "incomplete_expired" -> SubscriptionStatus.EXPIRED;
            case "trialing" -> SubscriptionStatus.TRIAL;
            case "active" -> cancelAtPeriodEnd
                    ? SubscriptionStatus.CANCELED
                    : SubscriptionStatus.ACTIVE;
            case "past_due", "unpaid" -> SubscriptionStatus.IN_GRACE;
            case "canceled" -> SubscriptionStatus.CANCELED;
            case "paused" -> SubscriptionStatus.EXPIRED;
            default -> {
                log.warn("Stripe status inattendu : {}", stripeStatus);
                yield fallback;
            }
        };
    }

    private UUID parseUserIdOrLog(String userIdStr, String sessionId) {
        if (userIdStr == null || userIdStr.isBlank()) {
            log.warn("checkout.session.completed sans client_reference_id : {}", sessionId);
            return null;
        }
        try {
            return UUID.fromString(userIdStr);
        } catch (IllegalArgumentException e) {
            log.warn("client_reference_id mal formé : {}", userIdStr);
            return null;
        }
    }

    private static Instant toInstant(Long epochSeconds, Instant fallback) {
        return epochSeconds != null ? Instant.ofEpochSecond(epochSeconds) : fallback;
    }

    /**
     * Désérialise le payload d'un Event Stripe vers une classe précise. Le
     * chemin nominal {@code getObject()} échoue silencieusement quand la
     * version d'API du payload ne matche pas celle du SDK (cas courant en dev
     * avec {@code stripe listen}). Fallback sur {@code deserializeUnsafe}
     * qui parse le JSON brut.
     */
    @SuppressWarnings("unchecked")
    private <T extends StripeObject> T deserialize(Event event, Class<T> expected) {
        EventDataObjectDeserializer deserializer = event.getDataObjectDeserializer();
        StripeObject obj = deserializer.getObject().orElse(null);
        if (obj == null) {
            log.debug("Stripe event API version mismatch (event={}), fallback deserializeUnsafe",
                    event.getApiVersion());
            try {
                obj = deserializer.deserializeUnsafe();
            } catch (EventDataObjectDeserializationException e) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Payload Stripe non désérialisable : " + e.getMessage()
                );
            }
        }
        if (!expected.isInstance(obj)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Payload Stripe : objet attendu " + expected.getSimpleName()
                            + ", reçu " + obj.getClass().getSimpleName()
            );
        }
        return (T) obj;
    }
}
