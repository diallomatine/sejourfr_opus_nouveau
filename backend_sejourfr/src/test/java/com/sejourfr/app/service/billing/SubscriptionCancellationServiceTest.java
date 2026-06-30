package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.CancelSubscriptionResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import com.sejourfr.app.service.SubscriptionService;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre le routage de la résiliation selon la {@code source} :
 * Stripe → annulation serveur ({@code action=DONE} + mail + statut local
 * CANCELED), Apple/Google → {@code action=REDIRECT} (statut local inchangé,
 * pas d'appel Stripe). Plus les gardes 404 / 409 / 500. Test unitaire pur.
 */
class SubscriptionCancellationServiceTest {

    private SubscriptionService subscriptionService;
    private UserSubscriptionManager userSubscriptionManager;
    private StripeSubscriptionService stripeSubscriptionService;
    private MailService mailService;
    private SubscriptionCancellationService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        subscriptionService = mock(SubscriptionService.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        stripeSubscriptionService = mock(StripeSubscriptionService.class);
        mailService = mock(MailService.class);
        service = new SubscriptionCancellationService(
                subscriptionService, userSubscriptionManager, stripeSubscriptionService, mailService);
    }

    private UserSubscription sub(SubscriptionSource source, SubscriptionStatus status, String origTx) {
        User user = new User();
        user.setId(userId);
        user.setEmail("u@sejourfr.fr");
        user.setFirstName("Lea");
        Plan plan = new Plan();
        plan.setName("Intégral");
        plan.setModuleAccess(ModuleAccess.INTEGRAL);
        UserSubscription s = new UserSubscription();
        s.setUser(user);
        s.setPlan(plan);
        s.setSource(source);
        s.setStatus(status);
        s.setOriginalTransactionId(origTx);
        s.setEndsAt(Instant.now().plus(15, ChronoUnit.DAYS));
        return s;
    }

    @Test
    void cancelForUser_aucunAbo_renvoie404() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.cancelForUser(userId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(404);
    }

    @Test
    void cancelForUser_stripe_annuleServeur_done_etMarqueLocalCanceled() {
        UserSubscription s = sub(SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE, "sub_123");
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(s));
        when(userSubscriptionManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelSubscriptionResponse res = service.cancelForUser(userId);

        assertThat(res.action()).isEqualTo("DONE");
        assertThat(res.redirectUrl()).isNull();
        verify(stripeSubscriptionService).cancelAtPeriodEnd("sub_123");
        // UX immédiate : statut local basculé sans attendre le webhook.
        assertThat(s.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        assertThat(s.isAutoRenew()).isFalse();
        verify(userSubscriptionManager).save(s);
        verify(mailService).sendSubscriptionCanceledEmail(
                "u@sejourfr.fr", "Lea", "Intégral", s.getEndsAt(), "STRIPE");
    }

    @Test
    void cancelForUser_apple_redirect_statutLocalInchange_aucunAppelStripe() {
        UserSubscription s = sub(SubscriptionSource.APPLE, SubscriptionStatus.ACTIVE, "orig_apple");
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(s));

        CancelSubscriptionResponse res = service.cancelForUser(userId);

        assertThat(res.action()).isEqualTo("REDIRECT");
        assertThat(res.redirectUrl()).isEqualTo("https://apps.apple.com/account/subscriptions");
        assertThat(s.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        verify(stripeSubscriptionService, never()).cancelAtPeriodEnd(anyString());
        verify(userSubscriptionManager, never()).save(any());
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }

    @Test
    void cancelForUser_google_redirectVersPlayStore() {
        UserSubscription s = sub(SubscriptionSource.GOOGLE, SubscriptionStatus.ACTIVE, "token_g");
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(s));

        CancelSubscriptionResponse res = service.cancelForUser(userId);

        assertThat(res.action()).isEqualTo("REDIRECT");
        assertThat(res.redirectUrl()).isEqualTo("https://play.google.com/store/account/subscriptions");
    }

    @Test
    void cancelById_introuvable_renvoie404() {
        UUID id = UUID.randomUUID();
        when(userSubscriptionManager.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.cancelSubscriptionById(id))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(404);
    }

    @Test
    void cancelById_statutNonAnnulable_renvoie409() {
        UUID id = UUID.randomUUID();
        UserSubscription s = sub(SubscriptionSource.STRIPE, SubscriptionStatus.CANCELED, "sub_x");
        when(userSubscriptionManager.findById(id)).thenReturn(Optional.of(s));

        assertThatThrownBy(() -> service.cancelSubscriptionById(id))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("pas annulable")
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(409);
        verify(stripeSubscriptionService, never()).cancelAtPeriodEnd(anyString());
    }

    @Test
    void cancelById_stripeActif_done() {
        UUID id = UUID.randomUUID();
        UserSubscription s = sub(SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE, "sub_ok");
        when(userSubscriptionManager.findById(id)).thenReturn(Optional.of(s));
        when(userSubscriptionManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CancelSubscriptionResponse res = service.cancelSubscriptionById(id);

        assertThat(res.action()).isEqualTo("DONE");
        verify(stripeSubscriptionService).cancelAtPeriodEnd("sub_ok");
    }

    @Test
    void cancelStripe_sansOriginalTransactionId_renvoie500() {
        UserSubscription s = sub(SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE, null);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(s));

        assertThatThrownBy(() -> service.cancelForUser(userId))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(500);
        verify(stripeSubscriptionService, never()).cancelAtPeriodEnd(anyString());
    }
}
