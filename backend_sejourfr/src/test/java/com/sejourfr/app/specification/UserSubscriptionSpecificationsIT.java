package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) de {@link UserSubscriptionSpecifications}.
 * Les prédicats sont exercés via {@code findAll(spec)} pour valider le SQL —
 * notamment {@code hasModuleAccess} qui JOIN le {@code plan} (lazy) et
 * {@code userSearch} qui JOIN le {@code user}. Combinaison via
 * {@code where(...).and(...)} comme {@code AdminSubscriptionService}.
 *
 * <p>{@code user_subscriptions} n'est pas seedée par Flyway → assertions
 * exactes (seules les lignes du test existent dans la transaction rollbackée).</p>
 */
class UserSubscriptionSpecificationsIT extends AbstractIntegrationTest {

    @Autowired
    private UserSubscriptionRepository repository;

    @Autowired
    private PlanManager planManager;

    @Autowired
    private UserManager userManager;

    @Autowired
    private TestData testData;

    private UserSubscription sub(User user, Plan plan,
                                 SubscriptionSource source, SubscriptionStatus status) {
        UserSubscription s = testData.userSubscription(user, plan);
        s.setSource(source);
        s.setStatus(status);
        return repository.save(s);
    }

    private Plan plan(ModuleAccess access) {
        Plan p = testData.plan();
        p.setModuleAccess(access);
        return planManager.save(p);
    }

    private User user(String email, String firstName, String lastName) {
        User u = testData.user(email);
        u.setFirstName(firstName);
        u.setLastName(lastName);
        return userManager.save(u);
    }

    @Test
    void hasSourceFiltersBySourceAndNullMatchesAll() {
        User u = testData.user();
        Plan plan = testData.plan();
        UserSubscription apple = sub(u, plan, SubscriptionSource.APPLE, SubscriptionStatus.ACTIVE);
        UserSubscription stripe = sub(u, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);

        assertThat(repository.findAll(UserSubscriptionSpecifications.hasSource(SubscriptionSource.APPLE)))
                .extracting(UserSubscription::getId)
                .contains(apple.getId())
                .doesNotContain(stripe.getId());
        assertThat(repository.findAll(UserSubscriptionSpecifications.hasSource(null)))
                .extracting(UserSubscription::getId).contains(apple.getId(), stripe.getId());
    }

    @Test
    void hasStatusFiltersByStatusAndNullMatchesAll() {
        User u = testData.user();
        Plan plan = testData.plan();
        UserSubscription active = sub(u, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);
        UserSubscription canceled = sub(u, plan, SubscriptionSource.STRIPE, SubscriptionStatus.CANCELED);

        assertThat(repository.findAll(UserSubscriptionSpecifications.hasStatus(SubscriptionStatus.CANCELED)))
                .extracting(UserSubscription::getId)
                .contains(canceled.getId())
                .doesNotContain(active.getId());
        assertThat(repository.findAll(UserSubscriptionSpecifications.hasStatus(null)))
                .extracting(UserSubscription::getId).contains(active.getId(), canceled.getId());
    }

    @Test
    void hasModuleAccessJoinsPlanAndFiltersAndNullMatchesAll() {
        User u = testData.user();
        Plan civiquePlan = plan(ModuleAccess.CIVIQUE);
        Plan integralPlan = plan(ModuleAccess.INTEGRAL);
        UserSubscription civique = sub(u, civiquePlan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);
        UserSubscription integral = sub(u, integralPlan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);

        assertThat(repository.findAll(UserSubscriptionSpecifications.hasModuleAccess(ModuleAccess.CIVIQUE)))
                .extracting(UserSubscription::getId)
                .contains(civique.getId())
                .doesNotContain(integral.getId());
        assertThat(repository.findAll(UserSubscriptionSpecifications.hasModuleAccess(null)))
                .extracting(UserSubscription::getId).contains(civique.getId(), integral.getId());
    }

    @Test
    void userSearchMatchesEmailFirstNameOrLastNameCaseInsensitive() {
        Plan plan = testData.plan();
        User byEmail = user("ZorglubFind@test.sejourfr", "Jean", "Martin");
        User byFirst = testData.user();
        User firstHolder = user("a" + System.nanoTime() + "@test.sejourfr", "Bernadette", "Durand");
        User lastHolder = user("b" + System.nanoTime() + "@test.sejourfr", "Paul", "Wozniak");

        UserSubscription emailMatch = sub(byEmail, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);
        UserSubscription firstMatch = sub(firstHolder, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);
        UserSubscription lastMatch = sub(lastHolder, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);
        UserSubscription noise = sub(byFirst, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);

        // email (case-insensitive)
        assertThat(repository.findAll(UserSubscriptionSpecifications.userSearch("zorglubfind")))
                .extracting(UserSubscription::getId)
                .contains(emailMatch.getId())
                .doesNotContain(firstMatch.getId(), lastMatch.getId(), noise.getId());
        // firstName
        assertThat(repository.findAll(UserSubscriptionSpecifications.userSearch("BERNADETTE")))
                .extracting(UserSubscription::getId)
                .contains(firstMatch.getId())
                .doesNotContain(emailMatch.getId(), lastMatch.getId(), noise.getId());
        // lastName
        assertThat(repository.findAll(UserSubscriptionSpecifications.userSearch("wozniak")))
                .extracting(UserSubscription::getId)
                .contains(lastMatch.getId())
                .doesNotContain(emailMatch.getId(), firstMatch.getId(), noise.getId());
    }

    @Test
    void userSearchNullOrBlankAddsNoPredicate() {
        Plan plan = testData.plan();
        User u = user("c" + System.nanoTime() + "@test.sejourfr", "Alice", "Bob");
        UserSubscription s = sub(u, plan, SubscriptionSource.STRIPE, SubscriptionStatus.ACTIVE);

        assertThat(repository.findAll(UserSubscriptionSpecifications.userSearch(null)))
                .extracting(UserSubscription::getId).contains(s.getId());
        assertThat(repository.findAll(UserSubscriptionSpecifications.userSearch("   ")))
                .extracting(UserSubscription::getId).contains(s.getId());
    }

    @Test
    void whereAndChainCombinesAllFiltersLikeService() {
        Plan integralPlan = plan(ModuleAccess.INTEGRAL);
        Plan civiquePlan = plan(ModuleAccess.CIVIQUE);
        String marker = "needlename" + System.nanoTime();

        User target = user("t" + System.nanoTime() + "@test.sejourfr", marker, "Hit");
        User otherName = user("o" + System.nanoTime() + "@test.sejourfr", "Autre", "Nom");

        UserSubscription hit = sub(target, integralPlan, SubscriptionSource.APPLE, SubscriptionStatus.ACTIVE);
        UserSubscription wrongSource = sub(target, integralPlan, SubscriptionSource.GOOGLE, SubscriptionStatus.ACTIVE);
        UserSubscription wrongStatus = sub(target, integralPlan, SubscriptionSource.APPLE, SubscriptionStatus.CANCELED);
        UserSubscription wrongModule = sub(target, civiquePlan, SubscriptionSource.APPLE, SubscriptionStatus.ACTIVE);
        UserSubscription wrongName = sub(otherName, integralPlan, SubscriptionSource.APPLE, SubscriptionStatus.ACTIVE);

        Specification<UserSubscription> spec = Specification
                .where(UserSubscriptionSpecifications.hasSource(SubscriptionSource.APPLE))
                .and(UserSubscriptionSpecifications.hasStatus(SubscriptionStatus.ACTIVE))
                .and(UserSubscriptionSpecifications.hasModuleAccess(ModuleAccess.INTEGRAL))
                .and(UserSubscriptionSpecifications.userSearch(marker));

        assertThat(repository.findAll(spec))
                .extracting(UserSubscription::getId)
                .containsExactly(hit.getId())
                .doesNotContain(wrongSource.getId(), wrongStatus.getId(),
                        wrongModule.getId(), wrongName.getId());
    }
}
