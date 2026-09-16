package com.sejourfr.app.service.billing;

import com.apple.itunes.storekit.model.Data;
import com.apple.itunes.storekit.model.JWSTransactionDecodedPayload;
import com.apple.itunes.storekit.model.NotificationTypeV2;
import com.apple.itunes.storekit.model.ResponseBodyV2DecodedPayload;
import com.apple.itunes.storekit.model.Subtype;
import com.apple.itunes.storekit.model.Type;
import com.apple.itunes.storekit.verification.VerificationException;
import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProcessedExternalEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre Apple IAP en mode abonnement : verify-receipt (création + mappings
 * d'erreur 400 productId/plan/type, anti-account-stealing 409, signature
 * invalide 400) et les transitions de notification ASSN V2 (idempotence,
 * DID_CHANGE_RENEWAL_STATUS→CANCELED, REFUND→REFUNDED, SUBSCRIBED→ACTIVE).
 * Le client Apple est mocké (on n'a pas de JWS signé à forger).
 */
class AppleSubscriptionServiceTest {

    private AppleStoreClient appleStoreClient;
    private PlanManager planManager;
    private UserManager userManager;
    private UserSubscriptionManager userSubscriptionManager;
    private ProcessedExternalEventManager processedEventManager;
    private MailService mailService;
    private BillingProperties billingProperties;
    private AppleSubscriptionService service;

    private final UUID userId = UUID.randomUUID();
    private User user;
    private Plan plan;

    @BeforeEach
    void setUp() {
        appleStoreClient = mock(AppleStoreClient.class);
        planManager = mock(PlanManager.class);
        userManager = mock(UserManager.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        processedEventManager = mock(ProcessedExternalEventManager.class);
        mailService = mock(MailService.class);
        OneTimeAccessService oneTimeAccessService = mock(OneTimeAccessService.class);
        billingProperties = mock(BillingProperties.class); // isOneTime() = false par défaut
        service = new AppleSubscriptionService(
                appleStoreClient, planManager, userManager, userSubscriptionManager,
                processedEventManager, new SubscriptionNotificationService(mailService),
                oneTimeAccessService, billingProperties,
                new MontantEncaisseResolver(new com.sejourfr.app.config.AnalyticsProperties()));

        user = new User();
        user.setId(userId);
        user.setEmail("u@sejourfr.fr");
        user.setFirstName("Lea");
        plan = new Plan();
        plan.setName("Intégral");
        plan.setModuleAccess(ModuleAccess.INTEGRAL);

        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        when(userSubscriptionManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private JWSTransactionDecodedPayload txMock(
            String productId, String origTx, String txId, Type type, Long expiresFutureDays) {
        JWSTransactionDecodedPayload tx = mock(JWSTransactionDecodedPayload.class);
        when(tx.getProductId()).thenReturn(productId);
        when(tx.getOriginalTransactionId()).thenReturn(origTx);
        when(tx.getTransactionId()).thenReturn(txId);
        when(tx.getType()).thenReturn(type);
        when(tx.getRevocationDate()).thenReturn(null);
        when(tx.getExpiresDate()).thenReturn(
                Instant.now().plus(expiresFutureDays, ChronoUnit.DAYS).toEpochMilli());
        when(tx.getPurchaseDate()).thenReturn(Instant.now().toEpochMilli());
        return tx;
    }

    // ----- verify-receipt ----------------------------------------------------

    @Test
    void verifyReceipt_premierAchat_creeActif_etMailBienvenue() throws Exception {
        JWSTransactionDecodedPayload tx = txMock(
                "integral_monthly", "orig_1", "tx_1", Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("jws")).thenReturn(tx);
        when(planManager.findByAppleProductId("integral_monthly")).thenReturn(Optional.of(plan));
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_1")).thenReturn(Optional.empty());

        UserSubscription sub = service.activateFromReceipt(userId, "integral_monthly", "jws");

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getSource()).isEqualTo(SubscriptionSource.APPLE);
        assertThat(sub.getOriginalTransactionId()).isEqualTo("orig_1");
        verify(mailService).sendSubscriptionActivatedEmail(
                org.mockito.ArgumentMatchers.eq("u@sejourfr.fr"),
                org.mockito.ArgumentMatchers.eq("Lea"),
                org.mockito.ArgumentMatchers.eq("Intégral"),
                any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void verifyReceipt_productIdNeCorrespondPas_renvoie400() throws Exception {
        JWSTransactionDecodedPayload tx = txMock(
                "autre_produit", "orig_1", "tx_1", Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("jws")).thenReturn(tx);

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "jws"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
        verify(planManager, never()).findByAppleProductId(any());
    }

    @Test
    void verifyReceipt_planInconnu_renvoie400() throws Exception {
        JWSTransactionDecodedPayload tx = txMock(
                "integral_monthly", "orig_1", "tx_1", Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("jws")).thenReturn(tx);
        when(planManager.findByAppleProductId("integral_monthly")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "jws"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void verifyReceipt_typeNonAutoRenouvelable_renvoie400() throws Exception {
        JWSTransactionDecodedPayload tx = txMock(
                "integral_monthly", "orig_1", "tx_1", Type.NON_CONSUMABLE, 30L);
        when(appleStoreClient.verifyTransaction("jws")).thenReturn(tx);
        when(planManager.findByAppleProductId("integral_monthly")).thenReturn(Optional.of(plan));
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "jws"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void verifyReceipt_recuDUnAutreCompte_renvoie409() throws Exception {
        JWSTransactionDecodedPayload tx = txMock(
                "integral_monthly", "orig_1", "tx_1", Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("jws")).thenReturn(tx);
        when(planManager.findByAppleProductId("integral_monthly")).thenReturn(Optional.of(plan));
        User other = new User();
        other.setId(UUID.randomUUID());
        UserSubscription existing = new UserSubscription();
        existing.setUser(other);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_1")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "jws"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(409);
    }

    @Test
    void verifyReceipt_signatureInvalide_renvoie400() throws Exception {
        when(appleStoreClient.verifyTransaction("jws"))
                .thenThrow(new VerificationException(
                        com.apple.itunes.storekit.verification.VerificationStatus.VERIFICATION_FAILURE));

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "jws"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    // ----- handleNotification ------------------------------------------------

    private ResponseBodyV2DecodedPayload notifMock(
            String uuid, NotificationTypeV2 type, Subtype subtype, Data data) {
        ResponseBodyV2DecodedPayload p = mock(ResponseBodyV2DecodedPayload.class);
        when(p.getNotificationUUID()).thenReturn(uuid);
        when(p.getNotificationType()).thenReturn(type);
        when(p.getSubtype()).thenReturn(subtype);
        when(p.getData()).thenReturn(data);
        return p;
    }

    private Data dataMock(String signedTx) {
        Data data = mock(Data.class);
        when(data.getSignedTransactionInfo()).thenReturn(signedTx);
        when(data.getSignedRenewalInfo()).thenReturn(null);
        return data;
    }

    private UserSubscription localSub(SubscriptionStatus status) {
        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setStatus(status);
        sub.setSource(SubscriptionSource.APPLE);
        sub.setEndsAt(Instant.now().plus(30, ChronoUnit.DAYS));
        return sub;
    }

    @Test
    void notification_dejaTraitee_skip() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-1", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-1")).thenReturn(false);

        service.handleNotification("payload");

        verify(userSubscriptionManager, never()).findBySourceAndOriginalTransactionId(any(), any());
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void notification_sansData_ignoree() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-2", NotificationTypeV2.TEST, null, null);
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-2")).thenReturn(true);

        service.handleNotification("payload");
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void notification_aucuneSubscriptionLocale_ignoree() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-3", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-3")).thenReturn(true);
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_3", "tx_3",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_3")).thenReturn(Optional.empty());

        service.handleNotification("payload");
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void notification_autoRenewDisabled_mappeCanceled_etMail() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-4", NotificationTypeV2.DID_CHANGE_RENEWAL_STATUS,
                        Subtype.AUTO_RENEW_DISABLED, dataMock("stx"));
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-4")).thenReturn(true);
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_4", "tx_4",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        UserSubscription sub = localSub(SubscriptionStatus.ACTIVE);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_4")).thenReturn(Optional.of(sub));

        service.handleNotification("payload");

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(mailService).sendSubscriptionCanceledEmail(
                "u@sejourfr.fr", "Lea", "Intégral", sub.getEndsAt(), "APPLE");
    }

    @Test
    void notification_refund_mappeRefunded() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-5", NotificationTypeV2.REFUND, null, dataMock("stx"));
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-5")).thenReturn(true);
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_5", "tx_5",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        UserSubscription sub = localSub(SubscriptionStatus.ACTIVE);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_5")).thenReturn(Optional.of(sub));

        service.handleNotification("payload");
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
    }

    /**
     * Deux notifications ASSN V2 DISTINCTES (donc non dédupliquées par
     * {@code notificationUUID}) qui décrivent le même état : la seconde n'a
     * rien à écrire. Sans cette garde, {@code updated_at} avancerait sur une
     * ligne inchangée.
     */
    @Test
    void notification_memeEtatRejoue_neSauvegardeQuUneFois() throws Exception {
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_7", "tx_7",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        // Les mocks se construisent AVANT le when(...) : stuber dans l'argument
        // d'un when() lève UnfinishedStubbing (cf. docs/plan-tests-backend.md).
        ResponseBodyV2DecodedPayload premiere =
                notifMock("uuid-7a", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        ResponseBodyV2DecodedPayload seconde =
                notifMock("uuid-7b", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        when(appleStoreClient.verifyNotification("p1")).thenReturn(premiere);
        when(appleStoreClient.verifyNotification("p2")).thenReturn(seconde);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-7a")).thenReturn(true);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-7b")).thenReturn(true);
        UserSubscription sub = localSub(SubscriptionStatus.PENDING);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_7")).thenReturn(Optional.of(sub));

        service.handleNotification("p1");
        service.handleNotification("p2");

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        verify(userSubscriptionManager, times(1)).save(any());
    }

    /** Une notification qui change vraiment l'état est bien écrite, elle. */
    @Test
    void notification_changementReel_sauvegardeANouveau() throws Exception {
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_8", "tx_8",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        ResponseBodyV2DecodedPayload premiere =
                notifMock("uuid-8a", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        ResponseBodyV2DecodedPayload seconde =
                notifMock("uuid-8b", NotificationTypeV2.DID_RENEW, null, dataMock("stx"));
        ResponseBodyV2DecodedPayload resiliation =
                notifMock("uuid-8c", NotificationTypeV2.DID_CHANGE_RENEWAL_STATUS,
                        Subtype.AUTO_RENEW_DISABLED, dataMock("stx"));
        when(appleStoreClient.verifyNotification("p1")).thenReturn(premiere);
        when(appleStoreClient.verifyNotification("p2")).thenReturn(seconde);
        when(appleStoreClient.verifyNotification("p3")).thenReturn(resiliation);
        when(processedEventManager.tryMarkProcessed(
                org.mockito.ArgumentMatchers.eq("apple"), any())).thenReturn(true);
        UserSubscription sub = localSub(SubscriptionStatus.PENDING);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_8")).thenReturn(Optional.of(sub));

        service.handleNotification("p1");   // PENDING → ACTIVE : écrit
        service.handleNotification("p2");   // rien de neuf : pas écrit
        service.handleNotification("p3");   // résiliation : écrit

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(userSubscriptionManager, times(2)).save(any());
    }

    @Test
    void notification_subscribed_mappeActive() throws Exception {
        ResponseBodyV2DecodedPayload notif =
                notifMock("uuid-6", NotificationTypeV2.SUBSCRIBED, null, dataMock("stx"));
        when(appleStoreClient.verifyNotification("payload")).thenReturn(notif);
        when(processedEventManager.tryMarkProcessed("apple", "uuid-6")).thenReturn(true);
        JWSTransactionDecodedPayload tx = txMock("integral_monthly", "orig_6", "tx_6",
                Type.AUTO_RENEWABLE_SUBSCRIPTION, 30L);
        when(appleStoreClient.verifyTransaction("stx")).thenReturn(tx);
        UserSubscription sub = localSub(SubscriptionStatus.PENDING);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "orig_6")).thenReturn(Optional.of(sub));

        service.handleNotification("payload");
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }
}
