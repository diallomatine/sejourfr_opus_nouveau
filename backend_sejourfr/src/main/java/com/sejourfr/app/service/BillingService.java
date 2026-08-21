package com.sejourfr.app.service;

import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.dto.BillingCheckoutResponse;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProcessedExternalEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.PlanMapper;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.service.billing.StripeSubscriptionService;
import com.sejourfr.app.util.ClientContext;
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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
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

    /** Montant minimal facturable par Stripe (50 cts) — plancher d'un upgrade proraté. */
    private static final long MIN_CHARGE_CENTS = 50L;

    private final StripeProperties stripeProperties;
    private final BillingProperties billingProperties;
    private final UserManager userManager;
    private final PlanManager planManager;
    private final ProcessedExternalEventManager processedEventManager;
    private final PlanMapper planMapper;
    private final StripeSubscriptionService stripeSubscriptionService;
    private final SubscriptionService subscriptionService;
    private final FunnelEventService funnelEventService;

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
    public BillingCheckoutResponse getPaymentLink(UUID userId, String planCode,
                                                  ClientContext client) {
        if (!stripeProperties.isConfigured()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe non configuré côté backend (secret-key manquant)."
            );
        }
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        Plan plan = planManager.findByCode(planCode)
                .filter(Plan::isActive)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Plan inconnu ou inactif : " + planCode
                ));

        // Mode passes one-time (lot 5) : Checkout mode=PAYMENT, montant dynamique
        // (price_data depuis plan.price) — pas besoin de Stripe Price. Proration
        // appliquée si upgrade Civique→Intégral.
        if (billingProperties.isOneTime()) {
            return createOneTimeCheckout(user, plan, client);
        }

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
        String cancelUrl = checkoutCancelUrl(planCode);

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
                .setClientReferenceId(userId.toString())
                .setCustomerEmail(user.getEmail())
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(SessionCreateParams.LineItem.builder()
                        .setPrice(priceId)
                        .setQuantity(1L)
                        .build())
                .build();
        try {
            Session session = Session.create(params);
            recordCheckoutStarted(userId, client);
            return new BillingCheckoutResponse(session.getUrl());
        } catch (StripeException e) {
            log.error("Échec création Checkout Session (plan={}) : {}", planCode, e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Impossible de créer la session Stripe. Réessayez dans un instant."
            );
        }
    }

    /**
     * Dernière marche verifiable du funnel : une session de paiement a
     * REELLEMENT ete creee chez le fournisseur. Posee par le serveur, jamais
     * par un client — un clic declare est une intention, pas un depart de
     * paiement.
     *
     * <p><b>Best-effort absolu</b> : perdre une ligne de statistique est sans
     * commune mesure avec empêcher quelqu'un de payer. L'écriture est un
     * {@code ON CONFLICT DO NOTHING} qui ne lève pas, et l'appel est de toute
     * façon protégé.
     */
    private void recordCheckoutStarted(UUID userId, ClientContext client) {
        funnelEventService.recordQuietly(userId, FunnelEvent.CHECKOUT_STARTED, client);
    }

    /**
     * Où revient le candidat quand il fait demi-tour sur Stripe (flèche de
     * Checkout ou {@code cancel_url}) : sur le <b>récapitulatif du pass qu'il
     * avait choisi</b>, pas sur la grille des formules.
     *
     * <p>Il pointait sur {@code /paiement}, donc sur un écran où il fallait
     * re-choisir — exactement ce que le parcours « je clique un prix, il me
     * suit jusqu'au paiement » existe pour éviter. Un demi-tour est le moment
     * où l'on hésite : lui reprendre son choix à cet instant est le pire
     * moment.
     *
     * <p>L'URL est construite <b>par le serveur</b> à partir de son
     * {@code appBaseUrl} et du code de plan qu'il a déjà validé : aucun chemin
     * de retour ne vient du client, donc aucune redirection ouverte possible.
     */
    private String checkoutCancelUrl(String planCode) {
        return stripeProperties.getAppBaseUrl()
                + "/paiement/recapitulatif?plan=" + planCode + "&canceled=1";
    }

    /**
     * Checkout one-time (mode PAYMENT) : montant = prix du plan en base, via
     * {@code price_data} dynamique (aucun Stripe Price à créer). Le {@code planCode}
     * voyage en metadata pour que le webhook sache quel pass créditer ; le
     * {@code payment_intent} servira de clé d'unicité côté grant.
     */
    private BillingCheckoutResponse createOneTimeCheckout(User user, Plan plan,
                                                          ClientContext client) {
        long amountCents = computeOneTimeAmountCents(user.getId(), plan);
        String appBaseUrl = stripeProperties.getAppBaseUrl();
        String successUrl = appBaseUrl + "/paiement/succes"
                + "?session_id={CHECKOUT_SESSION_ID}&plan=" + plan.getCode();
        String cancelUrl = checkoutCancelUrl(plan.getCode());

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .setClientReferenceId(user.getId().toString())
                .setCustomerEmail(user.getEmail())
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .putMetadata("planCode", plan.getCode())
                // Facture Stripe émise et envoyée par email à chaque achat (CGU art. 6.4).
                // L'envoi suppose « Email finalized invoices » activé dans le Dashboard Stripe.
                .setInvoiceCreation(SessionCreateParams.InvoiceCreation.builder()
                        .setEnabled(true)
                        .setInvoiceData(SessionCreateParams.InvoiceCreation.InvoiceData.builder()
                                .setFooter("TVA non applicable, art. 293 B du CGI")
                                .build())
                        .build())
                .addLineItem(SessionCreateParams.LineItem.builder()
                        .setQuantity(1L)
                        .setPriceData(SessionCreateParams.LineItem.PriceData.builder()
                                .setCurrency("eur")
                                .setUnitAmount(amountCents)
                                .setProductData(SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                        .setName(plan.getName())
                                        .build())
                                .build())
                        .build())
                .build();
        try {
            Session session = Session.create(params);
            recordCheckoutStarted(user.getId(), client);
            return new BillingCheckoutResponse(session.getUrl());
        } catch (StripeException e) {
            log.error("Échec création Checkout one-time (plan={}) : {}", plan.getCode(), e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Impossible de créer la session Stripe. Réessayez dans un instant."
            );
        }
    }

    /**
     * Montant à facturer en centimes. Cas nominal = prix plein du plan. Cas
     * upgrade Civique→Intégral avec un accès Civique encore valide : on crédite
     * la valeur restante du pass Civique (prix × joursRestants / durée) et on ne
     * facture que la différence (plancher {@link #MIN_CHARGE_CENTS}). La
     * proration ne vit QUE côté Stripe : Apple/Google vendent à prix fixe.
     */
    private long computeOneTimeAmountCents(UUID userId, Plan plan) {
        long full = toCents(plan.getPrice());
        if (plan.getModuleAccess() != ModuleAccess.INTEGRAL) {
            return full;
        }
        UserSubscription current = subscriptionService.currentSubscription(userId).orElse(null);
        if (current == null || current.getPlan() == null
                || current.getPlan().getModuleAccess() != ModuleAccess.CIVIQUE) {
            return full; // déjà Intégral, ou aucun accès Civique à créditer
        }
        Instant end = current.getEndsAt();
        int civiqueDuration = current.getPlan().getDurationDays();
        if (end == null || !end.isAfter(Instant.now()) || civiqueDuration <= 0) {
            return full;
        }
        long remainingDays = Math.max(0, ChronoUnit.DAYS.between(Instant.now(), end));
        BigDecimal credit = current.getPlan().getPrice()
                .multiply(BigDecimal.valueOf(remainingDays))
                .divide(BigDecimal.valueOf(civiqueDuration), 2, RoundingMode.HALF_UP);
        long amount = full - toCents(credit);
        log.info("Upgrade proraté user={} plan={} plein={}cts crédit={}cts → {}cts",
                userId, plan.getCode(), full, toCents(credit), Math.max(amount, MIN_CHARGE_CENTS));
        return Math.max(amount, MIN_CHARGE_CENTS);
    }

    private static long toCents(BigDecimal euros) {
        return euros.movePointRight(2).setScale(0, RoundingMode.HALF_UP).longValueExact();
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
