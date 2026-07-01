package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.service.SubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Quota temps reel : le cap vient du pass ({@code plans.realtime_eo_sessions}) et
 * la consommation est derivee du comptage des sessions consommees + PENDING
 * recentes (fenetre de reservation). Aucun acces reseau/DB reel.
 */
@ExtendWith(MockitoExtension.class)
class RealtimeQuotaServiceTest {

    @Mock private SubscriptionService subscriptionService;
    @Mock private RealtimeSessionManager sessionManager;

    private final RealtimeProperties props = new RealtimeProperties();

    private RealtimeQuotaService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new RealtimeQuotaService(subscriptionService, sessionManager, props);
    }

    private UserSubscription subscriptionWithCap(int cap) {
        Plan plan = new Plan();
        plan.setRealtimeEoSessions(cap);
        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setPlan(plan);
        return sub;
    }

    @Test
    void evaluate_sans_pass_eligible_renvoie_quota_vide() {
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.empty());

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.subscription()).isNull();
        assertThat(quota.cap()).isZero();
        assertThat(quota.remaining()).isZero();
        assertThat(quota.canStartRealtime()).isFalse();
    }

    @Test
    void evaluate_pass_sans_acces_tcf_cap_zero() {
        UserSubscription sub = subscriptionWithCap(0);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.subscription()).isSameAs(sub);
        assertThat(quota.cap()).isZero();
        assertThat(quota.remaining()).isZero();
        assertThat(quota.canStartRealtime()).isFalse();
    }

    @Test
    void evaluate_calcule_le_restant_consomme_plus_pending() {
        UserSubscription sub = subscriptionWithCap(5);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));
        when(sessionManager.countConsumed(sub.getId())).thenReturn(2L);
        when(sessionManager.countRecentPending(eq(sub.getId()), any(Instant.class))).thenReturn(1L);

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.cap()).isEqualTo(5);
        assertThat(quota.remaining()).isEqualTo(2); // 5 - (2 + 1)
        assertThat(quota.canStartRealtime()).isTrue();
    }

    @Test
    void evaluate_restant_jamais_negatif() {
        UserSubscription sub = subscriptionWithCap(2);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));
        when(sessionManager.countConsumed(sub.getId())).thenReturn(3L);
        when(sessionManager.countRecentPending(eq(sub.getId()), any(Instant.class))).thenReturn(1L);

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.remaining()).isZero();
        assertThat(quota.canStartRealtime()).isFalse();
    }

    @Test
    void remaining_delegue_a_evaluate() {
        UserSubscription sub = subscriptionWithCap(4);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));
        lenient().when(sessionManager.countConsumed(sub.getId())).thenReturn(1L);
        lenient().when(sessionManager.countRecentPending(eq(sub.getId()), any(Instant.class))).thenReturn(0L);

        assertThat(service.remaining(userId)).isEqualTo(3);
    }
}
