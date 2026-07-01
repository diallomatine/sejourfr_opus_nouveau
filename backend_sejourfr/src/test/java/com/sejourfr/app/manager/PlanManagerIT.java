package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) du {@link PlanManager} : lookups par
 * code et par SKU store (Apple / Google / Stripe), CRUD de base.
 */
class PlanManagerIT extends AbstractIntegrationTest {

    @Autowired
    private PlanManager planManager;

    @Autowired
    private TestData testData;

    @Test
    void saveAssignsIdAndPersists() {
        Plan p = new Plan();
        p.setCode("PLAN_SAVE_" + UUID.randomUUID());
        p.setName("Plan créé en test");
        p.setBillingCycle(BillingCycle.MONTHLY);
        p.setPrice(new BigDecimal("12.50"));
        p.setModuleAccess(ModuleAccess.CIVIQUE);

        Plan saved = planManager.save(p);

        assertThat(saved.getId()).isNotNull();
        assertThat(planManager.findByCode(p.getCode())).isPresent();
    }

    @Test
    void findAllContainsSeededPlans() {
        Plan a = testData.plan();
        Plan b = testData.plan();

        List<Plan> all = planManager.findAll();

        assertThat(all).extracting(Plan::getId).contains(a.getId(), b.getId());
    }

    @Test
    void findByIdReturnsMatchAndEmptyWhenAbsent() {
        Plan p = testData.plan();

        assertThat(planManager.findById(p.getId())).isPresent();
        assertThat(planManager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByCodeSelectsExactMatch() {
        Plan p = testData.plan();

        Optional<Plan> found = planManager.findByCode(p.getCode());
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(p.getId());
        assertThat(planManager.findByCode("CODE_ABSENT_" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByAppleProductIdSelectsMatchingPlan() {
        String sku = "apple.sku." + UUID.randomUUID();
        Plan tagged = testData.plan();
        tagged.setAppleProductId(sku);
        planManager.save(tagged);
        testData.plan(); // autre plan sans SKU Apple

        Optional<Plan> found = planManager.findByAppleProductId(sku);
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(tagged.getId());
        assertThat(planManager.findByAppleProductId("apple.absent." + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByGoogleProductIdSelectsMatchingPlan() {
        String sku = "google.sku." + UUID.randomUUID();
        Plan tagged = testData.plan();
        tagged.setGoogleProductId(sku);
        planManager.save(tagged);
        testData.plan();

        Optional<Plan> found = planManager.findByGoogleProductId(sku);
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(tagged.getId());
        assertThat(planManager.findByGoogleProductId("google.absent." + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findByStripePriceIdSelectsMatchingPlan() {
        String priceId = "price_" + UUID.randomUUID();
        Plan tagged = testData.plan();
        tagged.setStripePriceId(priceId);
        planManager.save(tagged);
        testData.plan();

        Optional<Plan> found = planManager.findByStripePriceId(priceId);
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(tagged.getId());
        assertThat(planManager.findByStripePriceId("price_absent_" + UUID.randomUUID())).isEmpty();
    }
}
