package com.sejourfr.app.service;

import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.PlanRepository;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import com.stripe.Stripe;
import com.stripe.exception.EventDataObjectDeserializationException;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Gestion des paiements via Stripe Payment Links one-shot.
 *
 * Flux :
 *   1. Le front demande l'URL du payment link pour un plan via
 *      GET /api/billing/payment-link?plan=...
 *   2. Le back enrichit l'URL avec client_reference_id=<user_id> et la renvoie.
 *   3. L'utilisateur paie sur Stripe (hosted page).
 *   4. Stripe notifie le webhook checkout.session.completed.
 *   5. Le back active la UserSubscription pour durationDays jours.
 *
 * Pas de renouvellement automatique : l'utilisateur rachète manuellement
 * si besoin. Pas de gestion d'abonnement Stripe récurrent.
 */
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
     * Initialise la clé API Stripe globale au démarrage si elle est
     * configurée. Stripe SDK 28 utilise cette variable statique pour toutes
     * les requêtes (Session.create, etc.). Le webhook reste indépendant — il
     * vérifie la signature avec sa propre clé.
     */
    @PostConstruct
    public void initStripe() {
        if (!stripeProperties.getSecretKey().isBlank()) {
            Stripe.apiKey = stripeProperties.getSecretKey();
        }
    }

    /**
     * Liste les plans actifs pour la landing publique (section Tarifs).
     * Tri : prix croissant, le gratuit en tête. Le plan "FREE" est inclus —
     * c'est au front de décider quoi en faire (affichage en colonne "Découverte"
     * ou masqué).
     */
    public List<PlanPublicResponse> listPublicPlans() {
        return planRepository.findAll().stream()
                .filter(Plan::isActive)
                .sorted(Comparator.comparing(Plan::getPrice))
                .map(p -> new PlanPublicResponse(
                        p.getCode(),
                        p.getName(),
                        p.getBillingCycle(),
                        p.getPrice(),
                        p.getOriginalPrice(),
                        p.getModuleAccess(),
                        p.getDurationDays()
                ))
                .toList();
    }

    /**
     * Renvoie une URL de paiement Stripe pour le plan demandé.
     *
     * Deux stratégies selon la configuration :
     *
     *   - Si les Stripe Price IDs sont fournis (sejourfr.stripe.price-*), on
     *     crée une Checkout Session via l'API Stripe avec success_url et
     *     cancel_url définies en code → l'utilisateur revient automatiquement
     *     sur /paiement/succes après paiement (ou /paiement?canceled=1 en cas
     *     d'abandon). C'est la stratégie recommandée.
     *
     *   - Sinon, fallback sur les Payment Links statiques (URLs
     *     sejourfr.stripe.payment-link-*). La redirection après paiement
     *     dépend alors de la config dashboard Stripe de chaque lien.
     *
     * Dans les deux cas on injecte client_reference_id=<user_id> pour
     * retrouver l'utilisateur dans le webhook checkout.session.completed.
     */
    public BillingCheckoutResponse getPaymentLink(UUID userId, BillingPlan plan) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe n'est pas configuré côté backend (secret-key + price-* ou payment-link-* manquants)."
            );
        }
        // Vérifie que l'utilisateur existe (sinon l'URL serait inutile).
        userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        if (stripeProperties.isCheckoutSessionConfigured()) {
            return createCheckoutSession(userId, plan);
        }
        return buildPaymentLinkUrl(userId, plan);
    }

    /**
     * Stratégie recommandée : crée une Checkout Session via l'API Stripe avec
     * success_url et cancel_url construites côté code à partir de
     * `sejourfr.stripe.app-base-url`. Le query param `plan=...` est injecté
     * dans success_url pour que la page /paiement/succes puisse afficher le
     * bon libellé sans dépendre du statut user (le webhook peut arriver
     * quelques secondes après le retour du user).
     */
    private BillingCheckoutResponse createCheckoutSession(UUID userId, BillingPlan plan) {
        String priceId = switch (plan) {
            case CIVIQUE_3MOIS -> stripeProperties.getPriceCivique();
            case INTEGRAL_3MOIS -> stripeProperties.getPriceIntegral();
        };
        String appBaseUrl = stripeProperties.getAppBaseUrl();
        // Placeholder remplacé par Stripe avant la redirection.
        String successUrl = appBaseUrl + "/paiement/succes"
                + "?session_id={CHECKOUT_SESSION_ID}&plan=" + plan.name();
        String cancelUrl = appBaseUrl + "/paiement?canceled=1";

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setClientReferenceId(userId.toString())
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(
                        SessionCreateParams.LineItem.builder()
                                .setPrice(priceId)
                                .setQuantity(1L)
                                .build()
                )
                .build();
        try {
            Session session = Session.create(params);
            return new BillingCheckoutResponse(session.getUrl());
        } catch (StripeException e) {
            log.error("Échec création Checkout Session (plan={}) : {}", plan, e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Impossible de créer la session Stripe. Réessayez dans un instant."
            );
        }
    }

    /**
     * Stratégie de fallback : utilise les Payment Links statiques pré-créés
     * dans le dashboard Stripe. La redirection après paiement doit alors être
     * configurée sur le lien lui-même côté dashboard.
     */
    private BillingCheckoutResponse buildPaymentLinkUrl(UUID userId, BillingPlan plan) {
        String baseUrl = switch (plan) {
            case CIVIQUE_3MOIS -> stripeProperties.getPaymentLinkCivique();
            case INTEGRAL_3MOIS -> stripeProperties.getPaymentLinkIntegral();
        };
        String separator = baseUrl.contains("?") ? "&" : "?";
        String fullUrl = baseUrl + separator + "client_reference_id=" + userId;
        return new BillingCheckoutResponse(fullUrl);
    }

    /**
     * Reçoit un événement webhook Stripe, vérifie la signature, et applique
     * la mise à jour. Avec des Payment Links one-shot, seul
     * checkout.session.completed nous intéresse : l'utilisateur a payé, on
     * lui ouvre l'accès pour durationDays jours.
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

        if ("checkout.session.completed".equals(event.getType())) {
            handleCheckoutCompleted(event);
        } else {
            log.debug("Stripe event ignoré : {}", event.getType());
        }
    }

    private void handleCheckoutCompleted(Event event) {
        Session session = deserializeSession(event);

        // Identifier l'utilisateur : on a passé user_id dans client_reference_id
        // lors de la génération du payment link.
        String userIdStr = session.getClientReferenceId();
        if (userIdStr == null || userIdStr.isBlank()) {
            log.warn("Checkout completed sans client_reference_id : {}", session.getId());
            return;
        }

        // Identifier le plan via le montant payé (cohérent avec la table plans).
        long amountTotalCents = session.getAmountTotal() != null ? session.getAmountTotal() : 0L;
        BillingPlan plan = mapAmountToPlan(amountTotalCents);
        if (plan == null) {
            log.warn("Checkout completed avec montant inconnu : {} cents (session {})",
                    amountTotalCents, session.getId());
            return;
        }

        UUID userId;
        try {
            userId = UUID.fromString(userIdStr);
        } catch (IllegalArgumentException e) {
            log.warn("client_reference_id mal formé : {}", userIdStr);
            return;
        }

        activateSubscription(userId, plan, session.getCustomer(), session.getId());
        log.info("Abonnement {} activé pour user={} session={}",
                plan, userId, session.getId());
    }

    /**
     * Désérialise le Session attaché à un Event Stripe.
     *
     * Le chemin nominal `getDataObjectDeserializer().getObject()` renvoie
     * un Optional vide quand la version d'API Stripe du payload ne
     * correspond pas exactement à celle du SDK (ex: dashboard Stripe en
     * v2024-09-30 / SDK en v2024-06-20). C'est le cas le plus fréquent en
     * dev quand on crée le webhook via `stripe listen` qui forwarde tels
     * quels les events en version courante de l'API.
     *
     * On fait fallback sur `deserializeUnsafe()` qui parse le JSON brut
     * sans valider la version d'API — pour notre besoin (lire
     * client_reference_id, amount_total, id) les champs sont stables d'une
     * version d'API à l'autre.
     *
     * Cf doc Stripe : https://docs.stripe.com/webhooks#api-version-issues
     */
    private Session deserializeSession(Event event) {
        EventDataObjectDeserializer deserializer = event.getDataObjectDeserializer();
        StripeObject obj = deserializer.getObject().orElse(null);
        if (obj == null) {
            log.debug("Stripe event API version mismatch (event={}), fallback deserializeUnsafe", event.getApiVersion());
            try {
                obj = deserializer.deserializeUnsafe();
            } catch (EventDataObjectDeserializationException e) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Payload Stripe non désérialisable : " + e.getMessage()
                );
            }
        }
        if (!(obj instanceof Session session)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Payload Stripe : objet attendu Session, reçu " + obj.getClass().getSimpleName()
            );
        }
        return session;
    }

    /**
     * Mappe le montant total payé (en centimes) vers un BillingPlan.
     * S'appuie sur les prix de lancement et prix « normaux » de la table
     * plans, pour rester cohérent si l'admin change un prix côté Stripe.
     */
    private BillingPlan mapAmountToPlan(long amountCents) {
        Plan civique = planRepository.findByCode(BillingPlan.CIVIQUE_3MOIS.planCode()).orElse(null);
        Plan integral = planRepository.findByCode(BillingPlan.INTEGRAL_3MOIS.planCode()).orElse(null);
        if (civique != null && matchesPlanAmount(civique, amountCents)) {
            return BillingPlan.CIVIQUE_3MOIS;
        }
        if (integral != null && matchesPlanAmount(integral, amountCents)) {
            return BillingPlan.INTEGRAL_3MOIS;
        }
        return null;
    }

    private boolean matchesPlanAmount(Plan plan, long amountCents) {
        long planCents = plan.getPrice().multiply(BigDecimal.valueOf(100)).longValueExact();
        if (planCents == amountCents) {
            return true;
        }
        // Tolère aussi le prix « normal » : si l'admin a coupé l'offre de
        // lancement côté Stripe sans synchroniser la DB, on accepte tout de
        // même le paiement.
        if (plan.getOriginalPrice() != null) {
            long originalCents = plan.getOriginalPrice()
                    .multiply(BigDecimal.valueOf(100)).longValueExact();
            return originalCents == amountCents;
        }
        return false;
    }

    private void activateSubscription(
            UUID userId,
            BillingPlan plan,
            String stripeCustomerId,
            String stripeSessionId
    ) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        Plan dbPlan = planRepository.findByCode(plan.planCode())
                .orElseThrow(() -> new EntityNotFoundException("Plan introuvable : " + plan.planCode()));

        Instant now = Instant.now();
        int durationDays = dbPlan.getDurationDays() > 0 ? dbPlan.getDurationDays() : 90;
        Instant endsAt = now.plus(durationDays, ChronoUnit.DAYS);

        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(dbPlan);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setStartsAt(now);
        sub.setEndsAt(endsAt);
        sub.setStripeCustomerId(stripeCustomerId);
        // Avec Payment Links one-shot il n'y a pas de Subscription Stripe,
        // mais on garde l'ID de la session checkout pour la traçabilité.
        sub.setStripeSubscriptionId(stripeSessionId);
        userSubscriptionRepository.save(sub);
    }
}
