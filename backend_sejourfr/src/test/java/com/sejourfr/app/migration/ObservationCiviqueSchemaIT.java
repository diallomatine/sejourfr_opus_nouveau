package com.sejourfr.app.migration;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Fige les invariants de <b>V070</b> : l'observation accueille l'unité officielle
 * civique, et <b>exactement une</b> unité observée.
 *
 * <p>Arbitrage : <b>D-49</b> (E-2). Deux autorités, deux questions — l'observation
 * clôture l'étape du cycle, {@code CivicLeitnerResolver} dit l'état présent.
 *
 * <p>⚠️ Une violation de contrainte par test : en Postgres un statement en échec
 * aborte la transaction.
 */
class ObservationCiviqueSchemaIT extends AbstractIntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    @DisplayName("Une observation civique porte son unité officielle, et pas de compétence")
    void observationCiviqueSurUneUnite() {
        UUID user = insererUser();
        UUID unite = unite("P2_LAICITE");

        jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, official_unit_id, source_type, source_id, observed, status,
                     evidence, baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, ?, 'CIVIQUE_SERIE', gen_random_uuid(), true,
                        'SOLID', '8 bonnes sur 10', false, now(), now())
                """, user, unite);

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM learning_plan_observations
                WHERE official_unit_id = ? AND skill_id IS NULL
                """, Integer.class, unite)).isEqualTo(1);
    }

    @Test
    @DisplayName("🛑 Les DEUX unités observées à la fois : refusé")
    void deuxUnitesObserveesRefusees() {
        UUID user = insererUser();
        UUID skill = jdbc.queryForObject(
                "SELECT id FROM skills WHERE is_active LIMIT 1", UUID.class);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, skill_id, official_unit_id, source_type, source_id, observed,
                     status, evidence, baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, ?, ?, 'CIVIQUE_SERIE', gen_random_uuid(), true,
                        'SOLID', 'x', false, now(), now())
                """, user, skill, unite("P1_DEVISE_SYMBOLES")))
                .hasMessageContaining("chk_learning_plan_observation_unite");
    }

    @Test
    @DisplayName("🛑 AUCUNE unité observée : refusé")
    void aucuneUniteObserveeRefusee() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, source_type, source_id, observed, status, evidence,
                     baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE_SERIE', gen_random_uuid(), true,
                        'SOLID', 'x', false, now(), now())
                """, insererUser()))
                .hasMessageContaining("chk_learning_plan_observation_unite");
    }

    @Test
    @DisplayName("Les deux sources civiques sont admises, et elles seules s'ajoutent aux neuf")
    void lesDeuxSourcesCiviques() {
        UUID user = insererUser();
        UUID unite = unite("S3_TRAVAILLER");
        for (String source : new String[] {"CIVIQUE_SERIE", "CIVIQUE_EXAMEN"}) {
            jdbc.update("""
                    INSERT INTO learning_plan_observations
                        (id, user_id, official_unit_id, source_type, source_id, observed, status,
                         evidence, baseline, observed_at, created_at)
                    VALUES (gen_random_uuid(), ?, ?, ?, gen_random_uuid(), true, 'SOLID',
                            'x', false, now(), now())
                    """, user, unite, source);
        }
        assertThat(jdbc.queryForObject("""
                SELECT count(DISTINCT source_type) FROM learning_plan_observations
                WHERE official_unit_id = ?
                """, Integer.class, unite)).isEqualTo(2);
    }

    @Test
    @DisplayName("🛑 Une source inconnue reste refusée — le CHECK n'a pas été élargi à tout")
    void sourceInconnueRefusee() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, official_unit_id, source_type, source_id, observed, status,
                     evidence, baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, ?, 'CIVIQUE_QUELQUE_CHOSE', gen_random_uuid(),
                        true, 'SOLID', 'x', false, now(), now())
                """, insererUser(), unite("P2_LAICITE")))
                .hasMessageContaining("chk_learning_plan_observation_source");
    }

    @Test
    @DisplayName("🛑 Deux observations civiques de la MÊME source sont refusées — l'index jumeau")
    void uniciteParSourceCivique() {
        // ⚠️ `uq_learning_plan_observation_source` ne suffit pas : Postgres traite
        // les NULL comme DISTINCTS dans un index unique, donc deux lignes avec
        // `skill_id` nul y passeraient. D'où l'index jumeau sur la colonne civique.
        UUID user = insererUser();
        UUID unite = unite("H3_PATRIMOINE");
        UUID source = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, official_unit_id, source_type, source_id, observed, status,
                     evidence, baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, ?, 'CIVIQUE_SERIE', ?, true, 'SOLID',
                        'x', false, now(), now())
                """, user, unite, source);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO learning_plan_observations
                    (id, user_id, official_unit_id, source_type, source_id, observed, status,
                     evidence, baseline, observed_at, created_at)
                VALUES (gen_random_uuid(), ?, ?, 'CIVIQUE_SERIE', ?, true, 'SOLID',
                        'y', false, now(), now())
                """, user, unite, source))
                .hasMessageContaining("uq_learning_plan_observation_source_unite");
    }

    private UUID insererUser() {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO users (id, email, password_hash, role, auth_provider, created_at)
                VALUES (?, ?, 'x', 'USER', 'LOCAL', now())
                """, id, "obs-civique-" + id + "@test.fr");
        return id;
    }

    private UUID unite(String code) {
        return jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = ?", UUID.class, code);
    }
}
