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
}
