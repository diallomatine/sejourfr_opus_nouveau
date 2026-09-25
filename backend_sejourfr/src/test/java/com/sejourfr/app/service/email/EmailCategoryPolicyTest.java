package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.UserEmailPreference;
import com.sejourfr.app.enums.EmailCategory;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class EmailCategoryPolicyTest {

    private static Optional<UserEmailPreference> pref(boolean engagement, boolean marketing) {
        UserEmailPreference p = new UserEmailPreference();
        p.setEngagementEnabled(engagement);
        p.setMarketingEnabled(marketing);
        return Optional.of(p);
    }

    @Test
    void requiredToujoursAutorise() {
        assertThat(EmailCategoryPolicy.allows(EmailCategory.REQUIRED, pref(false, false))).isTrue();
        assertThat(EmailCategoryPolicy.allows(EmailCategory.REQUIRED, Optional.empty())).isTrue();
    }

    @Test
    void engagementActifParDefautEtDesactivable() {
        assertThat(EmailCategoryPolicy.allows(EmailCategory.ENGAGEMENT, Optional.empty())).isTrue();
        assertThat(EmailCategoryPolicy.allows(EmailCategory.ENGAGEMENT, pref(false, false))).isFalse();
    }

    @Test
    void marketingBloqueParDefautOptInSeulement() {
        assertThat(EmailCategoryPolicy.allows(EmailCategory.MARKETING, Optional.empty())).isFalse();
        assertThat(EmailCategoryPolicy.allows(EmailCategory.MARKETING, pref(true, false))).isFalse();
        assertThat(EmailCategoryPolicy.allows(EmailCategory.MARKETING, pref(true, true))).isTrue();
    }
}
