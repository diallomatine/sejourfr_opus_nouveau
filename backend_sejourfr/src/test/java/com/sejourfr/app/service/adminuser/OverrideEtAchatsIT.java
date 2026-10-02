package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.dto.AdminUserDetailDto;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.billing.OneTimeAccessService;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.DateMetierParis;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Décisions admin × flux d'achat (spec §2.3, §11 cas 6, 7, 11 ; GO §8 G-5 ; GO §7).
 * Le flux d'achat ({@link OneTimeAccessService}, commun Stripe / Apple / Google)
 * n'écrit JAMAIS une décision ; il les LIT seulement pour la base de prolongation.
 */
class OverrideEtAchatsIT extends AbstractIntegrationTest {

    private static final Duration JOUR = Duration.ofDays(1);

    @Autowired private TestData data;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private OneTimeAccessService oneTime;
    @Autowired private SubscriptionService subscriptions;
    @Autowired private RealtimeQuotaService quota;
    @Autowired private AdminUserService adminUserService;
    @Autowired private UserSubscriptionManager subscriptionManager;
    @Autowired private PlanManager planManager;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private List<Map<String, Object>> decisions(UUID userId) {
        return jdbc.queryForList("SELECT * FROM access_overrides WHERE user_id = ? ORDER BY id", userId);
    }

    private ProductAccessStatus statut(User u, ModuleAccess p) {
        AdminUserDetailDto d = adminUserService.detail(u.getId());
        return d.accesses().stream().filter(a -> a.product() == p).findFirst().orElseThrow().status();
    }

    @Test
    @DisplayName("Cas 6 — Stripe, Apple, Google rejoués : la décision reste en place, l'accès effectif ne change pas")
    void cas6WebhooksRejoues() {
        User admin = data.admin();
        User u = data.user();
        Plan integral = fx.pass(ModuleAccess.INTEGRAL, 30);
        for (SubscriptionSource src : SubscriptionSource.values()) {
            oneTime.grantOneTimeAccess(u.getId(), integral, src, "tx-" + src + "-" + u.getId(), "ext-" + src);
        }
        fx.agir(u, admin, AdminAccessOperationType.SHORTEN, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(5));
        em.flush();
        List<Map<String, Object>> avant = decisions(u.getId());
        SubscriptionService.CurrentAccess accesAvant = subscriptions.currentAccess(u.getId());

        for (SubscriptionSource src : SubscriptionSource.values()) {
            oneTime.grantOneTimeAccess(u.getId(), integral, src, "tx-" + src + "-" + u.getId(), "ext-" + src);
        }
        em.flush();

        assertThat(decisions(u.getId())).isEqualTo(avant);
        assertThat(subscriptions.currentAccess(u.getId())).isEqualTo(accesAvant);
        assertThat(accesAvant.endsAt()).isEqualTo(DateMetierParis.finExclusive(AccesAdminFixtures.jour(5)));
    }

    @Test
    @DisplayName("Cas 7 + G-5 — Civique révoqué puis racheté : actif, et le pass repart de MAINTENANT (pas de l'achat révoqué)")
    void cas7RachatApresRevoke() {
        User admin = data.admin();
        User u = data.user();
        fx.achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR.multipliedBy(10)), Instant.now().plus(JOUR.multipliedBy(80)));
        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.CIVIQUE, null, null, null);
        em.flush();
        assertThat(subscriptions.hasCivique(u.getId())).isFalse();

        Plan civique = fx.pass(ModuleAccess.CIVIQUE, 90);
        UserSubscription rachat = oneTime.grantOneTimeAccess(u.getId(), civique, SubscriptionSource.STRIPE,
                "cs_rachat_" + u.getId(), "pi_rachat");
        em.flush();

        assertThat(subscriptions.hasCivique(u.getId())).isTrue();
        assertThat(statut(u, ModuleAccess.CIVIQUE)).isEqualTo(ProductAccessStatus.ACTIVE);
        assertThat(rachat.getEndsAt()).isCloseTo(Instant.now().plus(90, ChronoUnit.DAYS), within(1, ChronoUnit.MINUTES));
    }

    @Test
    @DisplayName("G-5 — achat pendant un GRANT : prolonge depuis la fin effective du GRANT, durée achetée intégralement")
    void g5AchatPendantUnGrant() {
        User admin = data.admin();
        User u = data.user();
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(20));
        em.flush();
        Instant finGrant = DateMetierParis.finExclusive(AccesAdminFixtures.jour(20));

        Plan integral = fx.pass(ModuleAccess.INTEGRAL, 30);
        UserSubscription achat = oneTime.grantOneTimeAccess(u.getId(), integral, SubscriptionSource.APPLE,
                "apple_" + u.getId(), "apple_ext");

        assertThat(achat.getStartsAt()).isCloseTo(Instant.now(), within(1, ChronoUnit.MINUTES));
        assertThat(achat.getEndsAt()).isEqualTo(finGrant.plus(30, ChronoUnit.DAYS));
        assertThat(decisions(u.getId())).hasSize(1);
    }

    @Test
    @DisplayName("Cas 11 — GRANT en cours, achat remboursé (webhook) : GRANT conservé, alerte « Achat remboursé »")
    void cas11RemboursementSousGrant() {
        User admin = data.admin();
        User u = data.user();
        UserSubscription a = fx.achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(10)));
        fx.agir(u, admin, AdminAccessOperationType.EXTEND, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(30));
        em.flush();

        // Ce qu'écrit un webhook de remboursement total, sur SA ligne seulement.
        a.setStatus(SubscriptionStatus.REFUNDED);
        a.setPaymentStatus(PaymentStatus.REFUNDED);
        subscriptionManager.save(a);
        em.flush();

        assertThat(subscriptions.hasTcf(u.getId())).isTrue();
        var integral = adminUserService.detail(u.getId()).accesses().stream()
                .filter(x -> x.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow();
        assertThat(integral.status()).isEqualTo(ProductAccessStatus.ACTIVE);
        assertThat(integral.alerts()).extracting(x -> x.label()).contains("Achat remboursé");
    }

    @Test
    @DisplayName("Quota EO temps réel — Intégral acheté puis révoqué : plus aucune session consommable")
    void quotaApresRevoke() {
        User admin = data.admin();
        User u = data.user();
        UserSubscription a = fx.achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(20)));
        a.getPlan().setRealtimeEoSessions(15);
        planManager.save(a.getPlan());
        a.setRealtimeEoSessionsRemaining(12);
        subscriptionManager.save(a);
        em.flush();
        assertThat(quota.evaluate(u.getId()).canStartRealtime()).isTrue();

        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.INTEGRAL, null, null, null);
        em.flush();

        assertThat(quota.evaluate(u.getId()).canStartRealtime()).isFalse();
        assertThat(quota.evaluate(u.getId()).achat()).isEmpty();
    }

    @Test
    @DisplayName("Quota EO temps réel — GRANT Intégral prolongeant un achat Intégral couvrant : le solde de l'achat reste utilisable")
    void quotaGrantSurAchatIntegral() {
        User admin = data.admin();
        User u = data.user();
        UserSubscription a = fx.achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(5)));
        a.getPlan().setRealtimeEoSessions(15);
        planManager.save(a.getPlan());
        a.setRealtimeEoSessionsRemaining(4);
        subscriptionManager.save(a);
        fx.agir(u, admin, AdminAccessOperationType.EXTEND, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(30));
        em.flush();

        RealtimeQuotaService.Quota q = quota.evaluate(u.getId());
        assertThat(q.remaining()).isEqualTo(4);
        assertThat(q.achat().orElseThrow().getId()).isEqualTo(a.getId());
    }

    @Test
    @DisplayName("V084 — rachat pendant un GRANT Intégral à sessions : le report ne prend QUE le solde de l'achat, le GRANT est intact")
    void rachatPendantGrantNeReporteQueLAchat() {
        User admin = data.admin();
        User u = data.user();
        fx.achatIntegral(u, SubscriptionSource.STRIPE, "pi_" + UUID.randomUUID(), 15, 3);
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null,
                AccesAdminFixtures.jour(60), 5);
        em.flush();
        List<Map<String, Object>> decisionsAvant = decisions(u.getId());

        Plan integral = fx.pass(ModuleAccess.INTEGRAL, 30);
        integral.setRealtimeEoSessions(15);
        planManager.save(integral);
        UserSubscription rachat = oneTime.grantOneTimeAccess(u.getId(), integral, SubscriptionSource.STRIPE,
                "pi_rachat_" + u.getId(), "pi_rachat");
        em.flush();
        em.clear();

        assertThat(rachat.getRealtimeEoSessionsRemaining()).isEqualTo(3 + 15);
        assertThat(decisions(u.getId())).isEqualTo(decisionsAvant);
        RealtimeQuotaService.Quota q = quota.evaluate(u.getId());
        assertThat(q.grantRemaining()).isEqualTo(5);
        assertThat(q.achat().orElseThrow().getId()).isEqualTo(rachat.getId());
        assertThat(q.remaining()).isEqualTo(5 + 18);
    }
}
