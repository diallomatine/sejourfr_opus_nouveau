package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.FeeSource;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PurchaseOrigin;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContext;
import com.stripe.model.BalanceTransaction;
import com.stripe.model.Charge;
import com.stripe.model.Dispute;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import com.stripe.model.checkout.Session;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Scenarios 11, 12 et 13 du brief (chantier Suivi, lot 2b), contre la vraie
 * base : les CHECK de V074 (invariant de revenu, tout-ou-rien, delta &le; 0,
 * unicite des remboursements) sont ceux de la production.
 *
 * <p>Aucun appel Stripe : les objets Stripe sont des mocks, et
 * {@link StripeFeeClient} renonce de lui-meme (cle secrete vide en test) —
 * d'ou {@code fee_source = ESTIMATED}.
 */
class RevenusEtRemboursementsIT extends AbstractIntegrationTest {

    @Autowired
    private StripeSubscriptionService stripeSubscriptionService;
    @Autowired
    private OneTimeAccessService oneTimeAccessService;
    @Autowired
    private PaymentRefundService paymentRefundService;
    @Autowired
    private PurchaseIntentService purchaseIntentService;
    @Autowired
    private MontantEncaisseResolver montantEncaisseResolver;
    @Autowired
    private UserSubscriptionManager userSubscriptionManager;
    @Autowired
    private TestData testData;
    @Autowired
    private JdbcTemplate jdbc;
    @PersistenceContext
    private EntityManager em;

    private static final ClientContext WEB = new ClientContext(ClientPlatform.WEB, "direct");

    private static Event event(String type, StripeObject objet) {
        Event event = mock(Event.class);
        when(event.getType()).thenReturn(type);
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond());
        EventDataObjectDeserializer deserializer = mock(EventDataObjectDeserializer.class);
        when(deserializer.getObject()).thenReturn(Optional.of(objet));
        when(event.getDataObjectDeserializer()).thenReturn(deserializer);
        return event;
    }

    private static Session sessionPayee(User user, Plan plan, String paymentIntent, String intentId) {
        Session session = mock(Session.class);
        when(session.getSubscription()).thenReturn(null);
        when(session.getClientReferenceId()).thenReturn(user.getId().toString());
        when(session.getMetadata()).thenReturn(intentId == null
                ? Map.of("planCode", plan.getCode())
                : Map.of("planCode", plan.getCode(), "intentId", intentId));
        when(session.getPaymentIntent()).thenReturn(paymentIntent);
        when(session.getPaymentStatus()).thenReturn("paid");
        when(session.getAmountTotal()).thenReturn(999L);
        when(session.getCurrency()).thenReturn("eur");
        when(session.getId()).thenReturn("cs_" + paymentIntent);
        return session;
    }

    private static Charge charge(String paymentIntent, long cumulRembourse) {
        Charge charge = mock(Charge.class);
        when(charge.getId()).thenReturn("ch_" + paymentIntent);
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn(paymentIntent);
        when(charge.getAmount()).thenReturn(999L);
        when(charge.getAmountRefunded()).thenReturn(cumulRembourse);
        when(charge.getCurrency()).thenReturn("eur");
        return charge;
    }

    /** Un pass Stripe à 9,99 € réellement crédité par le webhook. */
    private UserSubscription achatStripe(String paymentIntent) {
        User user = testData.user();
        Plan plan = testData.plan();
        stripeSubscriptionService.dispatch(event("checkout.session.completed",
                sessionPayee(user, plan, paymentIntent, null)));
        em.flush();
        return userSubscriptionManager
                .findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, paymentIntent)
                .orElseThrow();
    }

    private Integer sommeDesDeltas(UserSubscription sub) {
        em.flush();
        return jdbc.queryForObject(
                "SELECT COALESCE(SUM(net_ex_vat_delta_cents), 0) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, sub.getId());
    }

    private int lignesDeRemboursement(UserSubscription sub) {
        em.flush();
        return jdbc.queryForObject("SELECT count(*) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, sub.getId());
    }

    // ------------------------------------------------------------------------
    // Scénario 11 — webhook reçu 2 fois → 1 achat
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Scénario 11 — le même achat Stripe notifié deux fois ne crée qu'une ligne et ne consomme l'intention qu'une fois")
    void webhookRecuDeuxFois_unSeulAchat() {
        User user = testData.user();
        Plan plan = testData.plan();
        String intent = purchaseIntentService
                .creerPourCheckout(user.getId(), plan, "PRICING", null, WEB)
                .orElseThrow().toString();
        String pi = "pi_" + UUID.randomUUID();

        stripeSubscriptionService.dispatch(event("checkout.session.completed",
                sessionPayee(user, plan, pi, intent)));
        stripeSubscriptionService.dispatch(event("checkout.session.completed",
                sessionPayee(user, plan, pi, intent)));
        em.flush();

        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM user_subscriptions WHERE source = 'STRIPE' AND original_transaction_id = ?",
                Integer.class, pi)).isEqualTo(1);
        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, pi).orElseThrow();
        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.OTHER_CTA);
        assertThat(sub.getPurchaseIntentId()).hasToString(intent);
    }

    // ------------------------------------------------------------------------
    // Contrôle B — paiement différé : l'intention se juge à la session
    // ------------------------------------------------------------------------

    /** Une intention posée il y a trois jours, déjà expirée (TTL 24 h) à l'heure de l'encaissement. */
    private String intentionVieilleDeTroisJours(User user, Plan plan, Instant creeeA) {
        String intent = purchaseIntentService
                .creerPourCheckout(user.getId(), plan, "PRICING", null, WEB)
                .orElseThrow().toString();
        em.flush();
        jdbc.update("UPDATE purchase_intent SET created_at = ?, expires_at = ? WHERE id = ?::uuid",
                java.sql.Timestamp.from(creeeA),
                java.sql.Timestamp.from(creeeA.plus(24, java.time.temporal.ChronoUnit.HOURS)), intent);
        em.clear();
        return intent;
    }

    @Test
    @DisplayName("Contrôle B — paiement différé encaissé à J+3 : l'intention posée à la session est attribuée")
    void paiementDiffereAJPlus3_intentionJugeeALaSession() {
        User user = testData.user();
        Plan plan = testData.plan();
        Instant clic = Instant.now().minus(3, java.time.temporal.ChronoUnit.DAYS);
        String intent = intentionVieilleDeTroisJours(user, plan, clic);
        String pi = "pi_" + UUID.randomUUID();
        Session session = sessionPayee(user, plan, pi, intent);
        when(session.getCreated()).thenReturn(clic.plusSeconds(30).getEpochSecond());
        Instant encaissement = Instant.now().truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
        Event succes = event("checkout.session.async_payment_succeeded", session);
        when(succes.getCreated()).thenReturn(encaissement.getEpochSecond());

        stripeSubscriptionService.dispatch(succes);
        em.flush();

        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, pi).orElseThrow();
        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.OTHER_CTA);
        assertThat(sub.getPurchaseIntentId()).hasToString(intent);
        // L'achat, lui, reste daté de l'encaissement.
        assertThat(sub.getPurchasedAt()).isEqualTo(encaissement);
    }

    @Test
    @DisplayName("Contrôle B — sans date de session lisible, l'intention se juge à l'encaissement (expirée → UNKNOWN)")
    void sansDateDeSession_repliSurLEncaissement() {
        User user = testData.user();
        Plan plan = testData.plan();
        String intent = intentionVieilleDeTroisJours(user, plan,
                Instant.now().minus(3, java.time.temporal.ChronoUnit.DAYS));
        String pi = "pi_" + UUID.randomUUID();
        Session session = sessionPayee(user, plan, pi, intent);
        when(session.getCreated()).thenReturn(null);

        stripeSubscriptionService.dispatch(event("checkout.session.async_payment_succeeded", session));
        em.flush();

        UserSubscription sub = userSubscriptionManager
                .findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, pi).orElseThrow();
        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
    }

    // ------------------------------------------------------------------------
    // Scénario 12 — montants au centime, invariant tenu par la base
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Scénario 12 — Stripe 9,99 € : TVA 0, frais 0,40, net 9,59, figés avec leur version")
    void stripeDecomposeAuCentime() {
        UserSubscription sub = achatStripe("pi_" + UUID.randomUUID());

        assertThat(sub.getAmountEurCents()).isEqualTo(999);
        assertThat(sub.getVatCents()).isZero();
        assertThat(sub.getProviderFeeCents()).isEqualTo(40);
        assertThat(sub.getNetAfterFeeCents()).isEqualTo(959);
        assertThat(sub.getNetExVatCents()).isEqualTo(959);
        assertThat(sub.getFeeSource()).isEqualTo(FeeSource.ESTIMATED);
        assertThat(sub.getRevenueRulesVersion()).isEqualTo(1);
        assertThat(sub.getPaymentStatus()).isEqualTo(PaymentStatus.PAID);
        assertThat(sub.getPurchasedAt()).isNotNull();
        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
    }

    @Test
    @DisplayName("Scénario 12 — Apple 9,99 € à 15 % : TVA 1,66, commission 1,25, net 7,08")
    void storeDecomposeAuCentime() {
        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                testData.user().getId(), testData.plan(), SubscriptionSource.APPLE,
                "tx-" + UUID.randomUUID(), "tx", montantEncaisseResolver.duJwsApple(9990L, "EUR"),
                ContexteAchat.AUCUN);
        em.flush();

        assertThat(sub.getVatCents()).isEqualTo(166);
        assertThat(sub.getProviderFeeCents()).isEqualTo(125);
        assertThat(sub.getNetAfterFeeCents()).isEqualTo(708);
        assertThat(sub.getNetExVatCents()).isEqualTo(708);
        assertThat(jdbc.queryForObject(
                "SELECT amount_eur_cents = vat_cents + provider_fee_cents + net_ex_vat_cents "
                        + "FROM user_subscriptions WHERE id = ?", Boolean.class, sub.getId())).isTrue();
    }

    /**
     * {@code null} = inconnu (Q16) : une devise sans taux ne donne pas de brut
     * en euros, donc aucune décomposition — les six colonnes restent NULL,
     * jamais zéro.
     */
    @Test
    @DisplayName("Sans brut en euros connu, la décomposition reste NULL (jamais zéro)")
    void brutInconnu_decompositionNulle() {
        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                testData.user().getId(), testData.plan(), SubscriptionSource.APPLE,
                "tx-" + UUID.randomUUID(), "tx", montantEncaisseResolver.duJwsApple(1_500_000L, "JPY"),
                ContexteAchat.AUCUN);
        em.flush();

        assertThat(sub.getAmountEurCents()).isNull();
        assertThat(sub.getNetExVatCents()).isNull();
        assertThat(sub.getFeeSource()).isNull();
        assertThat(sub.getRevenueRulesVersion()).isNull();
        assertThat(sub.getPaymentStatus()).isEqualTo(PaymentStatus.PAID);
    }

    // ------------------------------------------------------------------------
    // Scénario 13 — remboursements
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Scénario 13 — remboursement Stripe total : le net de l'achat finit à −0,40 €, un rejeu n'écrit rien")
    void remboursementStripeTotal() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);

        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 999)));
        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 999)));

        assertThat(lignesDeRemboursement(sub)).isEqualTo(1);
        assertThat(sub.getNetExVatCents() + sommeDesDeltas(sub)).isEqualTo(-40);
        UserSubscription relu = userSubscriptionManager.findById(sub.getId()).orElseThrow();
        assertThat(relu.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(relu.getPaymentStatus()).isEqualTo(PaymentStatus.REFUNDED);
    }

    @Test
    @DisplayName("Remboursement Stripe partiel : l'accès reste, puis le complément le retire — deux lignes")
    void remboursementStripePartielPuisComplement() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);

        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 300)));
        em.flush();
        UserSubscription apresPartiel = userSubscriptionManager.findById(sub.getId()).orElseThrow();
        assertThat(apresPartiel.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(apresPartiel.getPaymentStatus()).isEqualTo(PaymentStatus.PARTIALLY_REFUNDED);
        assertThat(sommeDesDeltas(sub)).isEqualTo(-300);

        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 999)));

        assertThat(lignesDeRemboursement(sub)).isEqualTo(2);
        assertThat(jdbc.queryForObject(
                "SELECT SUM(refunded_amount_cents) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, sub.getId())).isEqualTo(999);
        assertThat(sub.getNetExVatCents() + sommeDesDeltas(sub)).isEqualTo(-40);
        assertThat(userSubscriptionManager.findById(sub.getId()).orElseThrow().getStatus())
                .isEqualTo(SubscriptionStatus.REFUNDED);
    }

    @Test
    @DisplayName("Scénario 13 — remboursement store total : le net de l'achat finit à 0")
    void remboursementStoreTotal() {
        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                testData.user().getId(), testData.plan(), SubscriptionSource.GOOGLE,
                "tok-" + UUID.randomUUID(), "GPA.1", montantEncaisseResolver.enUnitesMineures(999L, "EUR"),
                ContexteAchat.AUCUN);
        em.flush();

        assertThat(paymentRefundService.enregistrer(sub, "GPA.1", 999, "EUR", Instant.now())).isTrue();
        assertThat(paymentRefundService.enregistrer(sub, "GPA.1", 999, "EUR", Instant.now())).isFalse();

        assertThat(lignesDeRemboursement(sub)).isEqualTo(1);
        assertThat(sub.getNetExVatCents() + sommeDesDeltas(sub)).isZero();
    }

    // ------------------------------------------------------------------------
    // Contrôle N6 — litiges Stripe
    // ------------------------------------------------------------------------

    private static Dispute litige(String paymentIntent, String statut, Long fraisEurCents) {
        Dispute dispute = mock(Dispute.class);
        when(dispute.getId()).thenReturn("du_" + paymentIntent);
        when(dispute.getStatus()).thenReturn(statut);
        when(dispute.getPaymentIntent()).thenReturn(paymentIntent);
        when(dispute.getCharge()).thenReturn("ch_" + paymentIntent);
        when(dispute.getAmount()).thenReturn(999L);
        when(dispute.getCurrency()).thenReturn("eur");
        if (fraisEurCents != null) {
            BalanceTransaction retrait = mock(BalanceTransaction.class);
            when(retrait.getFee()).thenReturn(fraisEurCents);
            when(retrait.getCurrency()).thenReturn("eur");
            when(dispute.getBalanceTransactions()).thenReturn(java.util.List.of(retrait));
        }
        return dispute;
    }

    @Test
    @DisplayName("N6 — litige perdu : accès retiré, ligne du montant contesté, frais de litige dans le delta ; rejoué : rien de plus")
    void litigePerdu_retireLAcces_etEcritUneLigne() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);

        stripeSubscriptionService.dispatch(event("charge.dispute.closed", litige(pi, "lost", 1500L)));
        stripeSubscriptionService.dispatch(event("charge.dispute.closed", litige(pi, "lost", 1500L)));

        assertThat(lignesDeRemboursement(sub)).isEqualTo(1);
        assertThat(jdbc.queryForObject(
                "SELECT provider_refund_id FROM payment_refunds WHERE subscription_id = ?",
                String.class, sub.getId())).isEqualTo("dispute:du_" + pi);
        // Net de l'achat : 959 − 999 (contesté) − 1500 (frais de litige) = −1540.
        assertThat(sub.getNetExVatCents() + sommeDesDeltas(sub)).isEqualTo(-1540);
        UserSubscription relu = userSubscriptionManager.findById(sub.getId()).orElseThrow();
        assertThat(relu.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(relu.getPaymentStatus()).isEqualTo(PaymentStatus.REFUNDED);
    }

    @Test
    @DisplayName("N6 — litige gagné (ou autre statut) : rien ne change")
    void litigeGagne_rienNeChange() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);

        stripeSubscriptionService.dispatch(event("charge.dispute.closed", litige(pi, "won", 1500L)));
        stripeSubscriptionService.dispatch(event("charge.dispute.closed", litige(pi, "warning_closed", null)));

        assertThat(lignesDeRemboursement(sub)).isZero();
        UserSubscription relu = userSubscriptionManager.findById(sub.getId()).orElseThrow();
        assertThat(relu.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(relu.getPaymentStatus()).isEqualTo(PaymentStatus.PAID);
    }

    @Test
    @DisplayName("N6 — litige perdu sans frais lisibles : ligne écrite, effet sur le net inconnu (NULL)")
    void litigePerdu_fraisIllisibles_deltaInconnu() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);

        stripeSubscriptionService.dispatch(event("charge.dispute.closed", litige(pi, "lost", null)));

        assertThat(jdbc.queryForObject(
                "SELECT refunded_eur_cents = 999 AND net_ex_vat_delta_cents IS NULL "
                        + "AND revenue_rules_version IS NULL FROM payment_refunds WHERE subscription_id = ?",
                Boolean.class, sub.getId())).isTrue();
        assertThat(userSubscriptionManager.findById(sub.getId()).orElseThrow().getStatus())
                .isEqualTo(SubscriptionStatus.REFUNDED);
    }

    /**
     * Une ligne de litige n'entre pas dans le cumul {@code amount_refunded}
     * d'une charge. Cas réel d'ordre de livraison : 3 € rendus, litige perdu
     * sur le reste (6,99 €), mais le {@code charge.refunded} arrive APRÈS le
     * litige. Retrancher la ligne de litige du cumul aurait fait disparaître
     * le remboursement.
     */
    @Test
    @DisplayName("N6 — la ligne de litige ne fausse pas le cumul des remboursements de la charge")
    void litigeHorsCumulDeLaCharge() {
        String pi = "pi_" + UUID.randomUUID();
        UserSubscription sub = achatStripe(pi);
        Dispute surLeReste = litige(pi, "lost", 1500L);
        when(surLeReste.getAmount()).thenReturn(699L);

        stripeSubscriptionService.dispatch(event("charge.dispute.closed", surLeReste));
        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 300)));
        stripeSubscriptionService.dispatch(event("charge.refunded", charge(pi, 300)));

        assertThat(lignesDeRemboursement(sub)).isEqualTo(2);
        assertThat(jdbc.queryForObject(
                "SELECT SUM(refunded_amount_cents) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, sub.getId())).isEqualTo(999);
        assertThat(userSubscriptionManager.findById(sub.getId()).orElseThrow().getStatus())
                .isEqualTo(SubscriptionStatus.REFUNDED);
    }

    /**
     * Contrôle A : un calcul qui lève (ici, une conversion en euros qui déborde
     * d'un {@code int}) ne fait pas tomber l'écriture — la ligne existe, son
     * effet en euros et sur le net est inconnu, et les CHECK de V074 tiennent.
     */
    @Test
    @DisplayName("Remboursement dont la conversion déborde : ligne écrite, euros et delta NULL")
    void remboursementCalculQuiDeborde_ligneEcriteEffetInconnu() {
        UserSubscription achat = testData.userSubscription();
        achat.setAmountCents(5000);
        achat.setCurrency("XXA");
        achat.setFxRateToEur(new java.math.BigDecimal("999999"));
        userSubscriptionManager.save(achat);
        em.flush();

        assertThat(paymentRefundService.enregistrer(achat, "deborde-1", 5000, "XXA", Instant.now())).isTrue();
        em.flush();

        assertThat(jdbc.queryForObject(
                "SELECT refunded_eur_cents IS NULL AND net_ex_vat_delta_cents IS NULL "
                        + "AND revenue_rules_version IS NULL AND refunded_amount_cents = 5000 "
                        + "FROM payment_refunds WHERE subscription_id = ?", Boolean.class, achat.getId()))
                .isTrue();
    }

    /**
     * Un achat antérieur à la mesure n'a pas de décomposition : son
     * remboursement est enregistré (montant, date), mais son effet sur le net
     * reste inconnu — NULL, jamais un zéro inventé.
     */
    @Test
    @DisplayName("Remboursement d'un achat sans décomposition : delta NULL, pas de règle figée")
    void remboursementDUnAchatAnterieur_deltaInconnu() {
        UserSubscription legacy = testData.userSubscription();
        legacy.setAmountCents(999);
        legacy.setCurrency("EUR");
        legacy.setAmountEurCents(999);
        legacy.setFxRateToEur(java.math.BigDecimal.ONE);
        userSubscriptionManager.save(legacy);
        em.flush();

        paymentRefundService.enregistrer(legacy, "legacy-1", 999, "EUR", Instant.now());
        em.flush();

        assertThat(jdbc.queryForObject(
                "SELECT net_ex_vat_delta_cents IS NULL AND revenue_rules_version IS NULL "
                        + "FROM payment_refunds WHERE subscription_id = ?", Boolean.class, legacy.getId()))
                .isTrue();
    }
}
