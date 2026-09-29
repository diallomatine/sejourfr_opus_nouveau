package com.sejourfr.app.service;

import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.dto.VerifyReceiptRequest;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.billing.AppleSubscriptionService;
import com.sejourfr.app.service.billing.GoogleSubscriptionService;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Couvre le dispatch verify-receipt : APPLE/GOOGLE délèguent au bon service
 * spécialisé puis renvoient le statut agrégé ; STRIPE est rejeté en 400
 * (Stripe passe par le webhook, pas par cet endpoint). Test unitaire pur.
 */
class ReceiptVerificationServiceTest {

    private AppleSubscriptionService appleSubscriptionService;
    private GoogleSubscriptionService googleSubscriptionService;
    private SubscriptionService subscriptionService;
    private RealtimeQuotaService realtimeQuotaService;
    private ReceiptVerificationService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        appleSubscriptionService = mock(AppleSubscriptionService.class);
        googleSubscriptionService = mock(GoogleSubscriptionService.class);
        subscriptionService = mock(SubscriptionService.class);
        realtimeQuotaService = mock(RealtimeQuotaService.class);
        when(realtimeQuotaService.evaluate(userId))
                .thenReturn(new RealtimeQuotaService.Quota(null, 10, 4));
        service = new ReceiptVerificationService(
                appleSubscriptionService, googleSubscriptionService, subscriptionService,
                realtimeQuotaService,
                new com.sejourfr.app.service.billing.MontantEncaisseResolver(
                        new com.sejourfr.app.config.AnalyticsProperties()));
    }

    private UserSubscription premiumSub() {
        Plan plan = new Plan();
        plan.setModuleAccess(ModuleAccess.INTEGRAL);
        UserSubscription s = new UserSubscription();
        s.setPlan(plan);
        s.setSource(SubscriptionSource.APPLE);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setProductId("integral_monthly");
        return s;
    }

    @Test
    void apple_delegue_puisRenvoieStatutPremium() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(premiumSub()));
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.APPLE, "jws-receipt", "integral_monthly", null, null);

        SubscriptionStatusResponse res = service.verify(userId, req);

        verify(appleSubscriptionService).activateFromReceipt(
                org.mockito.ArgumentMatchers.eq(userId),
                org.mockito.ArgumentMatchers.eq("integral_monthly"),
                org.mockito.ArgumentMatchers.eq("jws-receipt"),
                org.mockito.ArgumentMatchers.any());
        verifyNoInteractions(googleSubscriptionService);
        assertThat(res.isPremium()).isTrue();
        assertThat(res.source()).isEqualTo(SubscriptionSource.APPLE);
        // Pass à quota (cap 10 > 0) → solde temps réel exposé.
        assertThat(res.realtimeSessionsRemaining()).isEqualTo(4);
    }

    @Test
    void google_delegue_etRenvoieNotPremiumSiAucunAbo() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.empty());
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "purchase-token", "civique_monthly", null, null);

        SubscriptionStatusResponse res = service.verify(userId, req);

        verify(googleSubscriptionService).activateFromReceipt(
                org.mockito.ArgumentMatchers.eq(userId),
                org.mockito.ArgumentMatchers.eq("civique_monthly"),
                org.mockito.ArgumentMatchers.eq("purchase-token"),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.isNull());
        verifyNoInteractions(appleSubscriptionService);
        assertThat(res.isPremium()).isFalse();
        assertThat(res.moduleAccess()).isEqualTo(ModuleAccess.NONE);
    }

    /**
     * Bug Q11 : le mobile envoie {@code amountCents} + {@code currency}
     * ({@code billing_models.dart}) ; le backend n'attendait que
     * {@code rawPrice}, et Jackson ignorait le champ en silence.
     */
    @Test
    void montantDeclare_amountCentsDuMobile_estLu() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "tok", "p", null, null, 999L, "eur", null);

        com.sejourfr.app.service.billing.MontantEncaisse m = service.montantDeclare(req);

        assertThat(m.amountCents()).isEqualTo(999);
        assertThat(m.currency()).isEqualTo("EUR");
        assertThat(m.amountEurCents()).isEqualTo(999);
    }

    /** L'ancienne forme reste acceptée : un client antérieur ne casse pas. */
    @Test
    void montantDeclare_rawPriceHistorique_resteAccepte() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "tok", "p", 9.99, "EUR");

        assertThat(service.montantDeclare(req).amountCents()).isEqualTo(999);
    }

    /** Les deux formes présentes : {@code amountCents}, la forme actuelle, gagne. */
    @Test
    void montantDeclare_lesDeux_amountCentsGagne() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "tok", "p", 1.00, "EUR", 1999L, "EUR", null);

        assertThat(service.montantDeclare(req).amountCents()).isEqualTo(1999);
    }

    /** Aucun montant : inconnu, jamais zéro. */
    @Test
    void montantDeclare_absent_inconnu() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "tok", "p", null, null);

        assertThat(service.montantDeclare(req).estConnu()).isFalse();
    }

    /** L'intention voyage jusqu'au service store, telle que reçue (validée à l'octroi). */
    @Test
    void intentionTransmiseAuxServicesStore() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.empty());
        String intent = UUID.randomUUID().toString();

        service.verify(userId, new VerifyReceiptRequest(
                SubscriptionSource.APPLE, "jws", "sku", null, null, null, null, intent));
        service.verify(userId, new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "tok", "sku", null, null, null, null, intent));

        verify(appleSubscriptionService).activateFromReceipt(userId, "sku", "jws", intent);
        verify(googleSubscriptionService).activateFromReceipt(
                org.mockito.ArgumentMatchers.eq(userId), org.mockito.ArgumentMatchers.eq("sku"),
                org.mockito.ArgumentMatchers.eq("tok"), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.eq(intent));
    }

    @Test
    void stripe_rejete400_sansToucherLesServicesStore() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.STRIPE, "x", "y", null, null);

        assertThatThrownBy(() -> service.verify(userId, req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);

        verifyNoInteractions(appleSubscriptionService, googleSubscriptionService);
        verify(subscriptionService, never()).currentSubscription(userId);
    }
}
