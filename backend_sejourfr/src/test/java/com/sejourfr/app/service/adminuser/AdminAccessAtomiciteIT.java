package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Cas 15 — une correction de produit qui échoue à mi-parcours ne laisse RIEN :
 * ni le REVOKE déjà écrit, ni la ligne de journal (GO §5, « si une partie
 * échoue, aucune modification n'est conservée »).
 *
 * <p>🛑 Hors transaction de test ({@code NOT_SUPPORTED}) : dans la transaction
 * de rollback habituelle, l'action rejoindrait la transaction du test et ses
 * écritures resteraient visibles après l'échec — on ne prouverait rien.
 * L'échec est réel : un trigger de test fait échouer l'INSERT du GRANT en base,
 * APRÈS que le journal et le REVOKE ont été écrits et flushés.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class AdminAccessAtomiciteIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper om;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private AdminUserService adminUserService;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> comptes = new ArrayList<>();
    private final List<UUID> plans = new ArrayList<>();

    @AfterEach
    void nettoyer() {
        jdbc.execute("DROP TRIGGER IF EXISTS test_echec_grant ON access_overrides");
        jdbc.execute("DROP FUNCTION IF EXISTS test_echec_grant()");
        for (UUID id : comptes) {
            jdbc.update("DELETE FROM access_overrides WHERE user_id = ?", id);
            jdbc.update("DELETE FROM admin_access_operations WHERE user_id = ?", id);
            jdbc.update("DELETE FROM user_subscriptions WHERE user_id = ?", id);
        }
        for (UUID id : plans) jdbc.update("DELETE FROM plans WHERE id = ?", id);
        for (UUID id : comptes) jdbc.update("DELETE FROM users WHERE id = ?", id);
    }

    private User suivi(User u) {
        comptes.add(u.getId());
        return u;
    }

    @Test
    @DisplayName("Cas 15 — échec simulé sur le GRANT : rollback, le REVOKE et le journal ne sont pas persistés")
    void correctionQuiEchoueNeLaisseRien() throws Exception {
        User admin = suivi(data.admin());
        User u = suivi(data.user());
        UserSubscription civique = fx.achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(Duration.ofDays(1)),
                Instant.now().plus(Duration.ofDays(28)));
        plans.add(civique.getPlan().getId());
        Map<String, Object> achatAvant = fx.ligneAchat(civique.getId());
        String version = adminUserService.detail(u.getId()).accessVersion();

        jdbc.execute("""
                CREATE FUNCTION test_echec_grant() RETURNS trigger AS $$
                BEGIN
                  IF NEW.type = 'GRANT' AND NEW.product = 'INTEGRAL' AND NEW.user_id = '%s' THEN
                    RAISE EXCEPTION 'Echec simule du GRANT';
                  END IF;
                  RETURN NEW;
                END $$ LANGUAGE plpgsql""".formatted(u.getId()));
        jdbc.execute("CREATE TRIGGER test_echec_grant BEFORE INSERT ON access_overrides "
                + "FOR EACH ROW EXECUTE FUNCTION test_echec_grant()");

        mvc.perform(post("/api/admin/users/" + u.getId() + "/access-operations")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(om.writeValueAsString(Map.of(
                                "operation", "CORRECT_PRODUCT",
                                "product", "INTEGRAL",
                                "fromProduct", "CIVIQUE",
                                "endDateInclusive", AccesAdminFixtures.jour(27).toString(),
                                "reason", "Erreur de produit",
                                "dryRun", false,
                                "expectedVersion", version))))
                .andExpect(status().is5xxServerError());

        assertThat(jdbc.queryForObject("SELECT count(*) FROM access_overrides WHERE user_id = ?",
                Integer.class, u.getId())).as("aucun REVOKE conservé").isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM admin_access_operations WHERE user_id = ?",
                Integer.class, u.getId())).as("aucune entrée d'historique").isZero();
        assertThat(fx.ligneAchat(civique.getId())).isEqualTo(achatAvant);
        assertThat(adminUserService.detail(u.getId()).accesses().getFirst().status().name()).isEqualTo("ACTIVE");
    }
}
