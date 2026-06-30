package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import com.stripe.exception.StripeException;
import com.stripe.model.Charge;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import com.stripe.model.Subscription;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre l'application des events Stripe sur {@code user_subscriptions} : le
 * mapping {@code status Stripe → SubscriptionStatus}, le no-op sur subscription
 * inconnue, l'expiration immédiate (deleted), le refund one-time, le crédit du
 * pass one-time (checkout PAYMENT), et le 502 sur cancelAtPeriodEnd. On
 * mocke le {@link Event} et sa désérialisation pour injecter des objets Stripe
 * de test sans réseau.
 */
class StripeSubscriptionServiceTest {

    private UserManager userManager;
    private PlanManager planManager;
    private UserSubscriptionManager userSubscriptionManager;
    private MailService mailService;
    private OneTimeAccessService oneTimeAccessService;
    private BillingProperties billingProperties;
    private StripeSubscriptionService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        planManager = mock(PlanManager.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        mailService = mock(MailService.class);
        oneTimeAccessService = mock(OneTimeAccessService.class);
        billingProperties = mock(BillingProperties.class);
        service = new StripeSubscriptionService(
                userManager, planManager, userSubscriptionManager,
                mailService, oneTimeAccessService, billingProperties);
        when(userSubscriptionManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    /** Event mocké renvoyant {@code obj} via sa chaîne de désérialisation. */
    private Event eventOf(String type, StripeObject obj) {
        Event event = mock(Event.class);
        when(event.getType()).thenReturn(type);
        EventDataObjectDeserializer deserializer = mock(EventDataObjectDeserializer.class);
        when(deserializer.getObject()).thenReturn(Optional.of(obj));
        when(event.getDataObjectDeserializer()).thenReturn(deserializer);
        return event;
    }

    private UserSubscription existingSub(SubscriptionStatus status) {
        User user = new User();
        user.setId(userId);
        user.setEmail("u@sejourfr.fr");
        user.setFirstName("Lea");
        Plan plan = new Plan();
        plan.setName("Civique");
        plan.setModuleAccess(ModuleAccess.CIVIQUE);
        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setStatus(status);
        sub.setSource(SubscriptionSource.STRIPE);
        sub.setOriginalTransactionId("sub_1");
        return sub;
    }

    private Subscription subscriptionMock(String status, boolean cancelAtPeriodEnd) {
        Subscription s = mock(Subscription.class);
        when(s.getId()).thenReturn("sub_1");
        when(s.getStatus()).thenReturn(status);
        when(s.getCancelAtPeriodEnd()).thenReturn(cancelAtPeriodEnd);
        when(s.getItems()).thenReturn(null); // pas de lookup plan : on garde le plan existant
        when(s.getCurrentPeriodEnd()).thenReturn(null);
        when(s.getLatestInvoice()).thenReturn("in_1");
        return s;
    }

    private void dispatchUpdate(String stripeStatus, boolean cancel, UserSubscription existing) {
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "sub_1")).thenReturn(Optional.of(existing));
        service.dispatch(eventOf("customer.subscription.updated",
                subscriptionMock(stripeStatus, cancel)));
    }

    @Test
    void update_active_sansCancel_mappeActive() {
        UserSubscription existing = existingSub(SubscriptionStatus.PENDING);
        dispatchUpdate("active", false, existing);
        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(existing.isAutoRenew()).isTrue();
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }

    @Test
    void update_active_avecCancelAtPeriodEnd_mappeCanceled_etMail() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        dispatchUpdate("active", true, existing);
        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        assertThat(existing.isAutoRenew()).isFalse();
        // Transition ACTIVE → CANCELED → mail de résiliation.
        verify(mailService).sendSubscriptionCanceledEmail(
                "u@sejourfr.fr", "Lea", "Civique", null, "STRIPE");
    }

    @Test
    void update_canceledVersCanceled_pasDeMail() {
        UserSubscription existing = existingSub(SubscriptionStatus.CANCELED);
        dispatchUpdate("active", true, existing);
        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }

    @Test
    void update_mapStatutsDivers() {
        UserSubscription t = existingSub(SubscriptionStatus.PENDING);
        dispatchUpdate("trialing", false, t);
        assertThat(t.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);

        UserSubscription g = existingSub(SubscriptionStatus.ACTIVE);
        dispatchUpdate("past_due", false, g);
        assertThat(g.getStatus()).isEqualTo(SubscriptionStatus.IN_GRACE);

        UserSubscription p = existingSub(SubscriptionStatus.ACTIVE);
        dispatchUpdate("paused", false, p);
        assertThat(p.getStatus()).isEqualTo(SubscriptionStatus.EXPIRED);

        UserSubscription i = existingSub(SubscriptionStatus.ACTIVE);
        dispatchUpdate("incomplete", false, i);
        assertThat(i.getStatus()).isEqualTo(SubscriptionStatus.PENDING);
    }

    @Test
    void update_subscriptionInconnue_noop() {
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "sub_1")).thenReturn(Optional.empty());
        service.dispatch(eventOf("customer.subscription.updated",
                subscriptionMock("active", false)));
        verify(userSubscriptionManager, never()).save(any());
        verify(mailService, never()).sendSubscriptionCanceledEmail(any(), any(), any(), any(), any());
    }

    @Test
    void deleted_mappeExpired_etCoupeAutoRenew() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        existing.setAutoRenew(true);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "sub_1")).thenReturn(Optional.of(existing));
        Subscription s = mock(Subscription.class);
        when(s.getId()).thenReturn("sub_1");
        when(s.getCanceledAt()).thenReturn(null);

        service.dispatch(eventOf("customer.subscription.deleted", s));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.EXPIRED);
        assertThat(existing.isAutoRenew()).isFalse();
    }

    @Test
    void chargeRefunded_oneTime_parPaymentIntent_mappeRefunded() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        Charge charge = mock(Charge.class);
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn("pi_99");
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_99")).thenReturn(Optional.of(existing));

        service.dispatch(eventOf("charge.refunded", charge));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(existing.isAutoRenew()).isFalse();
    }

    @Test
    void checkoutCompleted_oneTime_crediteLePass() {
        when(billingProperties.isOneTime()).thenReturn(true);
        com.stripe.model.checkout.Session session = mock(com.stripe.model.checkout.Session.class);
        when(session.getSubscription()).thenReturn(null);
        when(session.getClientReferenceId()).thenReturn(userId.toString());
        when(session.getMetadata()).thenReturn(Map.of("planCode", "CIVIQUE_3MOIS"));
        when(session.getPaymentIntent()).thenReturn("pi_1");
        when(session.getId()).thenReturn("cs_1");
        Plan plan = new Plan();
        plan.setCode("CIVIQUE_3MOIS");
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(plan));

        service.dispatch(eventOf("checkout.session.completed", session));

        verify(oneTimeAccessService).grantOneTimeAccess(
                eq(userId), eq(plan), eq(SubscriptionSource.STRIPE), eq("pi_1"), eq("cs_1"));
    }

    @Test
    void checkoutCompleted_oneTime_sansPlanCode_noGrant() {
        when(billingProperties.isOneTime()).thenReturn(true);
        com.stripe.model.checkout.Session session = mock(com.stripe.model.checkout.Session.class);
        when(session.getSubscription()).thenReturn(null);
        when(session.getClientReferenceId()).thenReturn(userId.toString());
        when(session.getMetadata()).thenReturn(Map.of());
        when(session.getId()).thenReturn("cs_2");

        service.dispatch(eventOf("checkout.session.completed", session));

        verify(oneTimeAccessService, never()).grantOneTimeAccess(any(), any(), any(), any(), any());
    }

    @Test
    void cancelAtPeriodEnd_stripeException_renvoie502() {
        try (MockedStatic<Subscription> mocked = mockStatic(Subscription.class)) {
            mocked.when(() -> Subscription.retrieve("sub_err"))
                    .thenThrow(mock(StripeException.class));

            assertThatThrownBy(() -> service.cancelAtPeriodEnd("sub_err"))
                    .isInstanceOf(ResponseStatusException.class)
                    .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                    .isEqualTo(502);
        }
    }

    @Test
    void dispatch_typeInconnu_noop() {
        service.dispatch(eventOf("invoice.paid", mock(Subscription.class)));
        verify(userSubscriptionManager, never()).save(any());
        verify(oneTimeAccessService, never()).grantOneTimeAccess(any(), any(), any(), any(), any());
    }
}
