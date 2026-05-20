package com.sejourfr.app.service;

import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.BillingPlan;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.mapper.PlanMapper;
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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
 * <p>
 * Flux :
 * <ol>
 *   <li>Front demande l'URL via GET /api/billing/payment-link?plan=...</li>
 *   <li>Back enrichit l'URL avec client_reference_id=&lt;user_id&gt; et la renvoie.</li>
 *   <li>L'utilisateur paie sur Stripe (hosted page).</li>
 *   <li>Stripe notifie le webhook checkout.session.completed.</li>
 *   <li>Le back active la UserSubscription pour durationDays jours.</li>
 * </ol>
 * Pas de renouvellement automatique : l'utilisateur rachete manuellement
 * si besoin. Pas de gestion d'abonnement Stripe recurrent.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BillingService {

    private static final String CHECKOUT_COMPLETED_EVENT = "checkout.session.completed";
    private static final int DEFAULT_DURATION_DAYS = 90;
    private static final long CENTS_PER_EURO = 100L;

    private final StripeProperties stripeProperties;
    private final UserManager userManager;
    private final PlanManager planManager;
    private final UserSubscriptionManager userSubscriptionManager;
    private final PlanMapper planMapper;

    /**
     * Initialise la cle API Stripe globale au demarrage si elle est configuree.
     * Stripe SDK 28 utilise cette variable statique pour toutes les requetes
     * (Session.create, etc.). Le webhook reste independant — il verifie la
     * signature avec sa propre cle.
     */
    @PostConstruct
    public void initStripe() {
        if (!stripeProperties.getSecretKey().isBlank()) {
            Stripe.apiKey = stripeProperties.getSecretKey();
        }
    }

    // ------------------------------------------------------------------------
    // Lecture plans publics
    // ------------------------------------------------------------------------

    /**
     * Liste les plans actifs pour la landing publique (section Tarifs).
     * Tri : prix croissant, le gratuit en tete. Le plan "FREE" est inclus —
     * c'est au front de decider quoi en faire (colonne "Decouverte" ou masque).
     */
    public List<PlanPublicResponse> listPublicPlans() {
        return planManager.findAll().stream()
                .filter(Plan::isActive)
                .sorted(Comparator.comparing(Plan::getPrice))
                .map(planMapper::toPublicResponse)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Generation de l'URL de paiement
    // ------------------------------------------------------------------------

    /**
     * Renvoie une URL de paiement Stripe pour le plan demande.
     * <p>
     * Deux strategies selon la configuration :
     * <ul>
     *   <li>Si les Stripe Price IDs sont fournis (sejourfr.stripe.price-*), on
     *       cree une Checkout Session via l'API Stripe avec success_url /
     *       cancel_url definies en code → strategie recommandee.</li>
     *   <li>Sinon, fallback sur les Payment Links statiques pre-crees dans le
     *       dashboard Stripe.</li>
     * </ul>
     * Dans les deux cas, client_reference_id=&lt;user_id&gt; est injecte pour
     * retrouver l'utilisateur dans le webhook checkout.session.completed.
     */
    public BillingCheckoutResponse getPaymentLink(UUID userId, BillingPlan plan) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe n'est pas configuré côté backend (secret-key + price-* ou payment-link-* manquants)."
            );
        }
        userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        return stripeProperties.isCheckoutSessionConfigured()
                ? createCheckoutSession(userId, plan)
                : buildPaymentLinkUrl(userId, plan);
    }

    private BillingCheckoutResponse createCheckoutSession(UUID userId, BillingPlan plan) {
        String priceId = switch (plan) {
            case CIVIQUE_3MOIS -> stripeProperties.getPriceCivique();
            case INTEGRAL_3MOIS -> stripeProperties.getPriceIntegral();
        };
        String appBaseUrl = stripeProperties.getAppBaseUrl();
        // Placeholder remplace par Stripe avant la redirection.
        String successUrl = appBaseUrl + "/paiement/succes"
                + "?session_id={CHECKOUT_SESSION_ID}&plan=" + plan.name();
        String cancelUrl = appBaseUrl + "/paiement?canceled=1";

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setClientReferenceId(userId.toString())
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(SessionCreateParams.LineItem.builder()
                        .setPrice(priceId)
                        .setQuantity(1L)
                        .build())
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

    private BillingCheckoutResponse buildPaymentLinkUrl(UUID userId, BillingPlan plan) {
        String baseUrl = switch (plan) {
            case CIVIQUE_3MOIS -> stripeProperties.getPaymentLinkCivique();
            case INTEGRAL_3MOIS -> stripeProperties.getPaymentLinkIntegral();
        };
        String separator = baseUrl.contains("?") ? "&" : "?";
        return new BillingCheckoutResponse(baseUrl + separator + "client_reference_id=" + userId);
    }

    // ------------------------------------------------------------------------
    // Webhook
    // ------------------------------------------------------------------------

    /**
     * Recoit un evenement webhook Stripe, verifie la signature, et applique
     * la mise a jour. Avec des Payment Links one-shot, seul
     * checkout.session.completed nous interesse : l'utilisateur a paye, on lui
     * ouvre l'acces pour durationDays jours.
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

        if (CHECKOUT_COMPLETED_EVENT.equals(event.getType())) {
            handleCheckoutCompleted(event);
        } else {
            log.debug("Stripe event ignoré : {}", event.getType());
        }
    }

    private void handleCheckoutCompleted(Event event) {
        Session session = deserializeSession(event);

        String userIdStr = session.getClientReferenceId();
        if (userIdStr == null || userIdStr.isBlank()) {
            log.warn("Checkout completed sans client_reference_id : {}", session.getId());
            return;
        }

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
        log.info("Abonnement {} activé pour user={} session={}", plan, userId, session.getId());
    }

    /**
     * Deserialise le Session attache a un Event Stripe.
     * <p>
     * Le chemin nominal {@code getDataObjectDeserializer().getObject()} renvoie
     * un Optional vide quand la version d'API Stripe du payload ne correspond
     * pas exactement a celle du SDK. C'est le cas le plus frequent en dev avec
     * {@code stripe listen}. On fait fallback sur {@code deserializeUnsafe()}
     * qui parse le JSON brut sans valider la version — pour notre besoin
     * (client_reference_id, amount_total, id) les champs sont stables.
     *
     * @see <a href="https://docs.stripe.com/webhooks#api-version-issues">Stripe docs</a>
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
     * Mappe le montant total paye (en centimes) vers un BillingPlan, en se basant
     * sur les prix de lancement et originaux de la table plans. Reste robuste si
     * l'admin change un prix cote Stripe sans synchroniser la DB.
     */
    private BillingPlan mapAmountToPlan(long amountCents) {
        Plan civique = planManager.findByCode(BillingPlan.CIVIQUE_3MOIS.planCode()).orElse(null);
        Plan integral = planManager.findByCode(BillingPlan.INTEGRAL_3MOIS.planCode()).orElse(null);
        if (civique != null && matchesPlanAmount(civique, amountCents)) {
            return BillingPlan.CIVIQUE_3MOIS;
        }
        if (integral != null && matchesPlanAmount(integral, amountCents)) {
            return BillingPlan.INTEGRAL_3MOIS;
        }
        return null;
    }

    private boolean matchesPlanAmount(Plan plan, long amountCents) {
        long planCents = toCents(plan.getPrice());
        if (planCents == amountCents) return true;

        // Tolere aussi le prix « normal » : si l'admin a coupe l'offre de
        // lancement cote Stripe sans synchroniser la DB, on accepte tout de
        // meme le paiement.
        if (plan.getOriginalPrice() != null) {
            return toCents(plan.getOriginalPrice()) == amountCents;
        }
        return false;
    }

    private static long toCents(BigDecimal amount) {
        return amount.multiply(BigDecimal.valueOf(CENTS_PER_EURO)).longValueExact();
    }

    private void activateSubscription(
            UUID userId, BillingPlan plan, String stripeCustomerId, String stripeSessionId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        Plan dbPlan = planManager.findByCode(plan.planCode())
                .orElseThrow(() -> new EntityNotFoundException("Plan introuvable : " + plan.planCode()));

        Instant now = Instant.now();
        int durationDays = dbPlan.getDurationDays() > 0 ? dbPlan.getDurationDays() : DEFAULT_DURATION_DAYS;

        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(dbPlan);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setStartsAt(now);
        sub.setEndsAt(now.plus(durationDays, ChronoUnit.DAYS));
        sub.setStripeCustomerId(stripeCustomerId);
        // Avec Payment Links one-shot il n'y a pas de Subscription Stripe, mais
        // on garde l'ID de la session checkout pour la tracabilite.
        sub.setStripeSubscriptionId(stripeSessionId);
        userSubscriptionManager.save(sub);
    }
}
