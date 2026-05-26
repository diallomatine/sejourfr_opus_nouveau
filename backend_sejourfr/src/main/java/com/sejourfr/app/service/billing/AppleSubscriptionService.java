package com.sejourfr.app.service.billing;

import com.apple.itunes.storekit.client.APIException;
import com.apple.itunes.storekit.model.AutoRenewStatus;
import com.apple.itunes.storekit.model.Data;
import com.apple.itunes.storekit.model.JWSRenewalInfoDecodedPayload;
import com.apple.itunes.storekit.model.JWSTransactionDecodedPayload;
import com.apple.itunes.storekit.model.NotificationTypeV2;
import com.apple.itunes.storekit.model.ResponseBodyV2DecodedPayload;
import com.apple.itunes.storekit.model.Subtype;
import com.apple.itunes.storekit.model.Type;
import com.apple.itunes.storekit.verification.VerificationException;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
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
import java.util.Optional;
import java.util.UUID;

/**
 * Logique métier Apple IAP : activation à partir d'un reçu remonté par l'app
 * mobile (verify-receipt) et application des notifications serveur-à-serveur
 * (ASSN V2).
 *
 * <p>Garantie d'unicité : un même {@code (APPLE, originalTransactionId)} ne
 * peut pointer que vers une seule ligne {@code user_subscriptions}. Les
 * renouvellements UPDATE la ligne existante ; ils n'en créent pas une
 * nouvelle. Verrou matériel : index unique
 * {@code ux_user_subscriptions_source_original} (migration V103).
 *
 * <p>Idempotence webhook : chaque {@code notificationUUID} passé une fois est
 * stocké dans {@code processed_external_events}. Un replay du même
 * notificationUUID est silencieusement skipé.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AppleSubscriptionService {

    private final AppleStoreClient appleStoreClient;
    private final PlanManager planManager;
    private final UserManager userManager;
    private final UserSubscriptionManager userSubscriptionManager;
    private final ProcessedExternalEventManager processedEventManager;

    // ------------------------------------------------------------------------
    // verify-receipt : flow client → backend après un achat sur l'app
    // ------------------------------------------------------------------------

    /**
     * Active (ou rafraîchit) un abonnement Premium pour l'utilisateur authentifié
     * à partir d'un {@code signedTransactionInfo} (JWS Apple). Le backend
     * re-vérifie la signature contre la chaîne de certifs Apple — on ne fait
     * JAMAIS confiance au client.
     *
     * <p>Cas usuels :
     * <ul>
     *   <li>Premier achat : crée une ligne.</li>
     *   <li>Restauration d'achat (l'app mobile appelle {@code restorePurchases}) :
     *       retrouve la ligne existante et la rafraîchit avec l'état courant.</li>
     *   <li>Renouvellement : la notification webhook a déjà mis à jour
     *       {@code endsAt} ; ce flow ré-update à l'identique. Idempotent.</li>
     * </ul>
     *
     * @throws ResponseStatusException 400 si la signature est invalide / le
     *         productId ne correspond pas à un Plan / le type n'est pas
     *         auto-renouvelable ; 409 si le reçu appartient à un autre user
     *         (anti-account-stealing).
     */
    @Transactional
    public UserSubscription activateFromReceipt(
            UUID userId, String expectedProductId, String signedTransactionInfo) {
        log.info(
                "Apple verify-receipt START user={} expectedProductId={}",
                userId, expectedProductId
        );
        try {
            JWSTransactionDecodedPayload tx = decodeTransaction(signedTransactionInfo);

            if (!expectedProductId.equals(tx.getProductId())) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Le productId du reçu (" + tx.getProductId()
                                + ") ne correspond pas à celui annoncé (" + expectedProductId + ")."
                );
            }

            Plan plan = lookupPlanOrThrow(tx.getProductId());
            User user = userManager.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User introuvable: " + userId));

            UserSubscription sub = upsert(user, plan, tx, /* renewalInfo */ null);
            log.info(
                    "Apple verify-receipt OK user={} productId={} originalTxId={} endsAt={}",
                    userId, tx.getProductId(), tx.getOriginalTransactionId(), sub.getEndsAt()
            );
            return sub;
        } catch (ResponseStatusException e) {
            // Rend visible la raison exacte du refus (sinon le 400 est muet côté
            // serveur et seul un message générique remonte à l'app).
            log.warn(
                    "Apple verify-receipt REFUSÉ user={} expectedProductId={} → {} {}",
                    userId, expectedProductId, e.getStatusCode(), e.getReason()
            );
            throw e;
        }
    }

    // ------------------------------------------------------------------------
    // Webhook : App Store Server Notifications V2 (signed payload)
    // ------------------------------------------------------------------------

    /**
     * Traite une notification ASSN V2 signée. Idempotent : un même
     * {@code notificationUUID} ne change l'état qu'une fois, les rejouens
     * suivants sont skipés.
     *
     * <p>Types gérés explicitement : SUBSCRIBED, DID_RENEW, EXPIRED,
     * DID_FAIL_TO_RENEW, GRACE_PERIOD_EXPIRED, DID_CHANGE_RENEWAL_STATUS,
     * REFUND, REVOKE, REFUND_REVERSED. Les autres (PRICE_INCREASE,
     * METADATA_UPDATE, TEST, ...) sont logués et ignorés sans erreur.
     */
    @Transactional
    public void handleNotification(String signedPayload) {
        ResponseBodyV2DecodedPayload payload = decodeNotification(signedPayload);
        String notificationUUID = payload.getNotificationUUID();

        if (!processedEventManager.tryMarkProcessed(
                SubscriptionSource.APPLE.providerKey(), notificationUUID)) {
            log.info("Apple notification {} déjà traitée — skip (replay).", notificationUUID);
            return;
        }

        NotificationTypeV2 type = payload.getNotificationType();
        Subtype subtype = payload.getSubtype();
        Data data = payload.getData();
        if (data == null) {
            log.warn("Apple notification {} (type={}) sans data — ignorée.", notificationUUID, type);
            return;
        }

        JWSTransactionDecodedPayload tx = decodeTransaction(data.getSignedTransactionInfo());
        JWSRenewalInfoDecodedPayload renewalInfo = data.getSignedRenewalInfo() != null
                ? decodeRenewalInfo(data.getSignedRenewalInfo())
                : null;

        Optional<UserSubscription> existing = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.APPLE, tx.getOriginalTransactionId());

        if (existing.isEmpty()) {
            // Notification reçue pour un user qu'on ne connaît pas (jamais
            // de verify-receipt passé pour ce reçu). Cas possible : le mobile
            // a planté avant verify-receipt mais Apple nous notifie quand
            // même. On log et on attendra que l'app revienne avec un
            // verify-receipt — pas de création silencieuse sans userId.
            log.warn(
                    "Apple notification {} (type={}) pour originalTxId={} : aucune subscription locale, ignorée.",
                    notificationUUID, type, tx.getOriginalTransactionId()
            );
            return;
        }

        UserSubscription sub = existing.get();
        Plan plan = sub.getPlan();
        applyNotificationTransition(sub, type, subtype, tx, renewalInfo);
        sub.setPlan(plan); // garantir que la FK reste posée
        userSubscriptionManager.save(sub);

        log.info(
                "Apple notification {} (type={}, subtype={}) appliquée user={} status={} endsAt={} autoRenew={}",
                notificationUUID, type, subtype,
                sub.getUser().getId(), sub.getStatus(), sub.getEndsAt(), sub.isAutoRenew()
        );
    }

    // ------------------------------------------------------------------------
    // Helpers — décodage JWS
    // ------------------------------------------------------------------------

    private JWSTransactionDecodedPayload decodeTransaction(String signedTransactionInfo) {
        if (signedTransactionInfo == null || signedTransactionInfo.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "signedTransactionInfo manquant.");
        }
        try {
            return appleStoreClient.verifyTransaction(signedTransactionInfo);
        } catch (VerificationException e) {
            // Motif fréquent : APPLE_BUNDLE_ID ou APPLE_ENVIRONMENT qui ne
            // matchent pas le reçu (bundle réel de l'app / Sandbox vs Production),
            // ou chaîne de certifs racine incomplète. On trace tout.
            log.warn("Apple verifyTransaction a échoué : {}", e.getMessage(), e);
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Signature JWS Apple invalide : " + e.getMessage(),
                    e
            );
        }
    }

    private ResponseBodyV2DecodedPayload decodeNotification(String signedPayload) {
        try {
            return appleStoreClient.verifyNotification(signedPayload);
        } catch (VerificationException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Signature ASSN V2 invalide : " + e.getMessage(),
                    e
            );
        }
    }

    private JWSRenewalInfoDecodedPayload decodeRenewalInfo(String signedRenewalInfo) {
        try {
            return appleStoreClient.verifyRenewalInfo(signedRenewalInfo);
        } catch (VerificationException e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Signature renewal info invalide : " + e.getMessage(),
                    e
            );
        }
    }

    // ------------------------------------------------------------------------
    // Helpers — upsert + état
    // ------------------------------------------------------------------------

    private Plan lookupPlanOrThrow(String productId) {
        return planManager.findByAppleProductId(productId).orElseThrow(() ->
                new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Aucun Plan configuré pour appleProductId=" + productId
                                + " (renseigner plans.apple_product_id en DB)."
                )
        );
    }

    /**
     * Crée ou met à jour la ligne {@code user_subscriptions} pour le couple
     * {@code (APPLE, tx.originalTransactionId)}.
     */
    private UserSubscription upsert(
            User user,
            Plan plan,
            JWSTransactionDecodedPayload tx,
            JWSRenewalInfoDecodedPayload renewalInfo) {
        if (tx.getType() != Type.AUTO_RENEWABLE_SUBSCRIPTION) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Type de produit Apple non supporté pour le Premium : " + tx.getType()
                            + " — seul AUTO_RENEWABLE_SUBSCRIPTION est accepté."
            );
        }

        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(
                        SubscriptionSource.APPLE, tx.getOriginalTransactionId())
                .orElse(null);

        if (sub == null) {
            sub = new UserSubscription();
            sub.setUser(user);
            sub.setSource(SubscriptionSource.APPLE);
            sub.setOriginalTransactionId(tx.getOriginalTransactionId());
            sub.setStartsAt(toInstant(tx.getPurchaseDate(), Instant.now()));
        } else if (!sub.getUser().getId().equals(user.getId())) {
            // Sécurité : un même originalTransactionId Apple ne peut pas
            // changer de user (Family Sharing géré séparément à terme).
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce reçu Apple est déjà rattaché à un autre compte."
            );
        }

        sub.setPlan(plan);
        sub.setProductId(tx.getProductId());
        sub.setExternalTransactionId(tx.getTransactionId());
        sub.setEndsAt(toInstant(tx.getExpiresDate(), null));
        sub.setStatus(deriveStatusFromTransaction(tx));
        sub.setAutoRenew(deriveAutoRenew(renewalInfo, true /* défaut ARS = on */));
        return userSubscriptionManager.save(sub);
    }

    private void applyNotificationTransition(
            UserSubscription sub,
            NotificationTypeV2 type,
            Subtype subtype,
            JWSTransactionDecodedPayload tx,
            JWSRenewalInfoDecodedPayload renewalInfo) {
        // Toujours mettre à jour les champs "fait" depuis la transaction —
        // c'est la source de vérité.
        sub.setExternalTransactionId(tx.getTransactionId());
        sub.setEndsAt(toInstant(tx.getExpiresDate(), sub.getEndsAt()));
        sub.setAutoRenew(deriveAutoRenew(renewalInfo, sub.isAutoRenew()));

        switch (type) {
            case SUBSCRIBED, DID_RENEW, OFFER_REDEEMED -> sub.setStatus(SubscriptionStatus.ACTIVE);
            case EXPIRED, GRACE_PERIOD_EXPIRED -> sub.setStatus(SubscriptionStatus.EXPIRED);
            case DID_FAIL_TO_RENEW -> {
                // Avec subtype=GRACE_PERIOD, Apple donne au user une période
                // de grâce avant de couper. Sans subtype, le retry de paiement
                // a échoué mais l'abonnement court encore jusqu'à expiresDate.
                if (subtype == Subtype.GRACE_PERIOD) {
                    sub.setStatus(SubscriptionStatus.IN_GRACE);
                } else {
                    // L'abonnement reste ACTIVE tant que ends_at est dans le
                    // futur — pas de transition de statut, juste le log.
                }
            }
            case DID_CHANGE_RENEWAL_STATUS -> {
                // autoRenew déjà mis à jour ci-dessus via renewalInfo. Si user
                // a désactivé le renouvellement, on ne touche pas au statut :
                // ACTIVE jusqu'à expiresDate, puis EXPIRED via la notif EXPIRED.
                if (subtype == Subtype.AUTO_RENEW_DISABLED) {
                    sub.setStatus(SubscriptionStatus.CANCELED);
                } else if (subtype == Subtype.AUTO_RENEW_ENABLED
                        && sub.getStatus() == SubscriptionStatus.CANCELED) {
                    // Le user a réactivé le renouvellement avant la fin —
                    // on repasse ACTIVE.
                    sub.setStatus(SubscriptionStatus.ACTIVE);
                }
            }
            case REFUND, REVOKE -> sub.setStatus(SubscriptionStatus.REFUNDED);
            case REFUND_REVERSED -> {
                // Apple a annulé le remboursement : on remet ACTIVE si la date
                // de fin couvre encore.
                if (sub.getEndsAt() != null && sub.getEndsAt().isAfter(Instant.now())) {
                    sub.setStatus(SubscriptionStatus.ACTIVE);
                }
            }
            case DID_CHANGE_RENEWAL_PREF -> {
                // L'user a changé de produit pour le prochain renouvellement.
                // Le productId courant reste valide jusqu'à expiresDate. Pas
                // de transition à appliquer maintenant.
            }
            default -> {
                // PRICE_INCREASE, METADATA_UPDATE, TEST, MIGRATION,
                // PRICE_CHANGE, CONSUMPTION_REQUEST, etc. — pas d'impact sur
                // l'accès Premium, on log et on laisse l'état tel quel.
                log.debug("Apple notification type={} ignorée (pas d'impact Premium).", type);
            }
        }
    }

    private SubscriptionStatus deriveStatusFromTransaction(JWSTransactionDecodedPayload tx) {
        if (tx.getRevocationDate() != null) {
            return SubscriptionStatus.REFUNDED;
        }
        Instant expiresAt = toInstant(tx.getExpiresDate(), null);
        if (expiresAt != null && expiresAt.isBefore(Instant.now())) {
            return SubscriptionStatus.EXPIRED;
        }
        return SubscriptionStatus.ACTIVE;
    }

    private boolean deriveAutoRenew(JWSRenewalInfoDecodedPayload renewalInfo, boolean fallback) {
        if (renewalInfo == null || renewalInfo.getAutoRenewStatus() == null) {
            return fallback;
        }
        return renewalInfo.getAutoRenewStatus() == AutoRenewStatus.ON;
    }

    private static Instant toInstant(Long millis, Instant fallback) {
        return millis != null ? Instant.ofEpochMilli(millis) : fallback;
    }

    // ------------------------------------------------------------------------
    // Utilitaire : re-fetch côté Apple si on veut confirmer (lot 3 / debug)
    // ------------------------------------------------------------------------

    /**
     * Lecture autoritative d'une transaction depuis l'App Store Server API.
     * Non utilisé par défaut dans le flow nominal (la verif JWS suffit), mais
     * exposé pour les debugs / outils admin futurs.
     */
    public Optional<JWSTransactionDecodedPayload> fetchTransactionInfo(String transactionId) {
        try {
            return Optional.of(appleStoreClient.getTransactionInfo(transactionId));
        } catch (APIException | IOException | VerificationException e) {
            log.warn("Apple getTransactionInfo({}) a échoué : {}", transactionId, e.getMessage());
            return Optional.empty();
        }
    }
}
