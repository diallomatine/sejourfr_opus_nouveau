package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class UserSubscriptionMapperTest {

    private final UserSubscriptionMapper mapper = new UserSubscriptionMapper();

    private User user(UUID id) {
        User u = new User();
        u.setId(id);
        u.setEmail("karim@example.fr");
        u.setFirstName("Karim");
        u.setLastName("Test");
        return u;
    }

    @Test
    void toAdminDto_withPlan_mapsEveryField() {
        UUID subId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID planId = UUID.randomUUID();
        Instant starts = Instant.parse("2026-01-01T00:00:00Z");
        Instant ends = Instant.parse("2026-04-01T00:00:00Z");
        Instant updated = Instant.parse("2026-01-15T00:00:00Z");

        Plan plan = new Plan();
        plan.setId(planId);
        plan.setCode("CIVIQUE_QUARTERLY");
        plan.setName("Civique trimestriel");
        plan.setModuleAccess(ModuleAccess.CIVIQUE);
        plan.setPrice(new BigDecimal("9.99"));

        UserSubscription sub = new UserSubscription();
        sub.setId(subId);
        sub.setUser(user(userId));
        sub.setPlan(plan);
        sub.setSource(SubscriptionSource.STRIPE);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setExternalTransactionId("sub_ext_1");
        sub.setOriginalTransactionId("sub_orig_1");
        sub.setProductId("civique_quarterly");
        sub.setAutoRenew(true);
        sub.setStartsAt(starts);
        sub.setEndsAt(ends);
        sub.setUpdatedAt(updated);

        AdminSubscriptionDto dto = mapper.toAdminDto(sub);

        assertThat(dto.id()).isEqualTo(subId);
        assertThat(dto.userId()).isEqualTo(userId);
        assertThat(dto.userEmail()).isEqualTo("karim@example.fr");
        assertThat(dto.userFirstName()).isEqualTo("Karim");
        assertThat(dto.userLastName()).isEqualTo("Test");
        assertThat(dto.source()).isEqualTo(SubscriptionSource.STRIPE);
        assertThat(dto.status()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(dto.externalTransactionId()).isEqualTo("sub_ext_1");
        assertThat(dto.originalTransactionId()).isEqualTo("sub_orig_1");
        assertThat(dto.productId()).isEqualTo("civique_quarterly");
        assertThat(dto.autoRenew()).isTrue();
        assertThat(dto.startsAt()).isEqualTo(starts);
        assertThat(dto.endsAt()).isEqualTo(ends);
        assertThat(dto.updatedAt()).isEqualTo(updated);
        assertThat(dto.planId()).isEqualTo(planId);
        assertThat(dto.planCode()).isEqualTo("CIVIQUE_QUARTERLY");
        assertThat(dto.planName()).isEqualTo("Civique trimestriel");
        assertThat(dto.moduleAccess()).isEqualTo(ModuleAccess.CIVIQUE);
        assertThat(dto.planPrice()).isEqualByComparingTo("9.99");
    }

    @Test
    void toAdminDto_nullPlan_yieldNullPlanFields() {
        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setUser(user(UUID.randomUUID()));
        sub.setPlan(null);
        sub.setSource(SubscriptionSource.APPLE);
        sub.setStatus(SubscriptionStatus.EXPIRED);
        sub.setOriginalTransactionId("orig");
        sub.setAutoRenew(false);
        sub.setStartsAt(Instant.parse("2026-01-01T00:00:00Z"));
        sub.setUpdatedAt(Instant.parse("2026-01-01T00:00:00Z"));

        AdminSubscriptionDto dto = mapper.toAdminDto(sub);

        assertThat(dto.planId()).isNull();
        assertThat(dto.planCode()).isNull();
        assertThat(dto.planName()).isNull();
        assertThat(dto.moduleAccess()).isNull();
        assertThat(dto.planPrice()).isNull();
        assertThat(dto.endsAt()).isNull();
        assertThat(dto.autoRenew()).isFalse();
        assertThat(dto.source()).isEqualTo(SubscriptionSource.APPLE);
    }
}
