package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.Subscription;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * La colonne « mise à jour » de la console admin, contre la vraie base.
 *
 * <p>{@code UserSubscription.touchUpdatedAt()} est un {@code @PreUpdate} : il ne
 * s'exécute que si Hibernate émet réellement un {@code UPDATE}. Ce test vérifie
 * les deux bouts de la doctrine sur un vrai {@code EntityManager} et un vrai
 * Postgres : un webhook rejoué à état identique ne produit aucun {@code UPDATE}
 * (donc aucun bump), un webhook qui change l'état en produit un.
 *
 * <p>C'est la preuve que la garde ne repose pas seulement sur « on n'appelle pas
 * {@code save()} » : l'entité reste <b>non dirty</b> au flush, parce que les
 * {@code apply*} n'écrivent pas une valeur identique.
 */
class StripeWebhookUpdatedAtIT extends AbstractIntegrationTest {

    @Autowired
    private StripeSubscriptionService stripeSubscriptionService;
    @Autowired
    private UserSubscriptionManager userSubscriptionManager;
    @Autowired
    private TestData testData;
    @PersistenceContext
    private EntityManager entityManager;

    /** Un event {@code customer.subscription.updated} portant l'état donné. */
    private Event evenement(String subscriptionId, Instant finDePeriode, String derniereFacture) {
        Subscription subscription = mock(Subscription.class);
        when(subscription.getId()).thenReturn(subscriptionId);
        when(subscription.getStatus()).thenReturn("active");
        when(subscription.getCancelAtPeriodEnd()).thenReturn(false);
        when(subscription.getItems()).thenReturn(null); // pas de lookup plan
        when(subscription.getCurrentPeriodEnd()).thenReturn(finDePeriode.getEpochSecond());
        when(subscription.getLatestInvoice()).thenReturn(derniereFacture);

        Event event = mock(Event.class);
        when(event.getType()).thenReturn("customer.subscription.updated");
        EventDataObjectDeserializer deserializer = mock(EventDataObjectDeserializer.class);
        when(deserializer.getObject()).thenReturn(Optional.of(subscription));
        when(event.getDataObjectDeserializer()).thenReturn(deserializer);
        return event;
    }

    /**
     * Une souscription déjà à jour, dont {@code updated_at} est reculé d'une
     * heure en SQL direct — sinon on ne saurait pas distinguer « pas touché » de
     * « réécrit à la même seconde ».
     */
    private UserSubscription souscriptionAJour(Instant finDePeriode) {
        UserSubscription sub = testData.userSubscription();
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setAutoRenew(true);
        sub.setEndsAt(finDePeriode);
        sub.setExternalTransactionId("in_1");
        userSubscriptionManager.save(sub);
        entityManager.flush();
        entityManager.createNativeQuery(
                        "UPDATE user_subscriptions SET updated_at = now() - interval '1 hour' "
                                + "WHERE id = :id")
                .setParameter("id", sub.getId())
                .executeUpdate();
        entityManager.clear();
        return userSubscriptionManager.findById(sub.getId()).orElseThrow();
    }

    private Instant updatedAtEnBase(UserSubscription sub) {
        entityManager.flush();
        entityManager.clear();
        return userSubscriptionManager.findById(sub.getId()).orElseThrow().getUpdatedAt();
    }

    @Test
    @DisplayName("Un webhook qui n'apporte aucun changement métier ne fait pas avancer updated_at")
    void webhookSansChangement_nAvancePasUpdatedAt() {
        // Seconde pleine : le `current_period_end` de Stripe est en secondes,
        // un `endsAt` avec des micros paraîtrait changer à chaque event.
        Instant finDePeriode = Instant.now().plus(30, ChronoUnit.DAYS)
                .truncatedTo(ChronoUnit.SECONDS);
        UserSubscription sub = souscriptionAJour(finDePeriode);
        Instant repere = sub.getUpdatedAt();
        assertThat(repere).isBefore(Instant.now().minus(30, ChronoUnit.MINUTES));

        stripeSubscriptionService.dispatch(
                evenement(sub.getOriginalTransactionId(), finDePeriode, "in_1"));

        assertThat(updatedAtEnBase(sub)).isEqualTo(repere);
    }

    @Test
    @DisplayName("Un webhook qui change vraiment l'état fait avancer updated_at")
    void webhookAvecChangement_avanceUpdatedAt() {
        Instant finDePeriode = Instant.now().plus(30, ChronoUnit.DAYS)
                .truncatedTo(ChronoUnit.SECONDS);
        UserSubscription sub = souscriptionAJour(finDePeriode);
        Instant repere = sub.getUpdatedAt();

        // Renouvellement : la période est repoussée d'un mois.
        stripeSubscriptionService.dispatch(evenement(
                sub.getOriginalTransactionId(),
                finDePeriode.plus(30, ChronoUnit.DAYS),
                "in_2"));

        assertThat(updatedAtEnBase(sub)).isAfter(repere);
        UserSubscription relu = userSubscriptionManager.findById(sub.getId()).orElseThrow();
        assertThat(relu.getEndsAt()).isEqualTo(finDePeriode.plus(30, ChronoUnit.DAYS));
    }
}
