package com.sejourfr.app.migration;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * V083 — le schéma des décisions admin tient ses invariants EN BASE : extension
 * btree_gist disponible sur le Postgres embarqué, non-chevauchement des
 * décisions courantes (contrainte d'exclusion), bornes et motif contrôlés.
 * Chaque cas viole UNE contrainte dans sa propre transaction de test.
 */
class AccesAdminSchemaIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private User user;
    private User admin;
    private UUID operation;

    @BeforeEach
    void setUp() {
        user = data.user();
        admin = data.admin();
        em.flush();
        operation = UUID.randomUUID();
        jdbc.update("INSERT INTO admin_access_operations (id, user_id, admin_user_id, operation, product, reason, "
                + "before_state, after_state) VALUES (?, ?, ?, 'GRANT', 'CIVIQUE', 'Motif de test', '[]', '[]')",
                operation, user.getId(), admin.getId());
    }

    private void inserer(String produit, String type, String debut, String fin, String superseded) {
        jdbc.update("INSERT INTO access_overrides (id, user_id, product, type, starts_at, ends_at, decided_at, "
                        + "reason, created_by, operation_id, superseded_at, superseded_by_operation_id) VALUES "
                        + "(?, ?, ?, ?, now() + (?)::interval, now() + (?)::interval, now(), 'Motif de test', ?, ?, "
                        + (superseded == null ? "NULL, NULL" : "now(), '" + superseded + "'") + ")",
                UUID.randomUUID(), user.getId(), produit, type, debut, fin, admin.getId(), operation);
    }

    @Test
    @DisplayName("btree_gist est installée par V083 (la prod doit l'autoriser)")
    void extensionInstallee() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM pg_extension WHERE extname = 'btree_gist'",
                Integer.class)).isEqualTo(1);
    }

    @Test
    @DisplayName("Deux décisions courantes qui se chevauchent sur le même produit : refusé")
    void chevauchementRefuse() {
        inserer("CIVIQUE", "GRANT", "0 days", "10 days", null);
        assertThatThrownBy(() -> inserer("CIVIQUE", "REVOKE", "5 days", null, null))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Fenêtres adjacentes, autre produit, ou ancienne décision remplacée : accepté")
    void casAdmis() {
        inserer("CIVIQUE", "GRANT", "0 days", "10 days", null);
        inserer("CIVIQUE", "REVOKE", "10 days", null, null);
        inserer("INTEGRAL", "GRANT", "0 days", "10 days", null);
        inserer("INTEGRAL", "GRANT", "2 days", "8 days", operation.toString());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM access_overrides WHERE user_id = ?",
                Integer.class, user.getId())).isEqualTo(4);
    }

    @Test
    @DisplayName("Un GRANT sans fin est refusé")
    void grantSansFin() {
        assertThatThrownBy(() -> inserer("CIVIQUE", "GRANT", "0 days", null, null))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Une fin avant le début est refusée")
    void finAvantDebut() {
        assertThatThrownBy(() -> inserer("CIVIQUE", "REVOKE", "5 days", "1 days", null))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Produit hors catalogue (TCF) refusé")
    void produitInconnu() {
        assertThatThrownBy(() -> inserer("TCF", "REVOKE", "0 days", null, null))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Motif de moins de 3 caractères refusé dans le journal")
    void motifTropCourt() {
        assertThatThrownBy(() -> jdbc.update("INSERT INTO admin_access_operations (id, user_id, admin_user_id, "
                        + "operation, product, reason, before_state, after_state) VALUES (?, ?, ?, 'END', 'CIVIQUE', "
                        + "' a ', '[]', '[]')", UUID.randomUUID(), user.getId(), admin.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    // ------------------------------------------------ V084 : sessions EO temps réel

    /** Une décision avec ses deux colonnes de sessions ; {@code remplacee} : déjà supersedée. */
    private UUID insererSessions(String produit, String type, String fin, int offertes, int restantes,
                                 boolean remplacee) {
        UUID id = UUID.randomUUID();
        jdbc.update("INSERT INTO access_overrides (id, user_id, product, type, starts_at, ends_at, decided_at, "
                        + "reason, created_by, operation_id, superseded_at, superseded_by_operation_id, "
                        + "realtime_eo_sessions_granted, realtime_eo_sessions_remaining) VALUES "
                        + "(?, ?, ?, ?, now(), now() + (?)::interval, now(), 'Motif de test', ?, ?, "
                        + (remplacee ? "now(), ?" : "NULL, NULL") + ", ?, ?)",
                remplacee
                        ? new Object[]{id, user.getId(), produit, type, fin, admin.getId(), operation, operation, offertes, restantes}
                        : new Object[]{id, user.getId(), produit, type, fin, admin.getId(), operation, offertes, restantes});
        return id;
    }

    @Test
    @DisplayName("V084 — un GRANT INTEGRAL courant porte un solde ≤ offertes ; défaut 0 sur une décision existante")
    void sessionsAdmises() {
        insererSessions("INTEGRAL", "GRANT", "10 days", 10, 4, false);
        inserer("CIVIQUE", "GRANT", "0 days", "10 days", null);
        assertThat(jdbc.queryForObject("SELECT realtime_eo_sessions_granted + realtime_eo_sessions_remaining "
                + "FROM access_overrides WHERE user_id = ? AND product = 'CIVIQUE'", Integer.class, user.getId())).isZero();
    }

    @Test
    @DisplayName("V084 — sessions sur un GRANT CIVIQUE : refusé")
    void sessionsSurCivique() {
        assertThatThrownBy(() -> insererSessions("CIVIQUE", "GRANT", "10 days", 5, 5, false))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — sessions sur un REVOKE : refusé")
    void sessionsSurRevoke() {
        assertThatThrownBy(() -> insererSessions("INTEGRAL", "REVOKE", "10 days", 5, 0, false))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — solde au-delà des sessions offertes : refusé")
    void soldeAuDelaDesOffertes() {
        assertThatThrownBy(() -> insererSessions("INTEGRAL", "GRANT", "10 days", 4, 5, false))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — solde négatif : refusé")
    void soldeNegatif() {
        assertThatThrownBy(() -> insererSessions("INTEGRAL", "GRANT", "10 days", 4, -1, false))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — une ligne remplacée ne garde jamais de solde (l'allocation, si)")
    void ligneRemplaceeSansSolde() {
        insererSessions("INTEGRAL", "GRANT", "10 days", 4, 0, true);
        assertThatThrownBy(() -> insererSessions("INTEGRAL", "GRANT", "10 days", 4, 4, true))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — une session temps réel n'a jamais deux porteurs (achat ET décision admin)")
    void sessionDeuxPorteurs() {
        UUID grant = insererSessions("INTEGRAL", "GRANT", "10 days", 4, 4, false);
        UUID achat = UUID.randomUUID();
        jdbc.update("INSERT INTO user_subscriptions (id, user_id, plan_id, source, status, auto_renew, starts_at, original_transaction_id) "
                        + "SELECT ?, ?, id, 'STRIPE', 'ACTIVE', false, now(), 'pi_schema_test' FROM plans LIMIT 1",
                achat, user.getId());
        assertThatThrownBy(() -> jdbc.update("INSERT INTO realtime_sessions (id, user_id, subscription_id, "
                        + "access_override_id, epreuve, tache_numero, provider, model, status, transcript, "
                        + "resumption_count, started_at, created_at, updated_at) VALUES (?, ?, ?, ?, 'TCF_EO', 1, "
                        + "'gemini', 'm', 'PENDING', '', 0, now(), now(), now())",
                UUID.randomUUID(), user.getId(), achat, grant))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("V084 — décision purgée : la session garde son historique, porteur remis à NULL (FK SET NULL)")
    void purgeDecisionSessionConservee() {
        UUID grant = insererSessions("INTEGRAL", "GRANT", "10 days", 4, 3, false);
        UUID session = UUID.randomUUID();
        jdbc.update("INSERT INTO realtime_sessions (id, user_id, access_override_id, epreuve, tache_numero, provider, "
                + "model, status, transcript, resumption_count, started_at, created_at, updated_at) VALUES (?, ?, ?, "
                + "'TCF_EO', 1, 'gemini', 'm', 'ACTIVE', '', 0, now(), now(), now())", session, user.getId(), grant);
        jdbc.update("DELETE FROM access_overrides WHERE id = ?", grant);
        assertThat(jdbc.queryForObject("SELECT access_override_id FROM realtime_sessions WHERE id = ?",
                UUID.class, session)).isNull();
    }
}
