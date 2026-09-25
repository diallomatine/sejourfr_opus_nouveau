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
import org.springframework.context.ApplicationEventPublisher;
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
import static org.mockito.Mockito.times;
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
    private ApplicationEventPublisher mailService;
    private OneTimeAccessService oneTimeAccessService;
    private BillingProperties billingProperties;
    private StripeFeeClient stripeFeeClient;
    private PaymentRefundService paymentRefundService;
    private StripeSubscriptionService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        planManager = mock(PlanManager.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        mailService = mock(ApplicationEventPublisher.class);
        oneTimeAccessService = mock(OneTimeAccessService.class);
        billingProperties = mock(BillingProperties.class);
        stripeFeeClient = mock(StripeFeeClient.class);
        paymentRefundService = mock(PaymentRefundService.class);
        service = new StripeSubscriptionService(
                userManager, planManager, userSubscriptionManager,
                new SubscriptionNotificationService(mailService), oneTimeAccessService, billingProperties,
                new MontantEncaisseResolver(new com.sejourfr.app.config.AnalyticsProperties()),
                stripeFeeClient, paymentRefundService);
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
        verify(mailService, never()).publishEvent(org.mockito.ArgumentMatchers.<Object>argThat(e -> e instanceof com.sejourfr.app.service.email.event.PremiumSubscriptionCanceledEvent));
    }

    @Test
    void update_active_avecCancelAtPeriodEnd_mappeCanceled_etMail() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        dispatchUpdate("active", true, existing);
        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        assertThat(existing.isAutoRenew()).isFalse();
        // Transition ACTIVE → CANCELED → mail de résiliation.
        verify(mailService).publishEvent(org.mockito.ArgumentMatchers.<Object>argThat(e -> e instanceof com.sejourfr.app.service.email.event.PremiumSubscriptionCanceledEvent));
    }

    @Test
    void update_canceledVersCanceled_pasDeMail() {
        UserSubscription existing = existingSub(SubscriptionStatus.CANCELED);
        dispatchUpdate("active", true, existing);
        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(mailService, never()).publishEvent(org.mockito.ArgumentMatchers.<Object>argThat(e -> e instanceof com.sejourfr.app.service.email.event.PremiumSubscriptionCanceledEvent));
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
        verify(mailService, never()).publishEvent(org.mockito.ArgumentMatchers.<Object>argThat(e -> e instanceof com.sejourfr.app.service.email.event.PremiumSubscriptionCanceledEvent));
    }

    /**
     * Stripe émet une rafale d'events pour un même cycle métier (28
     * {@code event_id} distincts en quelques dizaines de secondes, constaté en
     * base). La dédup par {@code event_id} ne les couvre pas : ce sont des
     * events différents. Seul le premier a quelque chose à écrire — les
     * suivants ne doivent PAS resauvegarder, sinon {@code updated_at} avance
     * sans aucun changement métier.
     */
    @Test
    void update_memeEtatRejoue_neSauvegardeQuUneFois() {
        UserSubscription existing = existingSub(SubscriptionStatus.PENDING);
        dispatchUpdate("active", false, existing);
        dispatchUpdate("active", false, existing);
        dispatchUpdate("active", false, existing);

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        verify(userSubscriptionManager, times(1)).save(any());
    }

    /** Un event qui change vraiment l'état est bien écrit, lui. */
    @Test
    void update_changementReel_sauvegardeANouveau() {
        UserSubscription existing = existingSub(SubscriptionStatus.PENDING);
        dispatchUpdate("active", false, existing);   // PENDING → ACTIVE : écrit
        dispatchUpdate("active", false, existing);   // rien de neuf : pas écrit
        dispatchUpdate("active", true, existing);    // résiliation : écrit

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.CANCELED);
        verify(userSubscriptionManager, times(2)).save(any());
    }

    /**
     * 🛑 {@code null} = inconnu. Stripe émet des {@code subscription.updated}
     * dont le {@code latest_invoice} est encore {@code null} : ça ne veut pas
     * dire « plus de facture ». Écraser l'id connu perdrait la traçabilité et
     * ferait avancer {@code updated_at} sur un aller-retour null ⇄ in_1.
     */
    @Test
    void update_sansLatestInvoice_gardeLaFactureDejaConnue() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        existing.setAutoRenew(true);
        existing.setExternalTransactionId("in_1");

        Subscription sansFacture = subscriptionMock("active", false);
        when(sansFacture.getLatestInvoice()).thenReturn(null);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "sub_1")).thenReturn(Optional.of(existing));
        service.dispatch(eventOf("customer.subscription.updated", sansFacture));

        assertThat(existing.getExternalTransactionId()).isEqualTo("in_1");
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void deleted_rejoue_neSauvegardeQuUneFois() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        existing.setAutoRenew(true);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "sub_1")).thenReturn(Optional.of(existing));
        Subscription s = mock(Subscription.class);
        when(s.getId()).thenReturn("sub_1");
        when(s.getCanceledAt()).thenReturn(null);

        service.dispatch(eventOf("customer.subscription.deleted", s));
        service.dispatch(eventOf("customer.subscription.deleted", s));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.EXPIRED);
        verify(userSubscriptionManager, times(1)).save(any());
    }

    @Test
    void chargeRefunded_rejoue_neSauvegardeQuUneFois() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        Charge charge = mock(Charge.class);
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn("pi_99");
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_99")).thenReturn(Optional.of(existing));

        service.dispatch(eventOf("charge.refunded", charge));
        service.dispatch(eventOf("charge.refunded", charge));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        verify(userSubscriptionManager, times(1)).save(any());
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
        when(session.getPaymentStatus()).thenReturn("paid");
        when(session.getId()).thenReturn("cs_1");
        Plan plan = new Plan();
        plan.setCode("CIVIQUE_3MOIS");
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(plan));

        service.dispatch(eventOf("checkout.session.completed", session));

        // Le montant vient de Stripe lui-même (`amount_total` + `currency`) :
        // c'est le seul chiffre qui soit un fait, remises et proration comprises.
        verify(oneTimeAccessService).grantOneTimeAccess(
                eq(userId), eq(plan), eq(SubscriptionSource.STRIPE), eq("pi_1"), eq("cs_1"), any(), any());
    }

    private com.stripe.model.checkout.Session sessionPayee(String paymentStatus, Map<String, String> metadata) {
        com.stripe.model.checkout.Session session = mock(com.stripe.model.checkout.Session.class);
        when(session.getSubscription()).thenReturn(null);
        when(session.getClientReferenceId()).thenReturn(userId.toString());
        when(session.getMetadata()).thenReturn(metadata);
        when(session.getPaymentIntent()).thenReturn("pi_1");
        when(session.getPaymentStatus()).thenReturn(paymentStatus);
        when(session.getAmountTotal()).thenReturn(999L);
        when(session.getCurrency()).thenReturn("eur");
        when(session.getId()).thenReturn("cs_1");
        Plan plan = new Plan();
        plan.setCode("CIVIQUE_3MOIS");
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(plan));
        return session;
    }

    /**
     * Bug Q11 : un moyen de paiement différé termine la session en
     * {@code unpaid}. Rien n'est encaissé : rien n'est accordé.
     */
    @Test
    void checkoutCompleted_paiementDiffereNonEncaisse_aucunAcces() {
        when(billingProperties.isOneTime()).thenReturn(true);

        service.dispatch(eventOf("checkout.session.completed",
                sessionPayee("unpaid", Map.of("planCode", "CIVIQUE_3MOIS"))));

        verify(oneTimeAccessService, never())
                .grantOneTimeAccess(any(), any(), any(), any(), any(), any(), any());
    }

    /** L'encaissement différé arrive : l'accès s'ouvre à ce moment-là. */
    @Test
    void asyncPaymentSucceeded_accordeLeAcces() {
        when(billingProperties.isOneTime()).thenReturn(true);

        service.dispatch(eventOf("checkout.session.async_payment_succeeded",
                sessionPayee("paid", Map.of("planCode", "CIVIQUE_3MOIS"))));

        verify(oneTimeAccessService).grantOneTimeAccess(
                eq(userId), any(), eq(SubscriptionSource.STRIPE), eq("pi_1"), eq("cs_1"), any(), any());
    }

    /**
     * Q12 + §6 : l'intention voyage par {@code metadata.intentId}, le frais réel
     * par la balance_transaction, la date par l'évènement signé.
     */
    @Test
    void checkoutCompleted_transmetIntentionFraisReelEtDate() {
        when(billingProperties.isOneTime()).thenReturn(true);
        when(stripeFeeClient.fraisReelEurCents("pi_1")).thenReturn(Optional.of(39));
        String intent = UUID.randomUUID().toString();
        Event event = eventOf("checkout.session.completed",
                sessionPayee("paid", Map.of("planCode", "CIVIQUE_3MOIS", "intentId", intent)));
        when(event.getCreated()).thenReturn(1_790_000_000L);

        service.dispatch(event);

        org.mockito.ArgumentCaptor<ContexteAchat> contexte =
                org.mockito.ArgumentCaptor.forClass(ContexteAchat.class);
        org.mockito.ArgumentCaptor<MontantEncaisse> montant =
                org.mockito.ArgumentCaptor.forClass(MontantEncaisse.class);
        verify(oneTimeAccessService).grantOneTimeAccess(
                eq(userId), any(), eq(SubscriptionSource.STRIPE), eq("pi_1"), eq("cs_1"),
                montant.capture(), contexte.capture());
        assertThat(montant.getValue().amountEurCents()).isEqualTo(999);
        assertThat(contexte.getValue().purchaseIntentId()).isEqualTo(intent);
        assertThat(contexte.getValue().fraisReelEurCents()).isEqualTo(39);
        assertThat(contexte.getValue().purchasedAt())
                .isEqualTo(java.time.Instant.ofEpochSecond(1_790_000_000L));
    }

    /** Un webhook rejoué sur un achat déjà en base ne rappelle pas Stripe. */
    @Test
    void checkoutCompleted_achatDejaEnBase_neRelitPasLeFrais() {
        when(billingProperties.isOneTime()).thenReturn(true);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, "pi_1"))
                .thenReturn(Optional.of(existingSub(SubscriptionStatus.ACTIVE)));

        service.dispatch(eventOf("checkout.session.completed",
                sessionPayee("paid", Map.of("planCode", "CIVIQUE_3MOIS"))));

        verify(stripeFeeClient, never()).fraisReelEurCents(any());
    }

    private Charge chargeRemboursee(long montant, long cumul) {
        Charge charge = mock(Charge.class);
        when(charge.getId()).thenReturn("ch_1");
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn("pi_99");
        when(charge.getAmount()).thenReturn(montant);
        when(charge.getAmountRefunded()).thenReturn(cumul);
        when(charge.getCurrency()).thenReturn("eur");
        return charge;
    }

    /**
     * Bug Q11 : un remboursement PARTIEL était traité comme total et retirait
     * l'accès. Désormais l'accès reste, l'encaissement est marqué partiel, et
     * la ligne de remboursement porte le montant rendu.
     */
    @Test
    void chargeRefunded_partiel_gardeLAcces_etEnregistreLeMontant() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        existing.setPaymentStatus(com.sejourfr.app.enums.PaymentStatus.PAID);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_99")).thenReturn(Optional.of(existing));
        when(paymentRefundService.dejaRembourse(existing)).thenReturn(0L);

        service.dispatch(eventOf("charge.refunded", chargeRemboursee(999, 300)));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(existing.getPaymentStatus())
                .isEqualTo(com.sejourfr.app.enums.PaymentStatus.PARTIALLY_REFUNDED);
        verify(paymentRefundService).enregistrer(eq(existing), eq("ch_1:300"), eq(300L), eq("eur"), any());
    }

    /** Le complément rembourse le reste : seule la différence est écrite, l'accès tombe. */
    @Test
    void chargeRefunded_complement_enregistreLaDifference_etRetireLAcces() {
        UserSubscription existing = existingSub(SubscriptionStatus.ACTIVE);
        existing.setPaymentStatus(com.sejourfr.app.enums.PaymentStatus.PARTIALLY_REFUNDED);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_99")).thenReturn(Optional.of(existing));
        when(paymentRefundService.dejaRembourse(existing)).thenReturn(300L);

        service.dispatch(eventOf("charge.refunded", chargeRemboursee(999, 999)));

        assertThat(existing.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(existing.getPaymentStatus()).isEqualTo(com.sejourfr.app.enums.PaymentStatus.REFUNDED);
        verify(paymentRefundService).enregistrer(eq(existing), eq("ch_1:999"), eq(699L), eq("eur"), any());
    }

    /** Un cumul déjà entièrement enregistré (rejeu) n'écrit rien. */
    @Test
    void chargeRefunded_cumulDejaEnregistre_nEcritPasDeLigne() {
        UserSubscription existing = existingSub(SubscriptionStatus.REFUNDED);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_99")).thenReturn(Optional.of(existing));
        when(paymentRefundService.dejaRembourse(existing)).thenReturn(999L);

        service.dispatch(eventOf("charge.refunded", chargeRemboursee(999, 999)));

        verify(paymentRefundService, never()).enregistrer(any(), any(), org.mockito.ArgumentMatchers.anyLong(), any(), any());
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

        verify(oneTimeAccessService, never())
                .grantOneTimeAccess(any(), any(), any(), any(), any(), any(), any());
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
        verify(oneTimeAccessService, never())
                .grantOneTimeAccess(any(), any(), any(), any(), any(), any(), any());
    }
}
