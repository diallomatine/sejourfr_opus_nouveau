package com.sejourfr.app.service;

import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.PlanRepository;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.Subscription;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import jakarta.persistence.EntityNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.UUID;

@Service
public class BillingService {

    private static final Logger log = LoggerFactory.getLogger(BillingService.class);

    private final StripeProperties stripeProperties;
    private final UserRepository userRepository;
    private final PlanRepository planRepository;
    private final UserSubscriptionRepository userSubscriptionRepository;

    public BillingService(
            StripeProperties stripeProperties,
            UserRepository userRepository,
            PlanRepository planRepository,
            UserSubscriptionRepository userSubscriptionRepository
    ) {
        this.stripeProperties = stripeProperties;
        this.userRepository = userRepository;
        this.planRepository = planRepository;
        this.userSubscriptionRepository = userSubscriptionRepository;
    }

    /**
     * Crée une Stripe Checkout Session pour l'utilisateur et le plan demandé.
     * L'URL renvoyée est celle vers laquelle le front doit rediriger.
     */
    public BillingCheckoutResponse createCheckoutSession(UUID userId, BillingPlan plan) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe n'est pas configuré côté backend (secret-key / price-* manquants)."
            );
        }
        Stripe.apiKey = stripeProperties.getSecretKey();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        String priceId = switch (plan) {
            case MENSUEL -> stripeProperties.getPriceMonthly();
            case ANNUEL -> stripeProperties.getPriceYearly();
        };

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
                .setSuccessUrl(stripeProperties.getSuccessUrl())
                .setCancelUrl(stripeProperties.getCancelUrl())
                .setCustomerEmail(user.getEmail())
                .addLineItem(
                        SessionCreateParams.LineItem.builder()
                                .setPrice(priceId)
                                .setQuantity(1L)
                                .build()
                )
                .putMetadata("user_id", userId.toString())
                .putMetadata("plan", plan.name())
                .build();

        try {
            Session session = Session.create(params);
            return new BillingCheckoutResponse(session.getUrl());
        } catch (StripeException e) {
            log.error("Stripe checkout session creation failed", e);
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Stripe n'a pas pu créer la session : " + e.getMessage()
            );
        }
    }

    /**
     * Crée une session Stripe Customer Portal pour l'utilisateur courant.
     * Le portail Stripe-hosted permet à l'user de gérer sa carte, ses
     * factures et d'annuler son abonnement. Nécessite que l'user ait déjà
     * un stripe_customer_id (rempli au premier checkout completed).
     */
    public BillingCheckoutResponse createPortalSession(UUID userId) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe n'est pas configuré côté backend."
            );
        }
        String customerId = userSubscriptionRepository.findByUserId(userId).stream()
                .filter(s -> s.getStripeCustomerId() != null)
                .max(Comparator.comparing(UserSubscription::getStartsAt))
                .map(UserSubscription::getStripeCustomerId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun abonnement Stripe associé à ce compte."
                ));

        Stripe.apiKey = stripeProperties.getSecretKey();
        try {
            com.stripe.param.billingportal.SessionCreateParams params =
                    com.stripe.param.billingportal.SessionCreateParams.builder()
                            .setCustomer(customerId)
                            .setReturnUrl(stripeProperties.getCancelUrl())
                            .build();
            com.stripe.model.billingportal.Session session =
                    com.stripe.model.billingportal.Session.create(params);
            return new BillingCheckoutResponse(session.getUrl());
        } catch (StripeException e) {
            log.error("Stripe Customer Portal session failed", e);
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Stripe n'a pas pu créer la session portail : " + e.getMessage()
            );
        }
    }

    /**
     * Reçoit un événement webhook Stripe, vérifie la signature, et applique
     * la mise à jour :
     *   - checkout.session.completed  → active une nouvelle UserSubscription
     *   - customer.subscription.updated → resynchronise endsAt + status
     *   - customer.subscription.deleted → marque la UserSubscription EXPIRED
     */
    @Transactional
    public void handleWebhook(String payload, String signatureHeader) {
        if (stripeProperties.getWebhookSecret().isBlank()) {
            log.warn("Webhook Stripe reçu mais STRIPE_WEBHOOK_SECRET non configuré, ignoré.");
            return;
        }
        Event event;
        try {
            event = Webhook.constructEvent(payload, signatureHeader, stripeProperties.getWebhookSecret());
        } catch (SignatureVerificationException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Signature webhook invalide");
        }

        switch (event.getType()) {
            case "checkout.session.completed" -> handleCheckoutCompleted(event);
            case "customer.subscription.updated" -> handleSubscriptionUpdated(event);
            case "customer.subscription.deleted" -> handleSubscriptionDeleted(event);
            default -> log.debug("Stripe event ignoré : {}", event.getType());
        }
    }

    private void handleCheckoutCompleted(Event event) {
        Session session = (Session) event.getDataObjectDeserializer()
                .getObject()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Payload Stripe sans objet Session"
                ));

        String userIdStr = session.getMetadata().get("user_id");
        String planName = session.getMetadata().get("plan");
        if (userIdStr == null || planName == null) {
            log.warn("Checkout completed sans metadata user_id/plan : {}", session.getId());
            return;
        }

        UUID userId = UUID.fromString(userIdStr);
        BillingPlan plan = BillingPlan.valueOf(planName);
        activateSubscription(userId, plan, session.getCustomer(), session.getSubscription());
        log.info("Abonnement activé pour user={} plan={} subscription={}",
                userId, plan, session.getSubscription());
    }

    /**
     * Resync : Stripe nous prévient quand le statut, la période ou le mode de
     * paiement de l'abonnement change. On met simplement à jour endsAt et
     * status sur la UserSubscription correspondante (lookup par
     * stripe_subscription_id).
     */
    private void handleSubscriptionUpdated(Event event) {
        Subscription stripeSub = (Subscription) event.getDataObjectDeserializer()
                .getObject()
                .orElse(null);
        if (stripeSub == null) return;

        userSubscriptionRepository.findByStripeSubscriptionId(stripeSub.getId())
                .ifPresent(sub -> {
                    sub.setStatus(mapStripeStatus(stripeSub.getStatus()));
                    Long currentPeriodEnd = stripeSub.getCurrentPeriodEnd();
                    if (currentPeriodEnd != null && currentPeriodEnd > 0) {
                        sub.setEndsAt(Instant.ofEpochSecond(currentPeriodEnd));
                    }
                    userSubscriptionRepository.save(sub);
                    log.info("Subscription updated : {} -> status={} endsAt={}",
                            stripeSub.getId(), sub.getStatus(), sub.getEndsAt());
                });
    }

    private void handleSubscriptionDeleted(Event event) {
        Subscription stripeSub = (Subscription) event.getDataObjectDeserializer()
                .getObject()
                .orElse(null);
        if (stripeSub == null) return;

        userSubscriptionRepository.findByStripeSubscriptionId(stripeSub.getId())
                .ifPresent(sub -> {
                    sub.setStatus(SubscriptionStatus.EXPIRED);
                    sub.setEndsAt(Instant.now());
                    userSubscriptionRepository.save(sub);
                    log.info("Subscription supprimée : {}", stripeSub.getId());
                });
    }

    private SubscriptionStatus mapStripeStatus(String stripeStatus) {
        if (stripeStatus == null) return SubscriptionStatus.EXPIRED;
        return switch (stripeStatus) {
            case "active", "trialing", "past_due" -> SubscriptionStatus.ACTIVE;
            case "canceled" -> SubscriptionStatus.CANCELED;
            case "incomplete_expired", "unpaid", "incomplete" -> SubscriptionStatus.EXPIRED;
            default -> SubscriptionStatus.ACTIVE;
        };
    }

    private void activateSubscription(
            UUID userId,
            BillingPlan plan,
            String stripeCustomerId,
            String stripeSubscriptionId
    ) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        Plan dbPlan = planRepository.findByCode(plan.planCode())
                .orElseThrow(() -> new EntityNotFoundException("Plan introuvable : " + plan.planCode()));

        Instant now = Instant.now();
        Instant endsAt = switch (plan) {
            case MENSUEL -> now.plus(31, ChronoUnit.DAYS);
            case ANNUEL -> now.plus(366, ChronoUnit.DAYS);
        };

        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(dbPlan);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setStartsAt(now);
        sub.setEndsAt(endsAt);
        sub.setStripeCustomerId(stripeCustomerId);
        sub.setStripeSubscriptionId(stripeSubscriptionId);
        userSubscriptionRepository.save(sub);
    }
}
