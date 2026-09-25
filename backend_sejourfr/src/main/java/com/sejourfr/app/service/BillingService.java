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
import com.sejourfr.app.service.billing.PurchaseIntentService;
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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
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
    private final PurchaseIntentService purchaseIntentService;

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
                                                  String retour, ClientContext client) {
        return getPaymentLink(userId, planCode, retour, null, null, client);
    }

    /**
     * Variante attribuée (chantier Suivi, Q12) : {@code ctaLocation} (valeur de
     * {@code AnalyticsCtaLocation}) et {@code journeyId} créent une
     * {@code purchase_intent} serveur AVANT la session, transportée par
     * {@code metadata.intentId}. Les deux sont facultatifs et ne bloquent
     * jamais le paiement : sans CTA lisible, pas d'intention, et l'achat sera
     * rangé {@code UNKNOWN}.
     */
    public BillingCheckoutResponse getPaymentLink(UUID userId, String planCode, String retour,
                                                  String ctaLocation, String journeyId,
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
            String intentId = purchaseIntentService
                    .creerPourCheckout(userId, plan, ctaLocation, journeyId, client)
                    .map(UUID::toString)
                    .orElse(null);
            return createOneTimeCheckout(user, plan, retour, client, intentId);
        }

        String priceId = plan.getStripePriceId();
        if (priceId == null || priceId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Plan " + planCode + " sans stripe_price_id configuré — voir Stripe Dashboard."
            );
        }

        // Placeholder remplacé par Stripe avant la redirection.
        String successUrl = checkoutSuccessUrl(planCode, retour);
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
     * Où revient le candidat quand le paiement a <b>réussi</b> : la page de
     * succès, et — quand le client l'a demandé — l'écran d'où il était parti.
     *
     * <p><b>L'unique endroit qui compose la {@code success_url}</b>, pour les
     * deux modes de Checkout (SUBSCRIPTION et one-time PAYMENT). Deux copies du
     * même {@code if} auraient fini par ne valider qu'une des deux.
     *
     * <h4>⚠️ L'exception à « aucun chemin de retour ne vient du client »</h4>
     *
     * <p>{@link #checkoutCancelUrl} dit, à raison, qu'aucun chemin de retour ne
     * vient du client. {@code retour} est l'exception, et elle est <b>voulue</b> :
     * sans elle, un candidat parti du Plan revenait de Stripe sur une page
     * d'atterrissage sans rien à dépiler, au lieu de retrouver son écran. La
     * différence avec une redirection ouverte tient à trois faits :
     *
     * <ul>
     *   <li><b>C'est un CHEMIN, jamais une URL.</b> {@link #cheminDeRetour}
     *       n'accepte qu'une valeur commençant par {@code /} et refuse
     *       {@code //} et {@code /\} — les deux formes
     *       <i>protocol-relative</i>, qui sont l'open-redirect classique
     *       ({@code //evil.com} est une URL absolue pour un navigateur). Aucun
     *       hôte, aucun schéma ne peut passer.</li>
     *   <li><b>L'hôte reste le NÔTRE.</b> Le chemin est concaténé derrière
     *       {@code appBaseUrl}, qui vient de la configuration serveur — il ne
     *       remplace jamais l'origine, il la suit.</li>
     *   <li><b>La valeur est ENCODÉE</b> ({@link URLEncoder}), donc elle ne peut
     *       ni ajouter un paramètre, ni couper la query, ni glisser un
     *       {@code \r\n}. 🛑 Seule la valeur l'est : le marqueur
     *       {@code {CHECKOUT_SESSION_ID}} est substitué par <b>Stripe</b> et
     *       doit rester littéral — l'encoder le casserait.</li>
     * </ul>
     *
     * <p>🛑 <b>Un chemin refusé est ignoré en silence</b> : on retombe sur la
     * {@code success_url} d'avant. Un lien malformé ne doit jamais empêcher
     * quelqu'un de payer — et le front, qui repasse la valeur par son
     * {@code safeInternalPath}, a de toute façon le dernier mot.
     */
    private String checkoutSuccessUrl(String planCode, String retour) {
        String url = stripeProperties.getAppBaseUrl() + "/paiement/succes"
                + "?session_id={CHECKOUT_SESSION_ID}&plan=" + planCode;
        String chemin = cheminDeRetour(retour);
        return chemin == null
                ? url
                : url + "&retour=" + URLEncoder.encode(chemin, StandardCharsets.UTF_8);
    }

    /**
     * Le chemin de retour <b>accepté</b>, ou {@code null} — l'unique autorité de
     * validation, volontairement restrictive et sans exception.
     *
     * <p>Refuse : l'absence, le vide, ce qui ne commence pas par {@code /},
     * {@code //} et {@code /\} (protocol-relative), tout caractère de contrôle,
     * et au-delà de {@value #RETOUR_MAX_LEN} caractères. Aucune tentative de
     * « réparer » une valeur : elle passe telle quelle, ou elle n'existe pas.
     */
    private static String cheminDeRetour(String retour) {
        if (retour == null || retour.isBlank()) return null;
        if (retour.length() > RETOUR_MAX_LEN) return null;
        if (retour.charAt(0) != '/') return null;
        if (retour.length() > 1) {
            char second = retour.charAt(1);
            if (second == '/' || second == '\\') return null;
        }
        for (int i = 0; i < retour.length(); i++) {
            char c = retour.charAt(i);
            if (c < 0x20 || c == 0x7F) return null;
        }
        return retour;
    }

    /** Un chemin d'app, pas une charge utile : au-delà, c'est autre chose. */
    private static final int RETOUR_MAX_LEN = 512;

    /**
     * Checkout one-time (mode PAYMENT) : montant = prix du plan en base, via
     * {@code price_data} dynamique (aucun Stripe Price à créer). Le {@code planCode}
     * voyage en metadata pour que le webhook sache quel pass créditer ; le
     * {@code payment_intent} servira de clé d'unicité côté grant.
     */
    private BillingCheckoutResponse createOneTimeCheckout(User user, Plan plan,
                                                          String retour,
                                                          ClientContext client,
                                                          String intentId) {
        long amountCents = computeOneTimeAmountCents(user.getId(), plan);
        String successUrl = checkoutSuccessUrl(plan.getCode(), retour);
        String cancelUrl = checkoutCancelUrl(plan.getCode());

        SessionCreateParams.Builder builder = SessionCreateParams.builder();
        if (intentId != null) {
            builder.putMetadata(StripeSubscriptionService.METADATA_INTENT_ID, intentId);
        }
        SessionCreateParams params = builder
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

        // 🛑 PAS de garde sur l'âge de l'évènement (bug Q11). Stripe conserve le
        // `created` d'origine sur ses relances automatiques (jusqu'à 3 jours) :
        // l'ancienne garde de 300 s rejetait définitivement toute relance
        // légitime au-delà de 5 min, et l'achat n'était jamais crédité. Le
        // rejeu est tenu par (1) `Webhook.constructEvent`, dont la tolérance de
        // 300 s porte sur l'horodatage de la SIGNATURE, régénéré à chaque
        // livraison, et (2) l'idempotence ci-dessous sur l'id d'évènement.

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
