package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Intégration réelle (Postgres embarqué) du {@link UserSubscriptionManager} :
 * lookups par user / clé Stripe / clé canonique de réconciliation, recherche
 * paginée par Specification, requête métier des passes one-time, et la
 * contrainte d'unicité {@code (source, original_transaction_id)} (V103).
 */
class UserSubscriptionManagerIT extends AbstractIntegrationTest {

    @Autowired
    private UserSubscriptionManager manager;

    @Autowired
    private UserSubscriptionRepository repository;

    @Autowired
    private PlanManager planManager;

    @Autowired
    private TestData testData;

    @Test
    void findByUserIdReturnsOnlyThatUsersSubscriptions() {
        User user = testData.user();
        Plan plan = testData.plan();
        UserSubscription s1 = testData.userSubscription(user, plan);
        UserSubscription s2 = testData.userSubscription(user, plan);
        UserSubscription other = testData.userSubscription();

        List<UserSubscription> found = manager.findByUserId(user.getId());

        assertThat(found).extracting(UserSubscription::getId)
                .containsExactlyInAnyOrder(s1.getId(), s2.getId())
                .doesNotContain(other.getId());
    }

    @Test
    void findByIdReturnsMatchAndEmptyWhenAbsent() {
        UserSubscription s = testData.userSubscription();

        assertThat(manager.findById(s.getId())).isPresent();
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void saveAssignsIdAndTimestamps() {
        UserSubscription s = testData.userSubscription();

        assertThat(s.getId()).isNotNull();
        assertThat(s.getUpdatedAt()).isNotNull();
        assertThat(manager.findById(s.getId())).isPresent();
    }

    @Test
    void findByStripeSubscriptionIdSelectsMatch() {
        String stripeSubId = "sub_" + UUID.randomUUID();
        UserSubscription s = testData.userSubscription();
        s.setStripeSubscriptionId(stripeSubId);
        manager.save(s);

        Optional<UserSubscription> found = manager.findByStripeSubscriptionId(stripeSubId);
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(s.getId());
        assertThat(manager.findByStripeSubscriptionId("sub_absent_" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findBySourceAndOriginalTransactionIdMatchesOnBothColumns() {
        UserSubscription s = testData.userSubscription(); // source STRIPE
        String tx = s.getOriginalTransactionId();

        assertThat(manager.findBySourceAndOriginalTransactionId(SubscriptionSource.STRIPE, tx))
                .get().extracting(UserSubscription::getId).isEqualTo(s.getId());
        // Bonne tx mais mauvaise source → pas de match (l'index est composite).
        assertThat(manager.findBySourceAndOriginalTransactionId(SubscriptionSource.APPLE, tx))
                .isEmpty();
        // Bonne source mais tx inconnue → pas de match.
        assertThat(manager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "tx_absent_" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findAllWithSpecificationFiltersByStatus() {
        User user = testData.user();
        Plan plan = testData.plan();
        UserSubscription active = testData.userSubscription(user, plan);
        UserSubscription canceled = testData.userSubscription(user, plan);
        canceled.setStatus(SubscriptionStatus.CANCELED);
        manager.save(canceled);

        Specification<UserSubscription> spec = (root, query, cb) -> cb.and(
                cb.equal(root.get("user").get("id"), user.getId()),
                cb.equal(root.get("status"), SubscriptionStatus.ACTIVE));

        Page<UserSubscription> page = manager.findAll(spec, PageRequest.of(0, 10));

        assertThat(page.getContent()).extracting(UserSubscription::getId)
                .containsExactly(active.getId())
                .doesNotContain(canceled.getId());
    }

    @Test
    void findOneTimeExpiringSoonSelectsOnlyActiveOneTimeWithinWindowNotReminded() {
        User user = testData.user();
        Plan oneTime = testData.plan();
        oneTime.setPurchaseType(PlanPurchaseType.ONE_TIME);
        planManager.save(oneTime);
        Plan subPlan = testData.plan(); // reste en SUBSCRIPTION

        Instant now = Instant.now();
        Instant threshold = now.plus(14, ChronoUnit.DAYS);

        UserSubscription eligible = makeOneTime(user, oneTime, now.plus(5, ChronoUnit.DAYS), null);
        // Déjà rappelé → exclu.
        makeOneTime(user, oneTime, now.plus(5, ChronoUnit.DAYS), now);
        // Au-delà de la fenêtre → exclu.
        makeOneTime(user, oneTime, now.plus(30, ChronoUnit.DAYS), null);
        // Déjà expiré (endsAt <= now) → exclu.
        makeOneTime(user, oneTime, now.minus(1, ChronoUnit.DAYS), null);
        // Abonnement récurrent dans la fenêtre → exclu (purchaseType != ONE_TIME).
        UserSubscription recurring = testData.userSubscription(user, subPlan);
        recurring.setEndsAt(now.plus(5, ChronoUnit.DAYS));
        manager.save(recurring);

        List<UserSubscription> found = manager.findOneTimeExpiringSoon(now, threshold);

        assertThat(found).extracting(UserSubscription::getId).containsExactly(eligible.getId());
    }

    private UserSubscription makeOneTime(User user, Plan plan, Instant endsAt, Instant remindedAt) {
        UserSubscription s = testData.userSubscription(user, plan);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setEndsAt(endsAt);
        s.setExpiryRemindedAt(remindedAt);
        return manager.save(s);
    }

    @Test
    void duplicateSourceAndOriginalTransactionIdViolatesUniqueIndex() {
        UserSubscription first = testData.userSubscription();

        UserSubscription dup = new UserSubscription();
        dup.setUser(first.getUser());
        dup.setPlan(first.getPlan());
        dup.setStatus(SubscriptionStatus.ACTIVE);
        dup.setStartsAt(Instant.now());
        dup.setSource(first.getSource());
        dup.setOriginalTransactionId(first.getOriginalTransactionId());

        assertThatThrownBy(() -> repository.saveAndFlush(dup))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
