package com.sejourfr.app.service.realtime;

import com.sejourfr.app.dto.AdminRealtimeEoSessionsDto;
import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.service.adminuser.AdminUserService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Débit des sessions EO temps réel d'un GRANT INTEGRAL admin (V084), contre la
 * vraie base et dans de VRAIES transactions ({@code NOT_SUPPORTED}) : il faut
 * des commits pour exercer le verrou consultatif par compte, que partagent le
 * débit et les actions admin.
 * <ul>
 *   <li>idempotence : un rejeu de tour ne débite pas deux fois ;</li>
 *   <li>traçabilité : la session pointe la ligne débitée, qui mène au journal ;</li>
 *   <li>concurrence : deux connexions sur un solde de 1, un seul débit ; un
 *       débit pendant un Prolonger n'est ni perdu ni ressuscité ;</li>
 *   <li>{@code accessVersion} n'est pas touchée par un débit (aucun faux 409) ;</li>
 *   <li>Prolonger de bout en bout : 4 → 4 ; la fin d'un GRANT ne touche jamais l'achat.</li>
 * </ul>
 * Les comptes créés sont supprimés après chaque test (cascade), puis leurs plans.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class RealtimeGrantQuotaIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private RealtimeQuotaService quota;
    @Autowired private RealtimeSessionService sessions;
    @Autowired private AdminUserService adminUserService;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private PlatformTransactionManager transactionManager;

    private final List<UUID> comptes = new ArrayList<>();
    private User admin;

    @BeforeEach
    void setUp() {
        admin = data.admin();
    }

    @AfterEach
    void nettoyer() {
        List<UUID> plans = new ArrayList<>();
        for (UUID id : comptes) {
            plans.addAll(jdbc.queryForList("SELECT plan_id FROM user_subscriptions WHERE user_id = ?", UUID.class, id));
            jdbc.update("DELETE FROM users WHERE id = ?", id);
        }
        jdbc.update("DELETE FROM users WHERE id = ?", admin.getId());
        plans.forEach(id -> jdbc.update("DELETE FROM plans WHERE id = ?", id));
        comptes.clear();
    }

    private User compte() {
        User u = data.user();
        comptes.add(u.getId());
        return u;
    }

    private User avecGrant(int sessionsOffertes) {
        User u = compte();
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null,
                AccesAdminFixtures.jour(30), sessionsOffertes);
        return u;
    }

    private RealtimeSession reserver(User u) {
        return fx.sessionReservee(u, quota.evaluate(u.getId()));
    }

    private void parler(User u, RealtimeSession s, int tour) {
        sessions.appendTranscript(u, s.getId(), new AppendTranscriptRequest("CANDIDATE", "Bonjour " + tour, tour, null));
    }

    private UUID porteur(RealtimeSession s) {
        return jdbc.queryForObject("SELECT access_override_id FROM realtime_sessions WHERE id = ?", UUID.class, s.getId());
    }

    private String version(User u) {
        return adminUserService.detail(u.getId()).accessVersion();
    }

    @Test
    @DisplayName("Débit idempotent et traçable : rejeu du tour sans second débit, la session mène au journal de l'action")
    void debitIdempotentEtTrace() {
        User u = avecGrant(3);
        String versionAvant = version(u);
        RealtimeSession s = reserver(u);

        parler(u, s, 0);
        parler(u, s, 0);
        parler(u, s, 1);

        assertThat(fx.soldeGrantCourant(u.getId())).isEqualTo(2);
        Map<String, Object> trace = jdbc.queryForMap("""
                SELECT o.operation, o.reason, o.admin_user_id, d.realtime_eo_sessions_granted AS offertes
                  FROM realtime_sessions s
                  JOIN access_overrides d ON d.id = s.access_override_id
                  JOIN admin_access_operations o ON o.id = d.operation_id
                 WHERE s.id = ?""", s.getId());
        assertThat(trace.get("operation")).isEqualTo("GRANT");
        assertThat(trace.get("reason")).isEqualTo(AccesAdminFixtures.MOTIF);
        assertThat(trace.get("admin_user_id")).isEqualTo(admin.getId());
        assertThat(trace.get("offertes")).isEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT subscription_id FROM realtime_sessions WHERE id = ?",
                UUID.class, s.getId())).isNull();
        // Le débit ne change pas l'empreinte d'accès : la modale ouverte n'aura pas de faux 409.
        assertThat(version(u)).isEqualTo(versionAvant);
        assertThat(quota.remaining(u.getId())).isEqualTo(2);
    }

    @Test
    @DisplayName("Concurrence : deux connexions sur un solde de 1 — un seul débit, l'autre session sans porteur")
    void deuxConnexionsConcurrentesUnSeulDebit() throws Exception {
        User u = avecGrant(1);
        RealtimeSession a = reserver(u);
        RealtimeSession b = reserver(u);
        assertThat(a.getAccessOverrideId()).isNotNull().isEqualTo(b.getAccessOverrideId());

        CountDownLatch depart = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<?> fa = pool.submit(() -> {
                depart.await();
                parler(u, a, 0);
                return null;
            });
            Future<?> fb = pool.submit(() -> {
                depart.await();
                parler(u, b, 0);
                return null;
            });
            depart.countDown();
            fa.get(30, TimeUnit.SECONDS);
            fb.get(30, TimeUnit.SECONDS);
        } finally {
            pool.shutdownNow();
        }

        assertThat(fx.soldeGrantCourant(u.getId())).isZero();
        List<UUID> porteurs = new ArrayList<>();
        porteurs.add(porteur(a));
        porteurs.add(porteur(b));
        assertThat(porteurs).filteredOn(java.util.Objects::nonNull).hasSize(1);
    }

    @Test
    @DisplayName("Concurrence : un Prolonger pendant un débit attend le verrou du compte — ni débit perdu, ni solde ressuscité")
    void debitPendantUnProlonger() throws Exception {
        User u = avecGrant(4);
        UUID grantInitial = quota.evaluate(u.getId()).grant().orElseThrow().getId();
        RealtimeSession s = reserver(u);

        CountDownLatch debite = new CountDownLatch(1);
        CountDownLatch liberer = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<?> debit = pool.submit(() -> {
                new TransactionTemplate(transactionManager).executeWithoutResult(st -> {
                    parler(u, s, 0);
                    debite.countDown();
                    try {
                        liberer.await(30, TimeUnit.SECONDS);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                });
                return null;
            });
            assertThat(debite.await(30, TimeUnit.SECONDS)).isTrue();
            Future<?> prolonger = pool.submit(() -> {
                fx.agir(u, admin, AdminAccessOperationType.EXTEND, ModuleAccess.INTEGRAL, null, null,
                        AccesAdminFixtures.jour(90));
                return null;
            });
            Thread.sleep(500);
            assertThat(prolonger.isDone()).as("le Prolonger attend le verrou pris par le débit").isFalse();
            liberer.countDown();
            debit.get(30, TimeUnit.SECONDS);
            prolonger.get(30, TimeUnit.SECONDS);
        } finally {
            liberer.countDown();
            pool.shutdownNow();
        }

        assertThat(fx.soldeGrantCourant(u.getId())).isEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT realtime_eo_sessions_remaining FROM access_overrides WHERE id = ?",
                Integer.class, grantInitial)).isZero();
        assertThat(porteur(s)).isEqualTo(grantInitial);
        assertThat(quota.remaining(u.getId())).isEqualTo(3);
    }

    @Test
    @DisplayName("Prolonger de bout en bout : 4 restantes → 4 restantes, l'ancienne ligne à 0, la fiche le dit")
    void prolongerDeBoutEnBout() {
        User u = avecGrant(4);
        UUID ancien = quota.evaluate(u.getId()).grant().orElseThrow().getId();

        fx.agir(u, admin, AdminAccessOperationType.EXTEND, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(90));

        assertThat(fx.soldeGrantCourant(u.getId())).isEqualTo(4);
        Map<String, Object> ligne = jdbc.queryForMap(
                "SELECT superseded_at, realtime_eo_sessions_remaining FROM access_overrides WHERE id = ?", ancien);
        assertThat(ligne.get("superseded_at")).isNotNull();
        assertThat(ligne.get("realtime_eo_sessions_remaining")).isEqualTo(0);
        AdminRealtimeEoSessionsDto fiche = adminUserService.detail(u.getId()).accesses().stream()
                .filter(a -> a.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow().realtimeEoSessions();
        assertThat(fiche.grantRemaining()).isEqualTo(4);
        assertThat(fiche.grantGranted()).isEqualTo(4);
        assertThat(fiche.remaining()).isEqualTo(4);
        assertThat(fiche.info()).isNull();
    }

    @Test
    @DisplayName("GRANT terminé entre la réservation et la connexion : aucun débit, porteur effacé")
    void grantTermineAvantConnexion() {
        User u = avecGrant(4);
        RealtimeSession s = reserver(u);
        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.INTEGRAL, null, null, null);

        parler(u, s, 0);

        assertThat(porteur(s)).isNull();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM access_overrides WHERE user_id = ? "
                + "AND realtime_eo_sessions_remaining > 0", Integer.class, u.getId())).isZero();
        assertThat(quota.evaluate(u.getId()).canStartRealtime()).isFalse();
    }

    @Test
    @DisplayName("La fin d'un GRANT Intégral ne modifie jamais l'achat réel (ligne identique, solde et updated_at compris)")
    void finDuGrantNeModifieJamaisLAchat() {
        User u = compte();
        UserSubscription achat = fx.achatIntegral(u, SubscriptionSource.STRIPE, "pi_" + UUID.randomUUID(), 15, 7);
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null,
                AccesAdminFixtures.jour(60), 5);
        Map<String, Object> avant = fx.ligneAchat(achat.getId());

        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.INTEGRAL, null, null, null);

        assertThat(fx.ligneAchat(achat.getId())).isEqualTo(avant);
        assertThat(fx.soldeGrantCourant(u.getId())).isZero();
    }
}
