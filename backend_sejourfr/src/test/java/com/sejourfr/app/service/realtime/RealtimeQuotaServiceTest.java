package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.service.SubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Quota temps reel : le solde restant est LU sur la souscription couvrante
 * ({@code user_subscriptions.realtime_eo_sessions_remaining}) ; le cap
 * ({@code plans.realtime_eo_sessions}) n'est qu'informatif (affichage). Aucun
 * comptage de sessions, aucun acces reseau/DB reel.
 */
@ExtendWith(MockitoExtension.class)
class RealtimeQuotaServiceTest {

    @Mock private SubscriptionService subscriptionService;

    private RealtimeQuotaService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new RealtimeQuotaService(subscriptionService);
    }

    private UserSubscription subscription(int planCap, int remaining) {
        Plan plan = new Plan();
        plan.setRealtimeEoSessions(planCap);
        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setPlan(plan);
        sub.setRealtimeEoSessionsRemaining(remaining);
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
    void evaluate_pass_sans_acces_tcf_solde_zero() {
        UserSubscription sub = subscription(0, 0);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.subscription()).isSameAs(sub);
        assertThat(quota.cap()).isZero();
        assertThat(quota.remaining()).isZero();
        assertThat(quota.canStartRealtime()).isFalse();
    }

    @Test
    void evaluate_lit_le_solde_stocke_sur_la_souscription() {
        UserSubscription sub = subscription(5, 3);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.cap()).isEqualTo(5);       // informatif (allocation du pass)
        assertThat(quota.remaining()).isEqualTo(3); // solde stocké
        assertThat(quota.canStartRealtime()).isTrue();
    }

    @Test
    void evaluate_solde_epuise_bloque() {
        UserSubscription sub = subscription(5, 0);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        RealtimeQuotaService.Quota quota = service.evaluate(userId);

        assertThat(quota.remaining()).isZero();
        assertThat(quota.canStartRealtime()).isFalse();
    }

    @Test
    void evaluate_solde_negatif_clamp_a_zero() {
        UserSubscription sub = subscription(5, -2);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        assertThat(service.evaluate(userId).remaining()).isZero();
    }

    @Test
    void remaining_delegue_a_evaluate() {
        UserSubscription sub = subscription(4, 3);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(sub));

        assertThat(service.remaining(userId)).isEqualTo(3);
    }
}
