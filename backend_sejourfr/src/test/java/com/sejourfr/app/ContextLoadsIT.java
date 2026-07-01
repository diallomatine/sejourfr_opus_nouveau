package com.sejourfr.app;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Smoke test : le contexte Spring complet démarre sur Postgres embarqué, Flyway
 * applique toutes les migrations réelles, et {@code ddl-auto: validate} confirme
 * que le mapping JPA colle au schéma. Valide l'infra de test de bout en bout.
 */
class ContextLoadsIT extends AbstractIntegrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void contextLoadsAndFlywayMigrated() {
        Integer migrations = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM flyway_schema_history WHERE success = true", Integer.class);
        assertThat(migrations).isNotNull().isGreaterThan(200);

        Integer usersTable = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM information_schema.tables WHERE table_name = 'users'",
                Integer.class);
        assertThat(usersTable).isEqualTo(1);
    }
}
