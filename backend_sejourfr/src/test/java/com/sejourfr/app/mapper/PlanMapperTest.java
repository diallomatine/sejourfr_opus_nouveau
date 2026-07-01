package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminPlanDto;
import com.sejourfr.app.dto.PlanPublicResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PlanMapperTest {

    private final PlanMapper mapper = new PlanMapper();

    private Plan plan(UUID id) {
        Plan p = new Plan();
        p.setId(id);
        p.setCode("INTEGRAL_YEARLY");
        p.setName("Intégral annuel");
        p.setBillingCycle(BillingCycle.YEARLY);
        p.setPrice(new BigDecimal("79.99"));
        p.setOriginalPrice(new BigDecimal("99.99"));
        p.setModuleAccess(ModuleAccess.INTEGRAL);
        p.setDurationDays(365);
        p.setPurchaseType(PlanPurchaseType.ONE_TIME);
        p.setActive(true);
        p.setStripePriceId("price_abc");
        p.setAppleProductId("apple.integral.yearly");
        p.setGoogleProductId("google.integral.yearly");
        return p;
    }

    @Test
    void toPublicResponse_mapsEveryField() {
        PlanPublicResponse dto = mapper.toPublicResponse(plan(UUID.randomUUID()));

        assertThat(dto.code()).isEqualTo("INTEGRAL_YEARLY");
        assertThat(dto.name()).isEqualTo("Intégral annuel");
        assertThat(dto.billingCycle()).isEqualTo(BillingCycle.YEARLY);
        assertThat(dto.price()).isEqualByComparingTo("79.99");
        assertThat(dto.originalPrice()).isEqualByComparingTo("99.99");
        assertThat(dto.moduleAccess()).isEqualTo(ModuleAccess.INTEGRAL);
        assertThat(dto.durationDays()).isEqualTo(365);
        assertThat(dto.purchaseType()).isEqualTo(PlanPurchaseType.ONE_TIME);
        assertThat(dto.appleProductId()).isEqualTo("apple.integral.yearly");
        assertThat(dto.googleProductId()).isEqualTo("google.integral.yearly");
    }

    @Test
    void toAdminDto_mapsEveryFieldIncludingInternalIdAndFlags() {
        UUID id = UUID.randomUUID();

        AdminPlanDto dto = mapper.toAdminDto(plan(id));

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.code()).isEqualTo("INTEGRAL_YEARLY");
        assertThat(dto.name()).isEqualTo("Intégral annuel");
        assertThat(dto.billingCycle()).isEqualTo(BillingCycle.YEARLY);
        assertThat(dto.price()).isEqualByComparingTo("79.99");
        assertThat(dto.originalPrice()).isEqualByComparingTo("99.99");
        assertThat(dto.moduleAccess()).isEqualTo(ModuleAccess.INTEGRAL);
        assertThat(dto.durationDays()).isEqualTo(365);
        assertThat(dto.purchaseType()).isEqualTo(PlanPurchaseType.ONE_TIME);
        assertThat(dto.active()).isTrue();
        assertThat(dto.stripePriceId()).isEqualTo("price_abc");
        assertThat(dto.appleProductId()).isEqualTo("apple.integral.yearly");
        assertThat(dto.googleProductId()).isEqualTo("google.integral.yearly");
    }

    @Test
    void toAdminDto_nullableStoreIdsAndOriginalPrice() {
        Plan p = new Plan();
        p.setId(UUID.randomUUID());
        p.setCode("FREE");
        p.setName("Gratuit");
        p.setBillingCycle(BillingCycle.NONE);
        p.setPrice(new BigDecimal("0.00"));
        p.setModuleAccess(ModuleAccess.NONE);
        p.setActive(false);

        AdminPlanDto dto = mapper.toAdminDto(p);

        assertThat(dto.originalPrice()).isNull();
        assertThat(dto.stripePriceId()).isNull();
        assertThat(dto.appleProductId()).isNull();
        assertThat(dto.googleProductId()).isNull();
        assertThat(dto.active()).isFalse();
        assertThat(dto.purchaseType()).isEqualTo(PlanPurchaseType.SUBSCRIPTION);
    }
}
