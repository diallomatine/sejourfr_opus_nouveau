package com.sejourfr.app.service.billing;

import com.google.api.client.googleapis.json.GoogleJsonError;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.http.HttpHeaders;
import com.google.api.client.http.HttpResponseException;
import com.google.api.services.androidpublisher.model.AutoRenewingPlan;
import com.google.api.services.androidpublisher.model.ProductPurchase;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseLineItem;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseV2;
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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre Google Play Billing en mode abonnement : verify-receipt (création +
 * 400 productId/plan/IO, 409 anti-account-stealing) et les RTDN (messageId
 * manquant, idempotence, SUBSCRIPTION_REVOKED→REFUNDED immédiat sans refetch,
 * mapping subscriptionState→SubscriptionStatus). Le client Google et l'auth
 * Pub/Sub sont mockés.
 */
class GoogleSubscriptionServiceTest {

    private GoogleStoreClient googleStoreClient;
    private PlanManager planManager;
    private UserManager userManager;
    private UserSubscriptionManager userSubscriptionManager;
    private ProcessedExternalEventManager processedEventManager;
    private MailService mailService;
    private BillingProperties billingProperties;
    private OneTimeAccessService oneTimeAccessService;
    private GoogleSubscriptionService service;

    private final UUID userId = UUID.randomUUID();
    private User user;
    private Plan plan;

    @BeforeEach
    void setUp() {
        googleStoreClient = mock(GoogleStoreClient.class);
        planManager = mock(PlanManager.class);
        userManager = mock(UserManager.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        processedEventManager = mock(ProcessedExternalEventManager.class);
        mailService = mock(MailService.class);
        oneTimeAccessService = mock(OneTimeAccessService.class);
        billingProperties = mock(BillingProperties.class); // isOneTime() = false par défaut
        service = new GoogleSubscriptionService(
                googleStoreClient, planManager, userManager, userSubscriptionManager,
                processedEventManager, new SubscriptionNotificationService(mailService),
                oneTimeAccessService, billingProperties);

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

    private SubscriptionPurchaseV2 stateMock(String productId, String subState) {
        AutoRenewingPlan arp = new AutoRenewingPlan().setAutoRenewEnabled(true);
        SubscriptionPurchaseLineItem item = new SubscriptionPurchaseLineItem()
                .setProductId(productId)
                .setExpiryTime(Instant.now().plus(30, ChronoUnit.DAYS).toString())
                .setAutoRenewingPlan(arp);
        SubscriptionPurchaseV2 state = mock(SubscriptionPurchaseV2.class);
        when(state.getLineItems()).thenReturn(List.of(item));
        when(state.getSubscriptionState()).thenReturn(subState);
        when(state.getLatestOrderId()).thenReturn("order_1");
        return state;
    }

    // ----- verify-receipt ----------------------------------------------------

    @Test
    void verifyReceipt_premierAchat_creeActif_etMail() throws Exception {
        SubscriptionPurchaseV2 state = stateMock("integral_monthly", "SUBSCRIPTION_STATE_ACTIVE");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);
        when(planManager.findByGoogleProductId("integral_monthly")).thenReturn(Optional.of(plan));
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.empty());

        UserSubscription sub = service.activateFromReceipt(userId, "integral_monthly", "tok");

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getSource()).isEqualTo(SubscriptionSource.GOOGLE);
        assertThat(sub.getOriginalTransactionId()).isEqualTo("tok");
        verify(mailService).sendSubscriptionActivatedEmail(
                org.mockito.ArgumentMatchers.eq("u@sejourfr.fr"),
                org.mockito.ArgumentMatchers.eq("Lea"),
                org.mockito.ArgumentMatchers.eq("Intégral"),
                any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void verifyReceipt_productIdNeCorrespondPas_renvoie400() throws Exception {
        SubscriptionPurchaseV2 state = stateMock("autre_produit", "SUBSCRIPTION_STATE_ACTIVE");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "tok"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void verifyReceipt_planInconnu_renvoie400() throws Exception {
        SubscriptionPurchaseV2 state = stateMock("integral_monthly", "SUBSCRIPTION_STATE_ACTIVE");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);
        when(planManager.findByGoogleProductId("integral_monthly")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "tok"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void verifyReceipt_apiPlayEchoue_renvoie400() throws Exception {
        when(googleStoreClient.getSubscriptionV2("tok")).thenThrow(new IOException("403 perms"));

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "tok"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void verifyReceipt_tokenDUnAutreCompte_renvoie409() throws Exception {
        SubscriptionPurchaseV2 state = stateMock("integral_monthly", "SUBSCRIPTION_STATE_ACTIVE");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);
        when(planManager.findByGoogleProductId("integral_monthly")).thenReturn(Optional.of(plan));
        User other = new User();
        other.setId(UUID.randomUUID());
        UserSubscription existing = new UserSubscription();
        existing.setUser(other);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> service.activateFromReceipt(userId, "integral_monthly", "tok"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(409);
    }

    // ----- handleNotification (RTDN) -----------------------------------------

    private static String pubSubPayload(String messageId, int notificationType, String purchaseToken) {
        String inner = "{\"subscriptionNotification\":{\"notificationType\":" + notificationType
                + ",\"purchaseToken\":\"" + purchaseToken + "\"}}";
        String dataB64 = Base64.getEncoder()
                .encodeToString(inner.getBytes(StandardCharsets.UTF_8));
        return "{\"message\":{\"messageId\":\"" + messageId + "\",\"data\":\"" + dataB64 + "\"}}";
    }

    private UserSubscription localSub(SubscriptionStatus status) {
        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setStatus(status);
        sub.setSource(SubscriptionSource.GOOGLE);
        sub.setEndsAt(Instant.now().plus(30, ChronoUnit.DAYS));
        return sub;
    }

    @Test
    void rtdn_messageIdManquant_renvoie400() {
        String payload = "{\"message\":{\"data\":\"e30=\"}}"; // pas de messageId
        assertThatThrownBy(() -> service.handleNotification("Bearer x", payload))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
    }

    @Test
    void rtdn_dejaTraite_skip() {
        when(processedEventManager.tryMarkProcessed("google", "m1")).thenReturn(false);
        service.handleNotification("Bearer x", pubSubPayload("m1", 4, "tok"));
        verify(userSubscriptionManager, never()).findBySourceAndOriginalTransactionId(any(), any());
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void rtdn_revoked_mappeRefunded_sansRefetch() throws Exception {
        when(processedEventManager.tryMarkProcessed("google", "m2")).thenReturn(true);
        UserSubscription sub = localSub(SubscriptionStatus.ACTIVE);
        sub.setAutoRenew(true);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.of(sub));

        // notificationType 12 = SUBSCRIPTION_REVOKED
        service.handleNotification("Bearer x", pubSubPayload("m2", 12, "tok"));

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(sub.isAutoRenew()).isFalse();
        // Pas d'appel à l'API Play : REVOKED est appliqué immédiatement.
        verify(googleStoreClient, never()).getSubscriptionV2(anyString());
    }

    @Test
    void rtdn_aucuneSubscriptionLocale_ignoree() throws Exception {
        when(processedEventManager.tryMarkProcessed("google", "m3")).thenReturn(true);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.empty());

        service.handleNotification("Bearer x", pubSubPayload("m3", 4, "tok"));

        verify(googleStoreClient, never()).getSubscriptionV2(anyString());
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void rtdn_etatCanceled_mappeCanceled_etMail() throws Exception {
        when(processedEventManager.tryMarkProcessed("google", "m4")).thenReturn(true);
        UserSubscription sub = localSub(SubscriptionStatus.ACTIVE);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.of(sub));
        SubscriptionPurchaseV2 state = stateMock("integral_monthly", "SUBSCRIPTION_STATE_CANCELED");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);

        // notificationType 3 = SUBSCRIPTION_CANCELED (refetch quand même)
        service.handleNotification("Bearer x", pubSubPayload("m4", 3, "tok"));

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(mailService).sendSubscriptionCanceledEmail(
                "u@sejourfr.fr", "Lea", "Intégral", sub.getEndsAt(), "GOOGLE");
    }

    @Test
    void rtdn_etatActive_mappeActive_pasDeMailResiliation() throws Exception {
        when(processedEventManager.tryMarkProcessed("google", "m5")).thenReturn(true);
        UserSubscription sub = localSub(SubscriptionStatus.PENDING);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.GOOGLE, "tok")).thenReturn(Optional.of(sub));
        SubscriptionPurchaseV2 state = stateMock("integral_monthly", "SUBSCRIPTION_STATE_ACTIVE");
        when(googleStoreClient.getSubscriptionV2("tok")).thenReturn(state);

        service.handleNotification("Bearer x", pubSubPayload("m5", 4, "tok"));

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }

    // ----- verify-receipt, pass one-time (lot 5) ------------------------------

    private ProductPurchase produitAchete() {
        return new ProductPurchase().setPurchaseState(0).setOrderId("order_1");
    }

    private void modeOneTime(ProductPurchase pp) throws Exception {
        when(billingProperties.isOneTime()).thenReturn(true);
        when(googleStoreClient.getProduct("integral_pass_2m", "tok")).thenReturn(pp);
        when(planManager.findByGoogleProductId("integral_pass_2m")).thenReturn(Optional.of(plan));
        when(oneTimeAccessService.grantOneTimeAccess(
                any(), any(), any(), anyString(), any()))
                .thenReturn(localSub(SubscriptionStatus.ACTIVE));
    }

    /**
     * Le client consomme le pass lui-même ({@code autoConsume}) et une
     * consommation acquitte implicitement : réacquitter ne ferait que provoquer
     * un 400 inutile.
     */
    @Test
    void passOneTimeDejaConsommeCoteClient_nEstPasReacquitte() throws Exception {
        modeOneTime(produitAchete().setConsumptionState(1));

        service.activateFromReceipt(userId, "integral_pass_2m", "tok");

        verify(googleStoreClient, never()).acknowledgeProduct(anyString(), anyString());
        verify(oneTimeAccessService).grantOneTimeAccess(
                any(), any(), org.mockito.ArgumentMatchers.eq(SubscriptionSource.GOOGLE),
                org.mockito.ArgumentMatchers.eq("tok"), any());
    }

    @Test
    void passOneTimePasEncoreAcquitte_estAcquitte() throws Exception {
        modeOneTime(produitAchete().setAcknowledgementState(0));

        service.activateFromReceipt(userId, "integral_pass_2m", "tok");

        verify(googleStoreClient).acknowledgeProduct("integral_pass_2m", "tok");
    }

    /**
     * Course perdue contre la consommation client : Play refuse l'acquittement en
     * 400 {@code invalidPurchaseState}. L'accès est payé, il doit être accordé.
     */
    @Test
    void acquittementRefuseEnInvalidPurchaseState_nEmpechePasLAcces() throws Exception {
        modeOneTime(produitAchete());
        GoogleJsonError.ErrorInfo info = new GoogleJsonError.ErrorInfo();
        info.setReason("invalidPurchaseState");
        GoogleJsonError details = new GoogleJsonError();
        details.setCode(400);
        details.setErrors(List.of(info));
        org.mockito.Mockito.doThrow(new GoogleJsonResponseException(
                        new HttpResponseException.Builder(400, "Bad Request", new HttpHeaders()), details))
                .when(googleStoreClient).acknowledgeProduct(anyString(), anyString());

        service.activateFromReceipt(userId, "integral_pass_2m", "tok");

        verify(oneTimeAccessService).grantOneTimeAccess(
                any(), any(), org.mockito.ArgumentMatchers.eq(SubscriptionSource.GOOGLE),
                org.mockito.ArgumentMatchers.eq("tok"), any());
    }

    /** Un échec d'acquittement quelconque reste best-effort : l'accès payé passe. */
    @Test
    void acquittementEnEchecReseau_nEmpechePasLAcces() throws Exception {
        modeOneTime(produitAchete());
        org.mockito.Mockito.doThrow(new IOException("timeout"))
                .when(googleStoreClient).acknowledgeProduct(anyString(), anyString());

        service.activateFromReceipt(userId, "integral_pass_2m", "tok");

        verify(oneTimeAccessService).grantOneTimeAccess(
                any(), any(), org.mockito.ArgumentMatchers.eq(SubscriptionSource.GOOGLE),
                org.mockito.ArgumentMatchers.eq("tok"), any());
    }
}
