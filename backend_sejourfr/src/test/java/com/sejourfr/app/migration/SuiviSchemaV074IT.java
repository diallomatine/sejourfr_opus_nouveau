package com.sejourfr.app.migration;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Le schema V074 du chantier Suivi : les contraintes que les lots 2 et 4
 * tiennent pour acquises sont verifiees ici, contre le vrai Postgres.
 *
 * <p>Chaque violation attendue est jouee sous un {@code SAVEPOINT} : une erreur
 * Postgres avorte la transaction de test, et les assertions suivantes
 * echoueraient pour une autre raison que celle qu'elles verifient.
 */
class SuiviSchemaV074IT extends AbstractIntegrationTest {

    private static final String SENTINELLE = "-- @@INITIALISATION_IS_INTERNAL@@";

    @Autowired private JdbcTemplate jdbc;
    @Autowired private TestData testData;
    @Autowired private EntityManager em;

    private void refuse(String sql, Object... args) {
        jdbc.execute("SAVEPOINT v074");
        try {
            assertThatThrownBy(() -> jdbc.update(sql, args)).isInstanceOf(DataAccessException.class);
        } finally {
            jdbc.execute("ROLLBACK TO SAVEPOINT v074");
        }
    }

    // ------------------------------------------------------------------------
    // user_subscriptions : l'invariant du brief §6.1, tenu par la base
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("gross = vat + fee + net_ex_vat est tenu par la base, et la décomposition est tout ou rien")
    void invariantDuRevenu() {
        UserSubscription s = testData.userSubscription();
        em.flush();
        UUID id = s.getId();

        // Stripe sous franchise (arbitrage Q1) : 9,99 → vat 0, fee 0,40, net 9,59.
        jdbc.update("""
                UPDATE user_subscriptions SET amount_cents = 999, currency = 'EUR', amount_eur_cents = 999,
                    vat_cents = 0, provider_fee_cents = 40, net_after_fee_cents = 959, net_ex_vat_cents = 959,
                    fee_source = 'ESTIMATED', revenue_rules_version = 1, origin = 'UNKNOWN'
                WHERE id = ?""", id);

        refuse("UPDATE user_subscriptions SET net_ex_vat_cents = 958 WHERE id = ?", id);
        refuse("UPDATE user_subscriptions SET fee_source = NULL WHERE id = ?", id);
        refuse("UPDATE user_subscriptions SET origin = 'OTHER' WHERE id = ?", id);
        refuse("UPDATE user_subscriptions SET amount_eur_cents = NULL WHERE id = ?", id);
    }

    @Test
    @DisplayName("Une ligne antérieure reste NULL partout : null = inconnu, aucun rattrapage")
    void ligneAnterieureNulle() {
        UserSubscription s = testData.userSubscription();
        em.flush();
        Integer net = jdbc.queryForObject(
                "SELECT net_ex_vat_cents FROM user_subscriptions WHERE id = ?", Integer.class, s.getId());
        String origin = jdbc.queryForObject(
                "SELECT origin FROM user_subscriptions WHERE id = ?", String.class, s.getId());
        assertThat(net).isNull();
        assertThat(origin).isNull();
    }

    // ------------------------------------------------------------------------
    // payment_refunds
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Remboursements : partiels multiples permis, un identifiant provider une seule fois")
    void remboursements() {
        UserSubscription s = testData.userSubscription();
        em.flush();
        String insert = """
                INSERT INTO payment_refunds (id, subscription_id, provider, provider_refund_id,
                    refunded_amount_cents, currency, refunded_eur_cents, net_ex_vat_delta_cents,
                    revenue_rules_version, refunded_at)
                VALUES (?, ?, 'STRIPE', ?, ?, 'EUR', ?, ?, 1, now())""";
        jdbc.update(insert, UUID.randomUUID(), s.getId(), "re_1", 300, 300, -300);
        jdbc.update(insert, UUID.randomUUID(), s.getId(), "re_2", 200, 200, -200);

        refuse(insert, UUID.randomUUID(), s.getId(), "re_1", 100, 100, -100);
        refuse(insert, UUID.randomUUID(), s.getId(), "re_3", 100, 100, 50);
        refuse(insert, UUID.randomUUID(), s.getId(), "re_4", 0, 0, 0);

        Integer n = jdbc.queryForObject(
                "SELECT count(*) FROM payment_refunds WHERE subscription_id = ?", Integer.class, s.getId());
        assertThat(n).isEqualTo(2);
    }

    // ------------------------------------------------------------------------
    // diagnostic_run
    // ------------------------------------------------------------------------

    /**
     * Scenario 19 (socle) : la purge des invites supprime l'attempt civique, qui
     * emporte sa session ; la run, elle, reste — c'est elle qui compte les
     * « soumis anonymes jamais rattaches ».
     */
    @Test
    @DisplayName("La suppression de la session civique laisse la run intacte (FK SET NULL)")
    void runSurvitALaPurgeDesInvites() {
        User user = testData.user();
        Attempt attempt = testData.attempt(user);
        em.flush();
        UUID session = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO civic_diagnostic_sessions (id, user_id, attempt_id, mention, config_version, status)
                VALUES (?, ?, ?, 'CSP', 1, 'IN_PROGRESS')""", session, user.getId(), attempt.getId());
        UUID run = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO diagnostic_run (id, diagnostic_type, anonymous_id, civic_diagnostic_session_id,
                    submitted_at, submitted_authenticated)
                VALUES (?, 'CIVIQUE', ?, ?, now(), false)""", run, UUID.randomUUID(), session);

        jdbc.update("DELETE FROM civic_diagnostic_sessions WHERE id = ?", session);

        Integer restantes = jdbc.queryForObject(
                "SELECT count(*) FROM diagnostic_run WHERE id = ? AND civic_diagnostic_session_id IS NULL "
                        + "AND submitted_at IS NOT NULL", Integer.class, run);
        assertThat(restantes).isEqualTo(1);
    }

    @Test
    @DisplayName("Les états de la run sont cohérents : soumis, jeton et claim vont par paires")
    void coherenceDeLaRun() {
        String insert = """
                INSERT INTO diagnostic_run (id, diagnostic_type, submitted_at, submitted_authenticated,
                    claim_token_hash, claim_token_expires_at, claimed_at, claim_kind, claimed_via)
                VALUES (?, ?, ?::timestamptz, ?, ?, ?::timestamptz, ?::timestamptz, ?, ?)""";
        jdbc.update(insert, UUID.randomUUID(), "QUICK_TCF", "2026-09-25T10:00:00Z", false,
                "a".repeat(64), "2026-10-25T10:00:00Z", "2026-09-25T11:00:00Z", "SIGNUP", "SAME_DEVICE");

        refuse(insert, UUID.randomUUID(), "QUICK_TCF", "2026-09-25T10:00:00Z", null, null, null, null, null, null);
        refuse(insert, UUID.randomUUID(), "QUICK_TCF", null, null, "b".repeat(64), null, null, null, null);
        refuse(insert, UUID.randomUUID(), "QUICK_TCF", null, null, null, null, "2026-09-25T11:00:00Z", null, null);
        refuse(insert, UUID.randomUUID(), "TCF", null, null, null, null, null, null, null);
        refuse(insert, UUID.randomUUID(), "CIVIQUE", null, null, null, null, "2026-09-25T11:00:00Z",
                "SIGNUP", "HEURISTIQUE");
    }

    // ------------------------------------------------------------------------
    // users.is_internal (Q6) — rejoue le SQL reel de la migration
    // ------------------------------------------------------------------------

    /**
     * La migration a tourne sur une base de test vide : on rejoue son
     * initialisation, coupee sur sa sentinelle, sur des comptes fabriques ici.
     * Le SQL exerce est celui de la production, au caractere pres.
     */
    @Test
    @DisplayName("V074 initialise is_internal depuis l'ancienne liste excluded-emails, et rien d'autre")
    void initialisationIsInternal() {
        User admin = testData.user("Admin@SejourFR.fr");
        User karim = testData.user("karim.test@sejourfr.fr");
        User candidat = testData.user("candidat@exemple.fr");
        em.flush();
        assertThat(interne(admin)).isFalse();

        jdbc.execute(sqlDInitialisation());

        assertThat(interne(admin)).isTrue();
        assertThat(interne(karim)).isTrue();
        assertThat(interne(candidat)).isFalse();
    }

    private boolean interne(User user) {
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT is_internal FROM users WHERE id = ?", Boolean.class, user.getId()));
    }

    private static String sqlDInitialisation() {
        ClassPathResource resource = new ClassPathResource(
                "db/migration/00_schema/V074__schema_suivi_tunnel_diagnostic.sql");
        String migration;
        try (var in = resource.getInputStream()) {
            migration = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Migration V074 introuvable", e);
        }
        int coupe = migration.indexOf(SENTINELLE);
        assertTrue(coupe > 0, "Sentinelle " + SENTINELLE + " absente de V074 : le test ne peut plus "
                + "rejouer le SQL réel.");
        return migration.substring(coupe + SENTINELLE.length());
    }
}
