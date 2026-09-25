package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.stripe.model.Charge;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Contrôle A de la passe Suivi : remboursements Stripe CONCURRENTS, contre la
 * vraie base.
 *
 * <p>🛑 <b>Hors transaction de test</b> ({@code NOT_SUPPORTED}) : il faut deux
 * transactions réelles, qui commitent, pour exercer le verrou de ligne et le
 * {@code ON CONFLICT DO NOTHING}. Chaque livraison tourne dans sa propre
 * transaction, comme {@code BillingService.handleWebhook}. Les comptes créés
 * sont supprimés après chaque test (cascade vers achats et remboursements).
 *
 * <p>Aucun appel Stripe : les objets Stripe sont des mocks.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class RemboursementsConcurrentsIT extends AbstractIntegrationTest {

    @Autowired
    private StripeSubscriptionService stripeSubscriptionService;
    @Autowired
    private UserSubscriptionManager userSubscriptionManager;
    @Autowired
    private RevenueCalculator revenueCalculator;
    @Autowired
    private TestData testData;
    @Autowired
    private JdbcTemplate jdbc;
    @Autowired
    private PlatformTransactionManager transactionManager;

    private final List<UUID> users = new ArrayList<>();
    private final List<UUID> plans = new ArrayList<>();

    @AfterEach
    void nettoyer() {
        users.forEach(id -> jdbc.update("DELETE FROM users WHERE id = ?", id));
        plans.forEach(id -> jdbc.update("DELETE FROM plans WHERE id = ?", id));
        users.clear();
        plans.clear();
    }

    /** Un pass Stripe à 9,99 € commité, décomposé comme au crédit réel. */
    private UserSubscription achatCommite(String paymentIntent) {
        User user = testData.user();
        users.add(user.getId());
        Plan plan = testData.plan();
        plans.add(plan.getId());
        UserSubscription sub = new UserSubscription();
        sub.setUser(user);
        sub.setPlan(plan);
        sub.setProductId(plan.getCode());
        sub.setSource(SubscriptionSource.STRIPE);
        sub.setOriginalTransactionId(paymentIntent);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setAutoRenew(false);
        sub.setStartsAt(Instant.now());
        sub.setEndsAt(Instant.now().plusSeconds(86_400L * 30));
        new MontantEncaisse(999, "EUR", 999, BigDecimal.ONE).appliquerA(sub);
        revenueCalculator.decomposer(SubscriptionSource.STRIPE, 999, null).appliquerA(sub);
        sub.setPurchasedAt(Instant.now());
        sub.setPaymentStatus(PaymentStatus.PAID);
        return userSubscriptionManager.save(sub);
    }

    private static Event chargeRefunded(String paymentIntent, long cumul) {
        Charge charge = mock(Charge.class);
        when(charge.getId()).thenReturn("ch_" + paymentIntent);
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn(paymentIntent);
        when(charge.getAmount()).thenReturn(999L);
        when(charge.getAmountRefunded()).thenReturn(cumul);
        when(charge.getCurrency()).thenReturn("eur");
        Event event = mock(Event.class);
        when(event.getType()).thenReturn("charge.refunded");
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond());
        EventDataObjectDeserializer deserializer = mock(EventDataObjectDeserializer.class);
        when(deserializer.getObject()).thenReturn(Optional.<StripeObject>of(charge));
        when(event.getDataObjectDeserializer()).thenReturn(deserializer);
        return event;
    }

    /** Une livraison de webhook = une transaction, comme {@code BillingService.handleWebhook}. */
    private void livrer(Event event) {
        new TransactionTemplate(transactionManager)
                .executeWithoutResult(status -> stripeSubscriptionService.dispatch(event));
    }

    private int lignes(UUID subId) {
        return jdbc.queryForObject("SELECT count(*) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, subId);
    }

    private int montantRembourse(UUID subId) {
        return jdbc.queryForObject(
                "SELECT COALESCE(SUM(refunded_amount_cents), 0) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, subId);
    }

    @Test
    @DisplayName("Contrôle A — le même remboursement total livré deux fois en parallèle : une ligne, accès retiré, aucune erreur")
    void memeRemboursementLivreEnParallele() throws Exception {
        String pi = "pi_" + UUID.randomUUID();
        UUID subId = achatCommite(pi).getId();
        CountDownLatch depart = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<?> a = pool.submit(() -> {
                depart.await();
                livrer(chargeRefunded(pi, 999));
                return null;
            });
            Future<?> b = pool.submit(() -> {
                depart.await();
                livrer(chargeRefunded(pi, 999));
                return null;
            });
            depart.countDown();
            // Aucune des deux livraisons ne lève : ni l'unicité, ni le verrou.
            a.get(30, TimeUnit.SECONDS);
            b.get(30, TimeUnit.SECONDS);
        } finally {
            pool.shutdownNow();
        }

        assertThat(lignes(subId)).isEqualTo(1);
        assertThat(montantRembourse(subId)).isEqualTo(999);
        UserSubscription relu = userSubscriptionManager.findById(subId).orElseThrow();
        assertThat(relu.getStatus()).isEqualTo(SubscriptionStatus.REFUNDED);
        assertThat(relu.getPaymentStatus()).isEqualTo(PaymentStatus.REFUNDED);
    }

    /**
     * Le cas de double comptage de la passe de contrôle : deux cumuls
     * différents (300 puis 600) traités en parallèle lisaient le même « déjà
     * remboursé » (100) et écrivaient 200 + 500. La première livraison garde
     * ici sa transaction ouverte pendant que la seconde démarre : sous verrou,
     * la seconde attend, relit 300 et n'écrit que la différence.
     *
     * <p>L'achat est déjà {@code PARTIALLY_REFUNDED} (100 rendus, commités) :
     * aucune des deux livraisons ne change l'état d'accès, donc aucun
     * {@code UPDATE} ne les sérialise par accident — seul le verrou explicite
     * le fait.
     */
    @Test
    @DisplayName("Contrôle A — deux cumuls partiels concurrents : la différence est comptée une seule fois")
    void cumulsPartielsConcurrents_pasDeDoubleComptage() throws Exception {
        String pi = "pi_" + UUID.randomUUID();
        UUID subId = achatCommite(pi).getId();
        livrer(chargeRefunded(pi, 100));
        CountDownLatch premiereEcrite = new CountDownLatch(1);
        CountDownLatch liberer = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<?> premiere = pool.submit(() -> {
                new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
                    stripeSubscriptionService.dispatch(chargeRefunded(pi, 300));
                    premiereEcrite.countDown();
                    try {
                        liberer.await(30, TimeUnit.SECONDS);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                });
                return null;
            });
            assertThat(premiereEcrite.await(30, TimeUnit.SECONDS)).isTrue();
            Future<?> seconde = pool.submit(() -> {
                livrer(chargeRefunded(pi, 600));
                return null;
            });
            // La seconde a le temps d'arriver sur le verrou avant le commit de la première.
            Thread.sleep(500);
            assertThat(seconde.isDone()).as("la seconde livraison attend le verrou").isFalse();
            liberer.countDown();
            premiere.get(30, TimeUnit.SECONDS);
            seconde.get(30, TimeUnit.SECONDS);
        } finally {
            liberer.countDown();
            pool.shutdownNow();
        }

        assertThat(lignes(subId)).isEqualTo(3);
        assertThat(montantRembourse(subId)).isEqualTo(600);
        UserSubscription relu = userSubscriptionManager.findById(subId).orElseThrow();
        assertThat(relu.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(relu.getPaymentStatus()).isEqualTo(PaymentStatus.PARTIALLY_REFUNDED);
    }

    @Test
    @DisplayName("Contrôle A — un remboursement rejoué après commit n'écrit rien de plus")
    void remboursementRejoue_idempotent() {
        String pi = "pi_" + UUID.randomUUID();
        UUID subId = achatCommite(pi).getId();

        livrer(chargeRefunded(pi, 999));
        livrer(chargeRefunded(pi, 999));

        assertThat(lignes(subId)).isEqualTo(1);
        assertThat(userSubscriptionManager.findById(subId).orElseThrow().getStatus())
                .isEqualTo(SubscriptionStatus.REFUNDED);
    }
}
