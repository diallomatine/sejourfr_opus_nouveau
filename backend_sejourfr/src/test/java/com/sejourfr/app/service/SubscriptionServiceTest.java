package com.sejourfr.app.service;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserSubscriptionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Couvre l'agrégation Premium de {@link SubscriptionService} : la fonction
 * {@code isCovering} (statut × plan FREE × date de fin) et le départage
 * {@code currentSubscription}/{@code isBetter} (INTEGRAL &gt; CIVIQUE, puis
 * {@code endsAt} le plus tardif). Test unitaire pur : on mocke uniquement le
 * manager et on lui fait renvoyer des entités construites à la main.
 */
class SubscriptionServiceTest {

    private UserSubscriptionManager userSubscriptionManager;
    private SubscriptionService service;

    private final UUID userId = UUID.randomUUID();
    private final Instant future = Instant.now().plus(30, ChronoUnit.DAYS);
    private final Instant past = Instant.now().minus(1, ChronoUnit.DAYS);

    @BeforeEach
    void setUp() {
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        service = new SubscriptionService(userSubscriptionManager);
    }

    private static Plan plan(String code, ModuleAccess access, int durationDays) {
        Plan p = new Plan();
        p.setCode(code);
        p.setModuleAccess(access);
        p.setDurationDays(durationDays);
        return p;
    }

    private static UserSubscription sub(
            Plan plan, SubscriptionStatus status, Instant endsAt) {
        UserSubscription s = new UserSubscription();
        s.setPlan(plan);
        s.setStatus(status);
        s.setEndsAt(endsAt);
        s.setSource(SubscriptionSource.STRIPE);
        return s;
    }

    private void givenSubs(UserSubscription... subs) {
        when(userSubscriptionManager.findByUserId(userId)).thenReturn(List.of(subs));
    }

    @Test
    void isPremium_false_sansAucuneSouscription() {
        givenSubs();
        assertThat(service.isPremium(userId)).isFalse();
        assertThat(service.effectiveModuleAccess(userId)).isEqualTo(ModuleAccess.NONE);
    }

    @Test
    void isPremium_false_quandSeulPlanFreeActif() {
        // Une ligne ACTIVE rattachée au plan FREE n'ouvre jamais le Premium.
        givenSubs(sub(plan("FREE", ModuleAccess.NONE, 0), SubscriptionStatus.ACTIVE, null));
        assertThat(service.isPremium(userId)).isFalse();
    }

    @Test
    void isCovering_statutsNonCouvrants_ignores() {
        Plan civique = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90);
        givenSubs(
                sub(civique, SubscriptionStatus.EXPIRED, future),
                sub(civique, SubscriptionStatus.PENDING, future),
                sub(civique, SubscriptionStatus.REFUNDED, future));
        assertThat(service.isPremium(userId)).isFalse();
    }

    @Test
    void isCovering_canceledFutur_couvre_maisCanceledPasse_non() {
        Plan civique = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90);
        givenSubs(sub(civique, SubscriptionStatus.CANCELED, future));
        assertThat(service.hasCivique(userId)).isTrue();

        givenSubs(sub(civique, SubscriptionStatus.CANCELED, past));
        assertThat(service.hasCivique(userId)).isFalse();
    }

    @Test
    void isCovering_activeSansDateFin_couvre() {
        givenSubs(sub(plan("INTEGRAL", ModuleAccess.INTEGRAL, 90),
                SubscriptionStatus.ACTIVE, null));
        assertThat(service.isPremium(userId)).isTrue();
        assertThat(service.hasTcf(userId)).isTrue();
    }

    @Test
    void hasTcf_seulementIntegral() {
        givenSubs(sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90),
                SubscriptionStatus.ACTIVE, future));
        assertThat(service.hasCivique(userId)).isTrue();
        assertThat(service.hasTcf(userId)).isFalse();
    }

    @Test
    void effectiveModuleAccess_integralGagneSurCivique() {
        givenSubs(
                sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90), SubscriptionStatus.ACTIVE, future),
                sub(plan("INTEGRAL", ModuleAccess.INTEGRAL, 90), SubscriptionStatus.ACTIVE, future));
        assertThat(service.effectiveModuleAccess(userId)).isEqualTo(ModuleAccess.INTEGRAL);
    }

    @Test
    void currentSubscription_integralBatCivique_memeSiFinPlusProche() {
        UserSubscription civique = sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90),
                SubscriptionStatus.ACTIVE, future.plus(60, ChronoUnit.DAYS));
        UserSubscription integral = sub(plan("INTEGRAL", ModuleAccess.INTEGRAL, 90),
                SubscriptionStatus.ACTIVE, future);
        givenSubs(civique, integral);

        Optional<UserSubscription> best = service.currentSubscription(userId);
        assertThat(best).containsSame(integral);
    }

    @Test
    void currentSubscription_aModuleEgal_finLaPlusTardiveGagne() {
        UserSubscription early = sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90),
                SubscriptionStatus.ACTIVE, future);
        UserSubscription late = sub(plan("CIVIQUE_1AN", ModuleAccess.CIVIQUE, 365),
                SubscriptionStatus.ACTIVE, future.plus(100, ChronoUnit.DAYS));
        givenSubs(early, late);

        assertThat(service.currentSubscription(userId)).containsSame(late);
    }

    @Test
    void currentSubscription_finNull_batDateFinie_aModuleEgal() {
        UserSubscription finite = sub(plan("INTEGRAL_3MOIS", ModuleAccess.INTEGRAL, 90),
                SubscriptionStatus.ACTIVE, future);
        UserSubscription lifetime = sub(plan("INTEGRAL_LIFE", ModuleAccess.INTEGRAL, 0),
                SubscriptionStatus.ACTIVE, null);
        givenSubs(finite, lifetime);

        assertThat(service.currentSubscription(userId)).containsSame(lifetime);
    }

    @Test
    void currentEndForAtLeast_civique_compteCiviqueEtIntegral() {
        Instant civiqueEnd = future;
        Instant integralEnd = future.plus(40, ChronoUnit.DAYS);
        givenSubs(
                sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90), SubscriptionStatus.ACTIVE, civiqueEnd),
                sub(plan("INTEGRAL_3MOIS", ModuleAccess.INTEGRAL, 90), SubscriptionStatus.ACTIVE, integralEnd));
        // Pass CIVIQUE : prolonge depuis la fin la plus tardive d'un accès >= CIVIQUE.
        assertThat(service.currentEndForAtLeast(userId, ModuleAccess.CIVIQUE)).isEqualTo(integralEnd);
    }

    @Test
    void currentEndForAtLeast_integral_ignoreCivique() {
        givenSubs(
                sub(plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, 90), SubscriptionStatus.ACTIVE,
                        future.plus(100, ChronoUnit.DAYS)));
        // Pass INTEGRAL : aucun accès INTEGRAL existant → pas de prolongation
        // (le reste Civique est crédité via la proration Stripe, pas cumulé ici).
        assertThat(service.currentEndForAtLeast(userId, ModuleAccess.INTEGRAL)).isNull();
    }
}
