package com.sejourfr.app.service;

import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProcessedExternalEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.PlanMapper;
import com.sejourfr.app.service.billing.StripeSubscriptionService;
import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
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

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Surface publique des paiements Stripe : listing des plans actifs, création
 * d'une Checkout Session en mode abonnement récurrent, et dispatch des
 * webhooks.
 *
 * <p>Depuis le lot 4, les paiements Stripe sont des abonnements récurrents
 * ({@code mode=SUBSCRIPTION}) et non plus du one-shot. Les Stripe Price IDs
 * vivent en base sur {@code plans.stripe_price_id} ; le code ne contient plus
 * de hardcoding de plans.
 *
 * <p>La logique métier (activation, application des events de souscription,
 * refunds) vit dans {@link StripeSubscriptionService} — par symétrie avec
 * {@code AppleSubscriptionService} et {@code GoogleSubscriptionService}.
 * BillingService reste fin : vérification signature + anti-replay +
 * idempotence + dispatch.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BillingService {

    /** Provider key utilisé dans {@code processed_external_events}. */
    private static final String STRIPE_PROVIDER = SubscriptionSource.STRIPE.providerKey();

    /**
     * Tolérance temporelle anti-replay : on rejette tout évènement dont la
     * date de création serveur est plus vieille que cet écart. Stripe re-livre
     * normalement sous quelques minutes max ; au-delà, c'est suspect.
     */
    private static final long REPLAY_TOLERANCE_SECONDS = 300L;

    private final StripeProperties stripeProperties;
    private final UserManager userManager;
    private final PlanManager planManager;
    private final ProcessedExternalEventManager processedEventManager;
    private final PlanMapper planMapper;
    private final StripeSubscriptionService stripeSubscriptionService;

    /**
     * Initialise la clé API Stripe globale au démarrage si elle est configurée.
     * Stripe SDK 28 utilise cette variable statique pour toutes les requêtes
     * (Session.create, etc.). Le webhook reste indépendant — il vérifie la
     * signature avec sa propre clé.
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
     * Tri : prix croissant, le gratuit en tête. Le plan "FREE" est inclus —
     * c'est au front de décider quoi en faire.
     */
    public List<PlanPublicResponse> listPublicPlans() {
        return planManager.findAll().stream()
                .filter(Plan::isActive)
                .sorted(Comparator.comparing(Plan::getPrice))
                .map(planMapper::toPublicResponse)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Création d'une Checkout Session (mode SUBSCRIPTION)
    // ------------------------------------------------------------------------

    /**
     * Crée une Stripe Checkout Session en mode abonnement récurrent pour le
     * Plan demandé et renvoie son URL. Le {@code planCode} est validé contre
     * la base (Plan actif + stripe_price_id renseigné), donc seuls les SKUs
     * configurés peuvent être achetés.
     *
     * <p>{@code client_reference_id=<userId>} est injecté sur la session pour
     * que le webhook {@code checkout.session.completed} puisse rattacher la
     * subscription au user.
     *
     * @throws ResponseStatusException 503 si Stripe non configuré ;
     *         404 si planCode introuvable / inactif / sans stripe_price_id ;
     *         502 si l'API Stripe échoue.
     */
    public BillingCheckoutResponse getPaymentLink(UUID userId, String planCode) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe non configuré côté backend (secret-key manquant)."
            );
        }
        userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        Plan plan = planManager.findByCode(planCode)
                .filter(Plan::isActive)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Plan inconnu ou inactif : " + planCode
                ));
        String priceId = plan.getStripePriceId();
        if (priceId == null || priceId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Plan " + planCode + " sans stripe_price_id configuré — voir Stripe Dashboard."
            );
        }

        String appBaseUrl = stripeProperties.getAppBaseUrl();
        // Placeholder remplacé par Stripe avant la redirection.
        String successUrl = appBaseUrl + "/paiement/succes"
                + "?session_id={CHECKOUT_SESSION_ID}&plan=" + planCode;
        String cancelUrl = appBaseUrl + "/paiement?canceled=1";

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
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
            log.error("Échec création Checkout Session (plan={}) : {}", planCode, e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Impossible de créer la session Stripe. Réessayez dans un instant."
            );
        }
    }

    // ------------------------------------------------------------------------
    // Webhook : vérification + idempotence + dispatch
    // ------------------------------------------------------------------------

    /**
     * Reçoit un évènement webhook Stripe, vérifie la signature, applique les
     * gardes anti-replay et d'idempotence, puis délègue le traitement à
     * {@link StripeSubscriptionService} selon le type d'évènement.
     *
     * <p>Types gérés (cf. {@code StripeSubscriptionService} pour le mapping
     * vers {@code SubscriptionStatus}) :
     * <ul>
     *   <li>{@code checkout.session.completed} — première activation après
     *       paiement réussi (associe sub_xxx à user_id via
     *       {@code client_reference_id}).</li>
     *   <li>{@code customer.subscription.created} — sauvegarde en cas
     *       d'arrivée hors flow checkout (rare).</li>
     *   <li>{@code customer.subscription.updated} — renouvellements,
     *       annulations programmées, changements de status.</li>
     *   <li>{@code customer.subscription.deleted} — expiration immédiate.</li>
     *   <li>{@code charge.refunded} — remboursement → status REFUNDED.</li>
     * </ul>
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

        // Anti-replay temporel : Stripe doit re-livrer rapidement, un évènement
        // de 1h n'est pas un retry normal. event.getCreated() est en secondes
        // epoch — fourni par Stripe, donc fiable (la signature couvre tout le
        // payload, l'horodatage compris).
        Long createdSec = event.getCreated();
        if (createdSec != null) {
            long ageSeconds = Instant.now().getEpochSecond() - createdSec;
            if (ageSeconds > REPLAY_TOLERANCE_SECONDS) {
                log.warn("Stripe event trop ancien (age={}s, id={}) — rejeté.",
                        ageSeconds, event.getId());
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Évènement trop ancien (possible replay).");
            }
        }

        // Idempotence : si on a déjà traité cet event.id, on skip silencieusement.
        // tryMarkProcessed insère (provider, event_id) — si conflit PK, return
        // false. À ce stade le @Transactional englobe l'insertion ET le
        // traitement en aval — soit tout passe, soit tout rollback, donc pas
        // de risque de marquer "processed" sans avoir appliqué.
        if (!processedEventManager.tryMarkProcessed(STRIPE_PROVIDER, event.getId())) {
            log.info("Stripe event {} déjà traité — skip (replay/retry).", event.getId());
            return;
        }

        stripeSubscriptionService.dispatch(event);
    }
}
