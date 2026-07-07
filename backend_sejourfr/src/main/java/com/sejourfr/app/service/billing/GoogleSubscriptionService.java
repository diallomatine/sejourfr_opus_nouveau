package com.sejourfr.app.service.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.services.androidpublisher.model.AutoRenewingPlan;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseLineItem;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseV2;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.util.LogMask;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProcessedExternalEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Logique métier Google Play Billing : activation à partir d'un
 * {@code purchaseToken} remonté par l'app mobile (verify-receipt) et
 * application des Real-time Developer Notifications (RTDN via Pub/Sub).
 *
 * <p>Clé d'unicité : {@code (GOOGLE, purchaseToken)}. Un même purchaseToken
 * Google reste stable sur toute la chaîne de renouvellements d'un user — c'est
 * notre {@code originalTransactionId}. Les renouvellements UPDATE la ligne
 * existante (nouveau {@code latestOrderId} et {@code expiryTime} repoussé).
 *
 * <p>Source de vérité : on appelle TOUJOURS {@code GoogleStoreClient.getSubscriptionV2}
 * pour obtenir l'état autoritatif côté Play, qu'on traite ensuite. La RTDN
 * sert uniquement de trigger ("quelque chose a changé sur ce token") ; on ne
 * lit jamais l'état directement dedans, comme recommandé par Google.
 *
 * <p>Idempotence webhook : chaque {@code messageId} Pub/Sub passé une fois
 * est stocké dans {@code processed_external_events}. Pub/Sub at-least-once :
 * un même messageId peut arriver plusieurs fois, on doit pouvoir l'ignorer.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GoogleSubscriptionService {

    private final GoogleStoreClient googleStoreClient;
    private final PlanManager planManager;
    private final UserManager userManager;
    private final UserSubscriptionManager userSubscriptionManager;
    private final ProcessedExternalEventManager processedEventManager;
    private final SubscriptionNotificationService subscriptionNotifier;
    private final OneTimeAccessService oneTimeAccessService;
    private final com.sejourfr.app.config.BillingProperties billingProperties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // ------------------------------------------------------------------------
    // verify-receipt : flow client → backend après un achat sur l'app
    // ------------------------------------------------------------------------

    /**
     * Active (ou rafraîchit) un abonnement Premium pour l'utilisateur authentifié
     * à partir d'un {@code purchaseToken} (Google Play Billing). Le backend
     * re-valide l'état contre l'API Play — on ne fait JAMAIS confiance au
     * client.
     *
     * @throws ResponseStatusException 400 si l'état Play ne contient pas le
     *         productId attendu, si on ne trouve pas le Plan correspondant,
     *         ou si l'API Play échoue ; 409 si le purchaseToken est déjà
     *         rattaché à un autre user.
     */
    @Transactional
    public UserSubscription activateFromReceipt(
            UUID userId, String expectedProductId, String purchaseToken) {
        log.info(
                "Google verify-receipt START user={} expectedProductId={} purchaseToken={}",
                userId, expectedProductId, LogMask.token(purchaseToken)
        );
        try {
            // Mode passes one-time (lot 5) : produit managed → API products.get
            // (et non subscriptionsv2). Grant commun, durée backend.
            if (billingProperties.isOneTime()) {
                return activateOneTimeProduct(userId, expectedProductId, purchaseToken);
            }

            SubscriptionPurchaseV2 state = fetchSubscriptionOrThrow(purchaseToken);

            SubscriptionPurchaseLineItem lineItem = pickPrimaryLineItem(state, expectedProductId);
            Plan plan = lookupPlanOrThrow(lineItem.getProductId());
            User user = userManager.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User introuvable: " + userId));

            // Restauration côté StoreKit/Play : verify-receipt peut être rappelé
            // sur un purchaseToken existant. Pas de mail de bienvenue dans ce cas.
            boolean isNew = userSubscriptionManager
                    .findBySourceAndOriginalTransactionId(SubscriptionSource.GOOGLE, purchaseToken)
                    .isEmpty();
            UserSubscription sub = upsert(user, plan, lineItem, state, purchaseToken);
            log.info(
                    "Google verify-receipt OK user={} productId={} purchaseToken={} status={} endsAt={} new={}",
                    userId, lineItem.getProductId(), LogMask.token(purchaseToken), sub.getStatus(), sub.getEndsAt(), isNew
            );
            if (isNew) {
                subscriptionNotifier.sendActivation(sub);
            }
            return sub;
        } catch (ResponseStatusException e) {
            // Rend visible côté serveur la raison exacte du refus (sinon le 400
            // est muet dans les logs et seul un message générique remonte à l'app).
            log.warn(
                    "Google verify-receipt REFUSÉ user={} expectedProductId={} purchaseToken={} → {} {}",
                    userId, expectedProductId, LogMask.token(purchaseToken),
                    e.getStatusCode(), e.getReason()
            );
            throw e;
        }
    }

    /**
     * Active un pass one-time (managed product) via {@code purchases.products.get}.
     * On valide l'état d'achat (purchaseState=0 Purchased), acquitte best-effort,
     * puis crédite via le grant commun. La consommation (ré-achat) est faite
     * côté client par in_app_purchase.
     */
    private UserSubscription activateOneTimeProduct(
            UUID userId, String expectedProductId, String purchaseToken) {
        com.google.api.services.androidpublisher.model.ProductPurchase pp;
        try {
            pp = googleStoreClient.getProduct(expectedProductId, purchaseToken);
        } catch (IOException e) {
            log.warn("Google getProduct a échoué (productId={}, token={}) : {}",
                    expectedProductId, LogMask.token(purchaseToken), e.getMessage(), e);
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Reçu Google invalide ou inaccessible : " + e.getMessage(), e);
        }
        // purchaseState : 0 = Purchased, 1 = Canceled, 2 = Pending.
        Integer purchaseState = pp.getPurchaseState();
        if (purchaseState != null && purchaseState != 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Achat Google non finalisé (purchaseState=" + purchaseState + ").");
        }
        Plan plan = lookupPlanOrThrow(expectedProductId);

        // Acquittement obligatoire sous 3 j (sinon refund auto). Best-effort :
        // un échec d'ack ne doit pas bloquer l'octroi de l'accès déjà payé.
        try {
            googleStoreClient.acknowledgeProduct(expectedProductId, purchaseToken);
        } catch (IOException e) {
            log.warn("Google acknowledgeProduct a échoué (productId={}) : {} — accès accordé quand même.",
                    expectedProductId, e.getMessage());
        }

        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                userId, plan, SubscriptionSource.GOOGLE, purchaseToken, pp.getOrderId());
        log.info("Google one-time pass user={} productId={} token={} endsAt={}",
                userId, expectedProductId, LogMask.token(purchaseToken), sub.getEndsAt());
        return sub;
    }

    // ------------------------------------------------------------------------
    // Webhook : Real-time Developer Notifications (Pub/Sub push)
    // ------------------------------------------------------------------------

    /**
     * Traite une RTDN reçue depuis Pub/Sub. Étapes :
     * <ol>
     *   <li>Vérifie le Bearer JWT Pub/Sub (signature, audience, email SA) →
     *       401 si invalide. Cf. {@link GoogleStoreClient#verifyPubSubBearer}.</li>
     *   <li>Décode le {@code message.data} (base64 → JSON).</li>
     *   <li>Idempotence : chaque {@code message.messageId} traité une fois est
     *       stocké, replays Pub/Sub at-least-once silencieusement skipés.</li>
     *   <li>Extrait {@code subscriptionNotification.purchaseToken} et
     *       {@code notificationType}.</li>
     *   <li>Appelle {@code subscriptionsv2.get(purchaseToken)} pour avoir
     *       l'état autoritatif (la RTDN ne porte pas le détail).</li>
     *   <li>Update {@code user_subscriptions} sur la clé
     *       {@code (GOOGLE, purchaseToken)}.</li>
     * </ol>
     */
    @Transactional
    public void handleNotification(String authHeader, String pubSubPayload) {
        googleStoreClient.verifyPubSubBearer(authHeader);

        JsonNode root;
        try {
            root = objectMapper.readTree(pubSubPayload);
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Payload Pub/Sub non parsable : " + e.getMessage(), e);
        }

        JsonNode message = root.path("message");
        String messageId = message.path("messageId").asText("");
        if (messageId.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "message.messageId manquant dans le payload Pub/Sub.");
        }

        if (!processedEventManager.tryMarkProcessed(
                SubscriptionSource.GOOGLE.providerKey(), messageId)) {
            log.info("Google RTDN messageId={} déjà traité — skip (replay Pub/Sub).", messageId);
            return;
        }

        String dataBase64 = message.path("data").asText("");
        if (dataBase64.isBlank()) {
            log.warn("Google RTDN messageId={} sans data — ignoré.", messageId);
            return;
        }

        JsonNode data;
        try {
            byte[] decoded = Base64.getDecoder().decode(dataBase64);
            data = objectMapper.readTree(decoded);
        } catch (IllegalArgumentException | IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "message.data Pub/Sub non décodable : " + e.getMessage(),
                    e
            );
        }

        // Mode passes one-time (lot 5) : on traite voidedPurchaseNotification
        // (refund/chargeback → REFUNDED) et on logue oneTimeProductNotification
        // (l'octroi se fait via verify-receipt). Pas de subscriptionNotification.
        if (billingProperties.isOneTime()) {
            handleOneTimeNotification(data, messageId);
            return;
        }

        // RTDN d'abonnement uniquement (on ignore voidedPurchaseNotification,
        // oneTimeProductNotification, testNotification — non utilisés pour
        // l'IAP Premium actuel).
        JsonNode subNotif = data.path("subscriptionNotification");
        if (subNotif.isMissingNode() || subNotif.isNull()) {
            JsonNode testNotif = data.path("testNotification");
            if (!testNotif.isMissingNode() && !testNotif.isNull()) {
                log.info("Google RTDN testNotification messageId={} — pas d'impact.", messageId);
                return;
            }
            log.warn(
                    "Google RTDN messageId={} sans subscriptionNotification — ignoré (payload={}).",
                    messageId, data
            );
            return;
        }

        int notificationType = subNotif.path("notificationType").asInt(-1);
        String purchaseToken = subNotif.path("purchaseToken").asText("");
        if (purchaseToken.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "subscriptionNotification.purchaseToken manquant.");
        }

        Optional<UserSubscription> existing = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.GOOGLE, purchaseToken);

        if (existing.isEmpty()) {
            // Cas usuel : RTDN reçue pour un user qui n'a pas (encore) appelé
            // verify-receipt — l'app a planté ou est offline. On log et on
            // attend que l'app revienne ; pas de création sans userId.
            log.warn(
                    "Google RTDN messageId={} type={} purchaseToken={} : aucune subscription locale, ignorée.",
                    messageId, notificationType, LogMask.token(purchaseToken)
            );
            return;
        }

        UserSubscription sub = existing.get();

        // SUBSCRIPTION_REVOKED (12) → traitement spécial : Premium retiré
        // immédiatement, indépendamment de l'état renvoyé par l'API. La V2
        // peut encore montrer ACTIVE temporairement le temps que l'état se
        // propage.
        if (notificationType == GoogleNotificationType.SUBSCRIPTION_REVOKED) {
            sub.setStatus(SubscriptionStatus.REFUNDED);
            sub.setAutoRenew(false);
            userSubscriptionManager.save(sub);
            log.info("Google RTDN REVOKED appliqué user={} purchaseToken={}",
                    sub.getUser().getId(), LogMask.token(purchaseToken));
            return;
        }

        // Refetch l'état autoritatif côté Play et applique-le. Sans ça on
        // se fie à un timestamp dans la notification qui peut être en retard.
        SubscriptionPurchaseV2 state;
        try {
            state = googleStoreClient.getSubscriptionV2(purchaseToken);
        } catch (IOException e) {
            // Si l'API Play est down, on rend 502 pour que Pub/Sub retente.
            // L'event sort de processed_external_events via le rollback de la
            // transaction (insertion + side-effect dans la même @Transactional).
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "Échec refetch état Google Play : " + e.getMessage(),
                    e
            );
        }

        SubscriptionPurchaseLineItem lineItem = pickPrimaryLineItem(state, null);
        SubscriptionStatus oldStatus = sub.getStatus();
        sub.setProductId(lineItem.getProductId());
        sub.setExternalTransactionId(state.getLatestOrderId());
        sub.setEndsAt(parseExpiry(lineItem.getExpiryTime(), sub.getEndsAt()));
        sub.setAutoRenew(deriveAutoRenew(lineItem, sub.isAutoRenew()));
        sub.setStatus(mapSubscriptionState(state.getSubscriptionState(), sub.getStatus()));

        userSubscriptionManager.save(sub);

        // Mail de résiliation UNIQUEMENT sur transition vers CANCELED. Pas
        // d'envoi si CANCELED → CANCELED (replay RTDN ; Pub/Sub at-least-once).
        if (oldStatus != SubscriptionStatus.CANCELED
                && sub.getStatus() == SubscriptionStatus.CANCELED) {
            subscriptionNotifier.sendCancellation(sub);
        }
        log.info(
                "Google RTDN type={} messageId={} appliqué user={} status={} endsAt={} autoRenew={}",
                notificationType, messageId,
                sub.getUser().getId(), sub.getStatus(), sub.getEndsAt(), sub.isAutoRenew()
        );
    }

    /**
     * RTDN en mode passes one-time : refund/chargeback → REFUNDED. L'achat
     * (oneTimeProductNotification PURCHASED) est crédité via verify-receipt, on
     * se contente de loguer ici (pas de mapping userId sans ligne existante).
     */
    private void handleOneTimeNotification(JsonNode data, String messageId) {
        JsonNode voided = data.path("voidedPurchaseNotification");
        if (!voided.isMissingNode() && !voided.isNull()) {
            String token = voided.path("purchaseToken").asText("");
            if (token.isBlank()) {
                log.warn("Google RTDN voided messageId={} sans purchaseToken — ignoré.", messageId);
                return;
            }
            userSubscriptionManager
                    .findBySourceAndOriginalTransactionId(SubscriptionSource.GOOGLE, token)
                    .ifPresentOrElse(sub -> {
                        sub.setStatus(SubscriptionStatus.REFUNDED);
                        sub.setAutoRenew(false);
                        userSubscriptionManager.save(sub);
                        log.info("Google one-time voided/refund user={} token={}",
                                sub.getUser().getId(), LogMask.token(token));
                    }, () -> log.warn(
                            "Google RTDN voided messageId={} token={} : aucune subscription locale.",
                            messageId, LogMask.token(token)));
            return;
        }
        JsonNode oneTime = data.path("oneTimeProductNotification");
        if (!oneTime.isMissingNode() && !oneTime.isNull()) {
            log.info("Google one-time product notif messageId={} sku={} type={} — octroi via verify-receipt.",
                    messageId, oneTime.path("sku").asText(""),
                    oneTime.path("notificationType").asInt(-1));
            return;
        }
        JsonNode testNotif = data.path("testNotification");
        if (!testNotif.isMissingNode() && !testNotif.isNull()) {
            log.info("Google RTDN testNotification messageId={} (one-time) — pas d'impact.", messageId);
            return;
        }
        log.warn("Google RTDN one-time messageId={} sans notif exploitable — ignoré (payload={}).",
                messageId, data);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private SubscriptionPurchaseV2 fetchSubscriptionOrThrow(String purchaseToken) {
        try {
            return googleStoreClient.getSubscriptionV2(purchaseToken);
        } catch (IOException e) {
            // L'exception Google (GoogleJsonResponseException) porte le vrai motif
            // (403 permissions SA, 404 token/package, API non activée…) — on la
            // trace en entier, c'est la donnée clé pour diagnostiquer.
            log.warn("Google getSubscriptionV2 a échoué (purchaseToken={}) : {}",
                    LogMask.token(purchaseToken), e.getMessage(), e);
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Reçu Google invalide ou inaccessible : " + e.getMessage(),
                    e
            );
        }
    }

    /**
     * Sélectionne le line item à utiliser pour l'upsert. En pratique Play
     * renvoie 1 seul line item pour les abonnements simples ; on prend le
     * premier qui matche {@code expectedProductId} si fourni, sinon le
     * premier tout court. Lève 400 si match attendu et pas trouvé.
     */
    private SubscriptionPurchaseLineItem pickPrimaryLineItem(
            SubscriptionPurchaseV2 state, String expectedProductId) {
        List<SubscriptionPurchaseLineItem> items = state.getLineItems();
        if (items == null || items.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "État Google Play sans lineItems.");
        }
        if (expectedProductId == null) {
            return items.get(0);
        }
        return items.stream()
                .filter(li -> expectedProductId.equals(li.getProductId()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le productId Play (" + items.get(0).getProductId()
                                + ") ne correspond pas à celui annoncé (" + expectedProductId + ")."
                ));
    }

    private Plan lookupPlanOrThrow(String productId) {
        return planManager.findByGoogleProductId(productId).orElseThrow(() ->
                new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Aucun Plan configuré pour googleProductId=" + productId
                                + " (renseigner plans.google_product_id en DB)."
                )
        );
    }

    private UserSubscription upsert(
            User user,
            Plan plan,
            SubscriptionPurchaseLineItem lineItem,
            SubscriptionPurchaseV2 state,
            String purchaseToken) {
        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(SubscriptionSource.GOOGLE, purchaseToken)
                .orElse(null);

        boolean created = sub == null;
        if (created) {
            sub = new UserSubscription();
            sub.setUser(user);
            sub.setSource(SubscriptionSource.GOOGLE);
            sub.setOriginalTransactionId(purchaseToken);
            sub.setStartsAt(Instant.now());
        } else if (!sub.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce reçu Google est déjà rattaché à un autre compte."
            );
        }

        sub.setPlan(plan);
        sub.setProductId(lineItem.getProductId());
        sub.setExternalTransactionId(state.getLatestOrderId());
        sub.setEndsAt(parseExpiry(lineItem.getExpiryTime(), null));
        sub.setAutoRenew(deriveAutoRenew(lineItem, true));
        sub.setStatus(mapSubscriptionState(state.getSubscriptionState(), SubscriptionStatus.ACTIVE));
        // Sessions EO temps réel : allocation du pass à la 1re souscription.
        // TODO (récurrent dormant) : re-créditer à chaque renouvellement — non
        // implémenté (mode ONE_TIME actif, cf. OneTimeAccessService).
        if (created) {
            sub.setRealtimeEoSessionsRemaining(Math.max(0, plan.getRealtimeEoSessions()));
        }
        return userSubscriptionManager.save(sub);
    }

    /**
     * Mappe la string {@code subscriptionState} renvoyée par l'API Play
     * (ex: "SUBSCRIPTION_STATE_ACTIVE") vers notre vocabulaire commun.
     */
    private SubscriptionStatus mapSubscriptionState(String state, SubscriptionStatus fallback) {
        if (state == null) return fallback;
        return switch (state) {
            case "SUBSCRIPTION_STATE_ACTIVE" -> SubscriptionStatus.ACTIVE;
            case "SUBSCRIPTION_STATE_CANCELED" -> SubscriptionStatus.CANCELED;
            case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" -> SubscriptionStatus.IN_GRACE;
            case "SUBSCRIPTION_STATE_ON_HOLD",
                 "SUBSCRIPTION_STATE_PAUSED",
                 "SUBSCRIPTION_STATE_EXPIRED" -> SubscriptionStatus.EXPIRED;
            case "SUBSCRIPTION_STATE_PENDING" -> SubscriptionStatus.PENDING;
            case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED" -> SubscriptionStatus.REFUNDED;
            default -> {
                log.warn("Google subscriptionState inattendu : {}", state);
                yield fallback;
            }
        };
    }

    private boolean deriveAutoRenew(SubscriptionPurchaseLineItem lineItem, boolean fallback) {
        AutoRenewingPlan plan = lineItem.getAutoRenewingPlan();
        if (plan == null || plan.getAutoRenewEnabled() == null) {
            return fallback;
        }
        return plan.getAutoRenewEnabled();
    }

    /**
     * Parse l'expiryTime ISO-8601 renvoyé par Play (ex:
     * {@code "2026-07-15T10:00:00.000Z"}) en Instant. Retourne {@code fallback}
     * si parsing échoue, pour ne pas casser un upsert sur un format inattendu.
     */
    private Instant parseExpiry(String expiryTime, Instant fallback) {
        if (expiryTime == null || expiryTime.isBlank()) return fallback;
        try {
            return Instant.parse(expiryTime);
        } catch (DateTimeParseException e) {
            log.warn("Google expiryTime non parsable : {} ({})", expiryTime, e.getMessage());
            return fallback;
        }
    }

    /**
     * Constantes des notification types RTDN. Google les expose en int dans le
     * JSON ; on garde un mini-registre ici pour les types qui ont un traitement
     * spécifique. Cf. https://developer.android.com/google/play/billing/rtdn-reference
     */
    private static final class GoogleNotificationType {
        static final int SUBSCRIPTION_REVOKED = 12;
        private GoogleNotificationType() {}
    }
}
