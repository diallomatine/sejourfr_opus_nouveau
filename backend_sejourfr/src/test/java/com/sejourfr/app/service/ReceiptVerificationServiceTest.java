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
    private ReceiptVerificationService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        appleSubscriptionService = mock(AppleSubscriptionService.class);
        googleSubscriptionService = mock(GoogleSubscriptionService.class);
        subscriptionService = mock(SubscriptionService.class);
        service = new ReceiptVerificationService(
                appleSubscriptionService, googleSubscriptionService, subscriptionService);
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
                SubscriptionSource.APPLE, "jws-receipt", "integral_monthly");

        SubscriptionStatusResponse res = service.verify(userId, req);

        verify(appleSubscriptionService).activateFromReceipt(userId, "integral_monthly", "jws-receipt");
        verifyNoInteractions(googleSubscriptionService);
        assertThat(res.isPremium()).isTrue();
        assertThat(res.source()).isEqualTo(SubscriptionSource.APPLE);
    }

    @Test
    void google_delegue_etRenvoieNotPremiumSiAucunAbo() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.empty());
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.GOOGLE, "purchase-token", "civique_monthly");

        SubscriptionStatusResponse res = service.verify(userId, req);

        verify(googleSubscriptionService).activateFromReceipt(userId, "civique_monthly", "purchase-token");
        verifyNoInteractions(appleSubscriptionService);
        assertThat(res.isPremium()).isFalse();
        assertThat(res.moduleAccess()).isEqualTo(ModuleAccess.NONE);
    }

    @Test
    void stripe_rejete400_sansToucherLesServicesStore() {
        VerifyReceiptRequest req = new VerifyReceiptRequest(
                SubscriptionSource.STRIPE, "x", "y");

        assertThatThrownBy(() -> service.verify(userId, req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);

        verifyNoInteractions(appleSubscriptionService, googleSubscriptionService);
        verify(subscriptionService, never()).currentSubscription(userId);
    }
}
