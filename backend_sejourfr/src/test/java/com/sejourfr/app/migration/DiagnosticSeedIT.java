package com.sejourfr.app.migration;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Contrat durable du seed diagnostic initial et de ses invariants de schéma. */
class DiagnosticSeedIT extends AbstractIntegrationTest {

    private static final UUID WRITTEN_ID = UUID.fromString("d1a60000-0000-5000-8000-000000000001");
    private static final UUID ORAL_ID = UUID.fromString("d1a60000-0000-5000-8000-000000000002");
    private static final String ORAL_AUDIO_URL =
            "https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/" + ORAL_ID + ".mp3";

    @Autowired private JdbcTemplate jdbc;
    @Autowired private ProductionTaskManager taskManager;

    @Test
    void initialV1PublieExactementUnSujetEcritEtUnSujetOralFixes() {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT id, epreuve, mots_min, mots_max, duree_min_sec, duree_max_sec,
                       diagnostic_code, diagnostic_version, instruction_audio_url
                FROM production_tasks
                WHERE diagnostic_code = 'INITIAL_TCF' AND diagnostic_version = 1
                ORDER BY epreuve
                """);

        assertThat(rows).hasSize(2);
        assertThat(rows).extracting(row -> row.get("id"))
                .containsExactlyInAnyOrder(WRITTEN_ID, ORAL_ID);
        assertThat(rows).extracting(row -> row.get("epreuve"))
                .containsExactlyInAnyOrder("TCF_EE", "TCF_EO");

        Map<String, Object> written = rows.stream()
                .filter(row -> "TCF_EE".equals(row.get("epreuve"))).findFirst().orElseThrow();
        assertThat(((Number) written.get("mots_min")).intValue()).isEqualTo(100);
        assertThat(((Number) written.get("mots_max")).intValue()).isEqualTo(130);

        Map<String, Object> oral = rows.stream()
                .filter(row -> "TCF_EO".equals(row.get("epreuve"))).findFirst().orElseThrow();
        assertThat(((Number) oral.get("duree_min_sec")).intValue()).isEqualTo(120);
        assertThat(((Number) oral.get("duree_max_sec")).intValue()).isEqualTo(180);
        assertThat(oral.get("instruction_audio_url"))
                .as("Flyway référence l'objet versionné généré et vérifié hors migration")
                .isEqualTo(ORAL_AUDIO_URL);
    }

    @Test
    void chaqueSujetExposeUneAllowlistDeHuitCompetencesExistantes() {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT d.production_task_id, count(*) AS n,
                       count(DISTINCT s.code) AS distinct_codes
                FROM diagnostic_task_skills d
                JOIN skills s ON s.id = d.skill_id
                WHERE d.production_task_id IN (?, ?)
                GROUP BY d.production_task_id
                """, WRITTEN_ID, ORAL_ID);

        assertThat(rows).hasSize(2).allSatisfy(row -> {
            assertThat(((Number) row.get("n")).intValue()).isEqualTo(8);
            assertThat(((Number) row.get("distinct_codes")).intValue()).isEqualTo(8);
        });

        assertThat(jdbc.queryForObject("""
                SELECT count(*)
                FROM diagnostic_task_skills d
                WHERE d.production_task_id IN (?, ?)
                  AND NOT EXISTS (
                    SELECT 1 FROM skill_prompts p
                    WHERE p.skill_id = d.skill_id AND p.is_active = true
                  )
                """, Integer.class, WRITTEN_ID, ORAL_ID))
                .as("chaque compétence diagnostic permet une action immédiate réelle")
                .isZero();
    }

    @Test
    void catalogueStandardEtTirageNExposentJamaisLesSujetsDiagnostic() {
        assertThat(taskManager.findActive(EpreuveType.TCF_EE, null, null))
                .noneMatch(task -> task.isDiagnostic() || WRITTEN_ID.equals(task.getId()));
        assertThat(taskManager.findActive(EpreuveType.TCF_EO, null, null))
                .noneMatch(task -> task.isDiagnostic() || ORAL_ID.equals(task.getId()));
        assertThat(taskManager.findAllActive()).noneMatch(task -> task.isDiagnostic());
    }

    @Test
    void schemaFermeLesCoursesSurSessionAttemptsEtSoumission() {
        List<String> constraints = jdbc.queryForList("""
                SELECT conname FROM pg_constraint
                WHERE conrelid = 'diagnostic_sessions'::regclass
                """, String.class);
        assertThat(constraints)
                .contains("uq_diagnostic_session_user_version",
                        "uq_diagnostic_session_written_attempt",
                        "uq_diagnostic_session_oral_attempt");

        List<String> indexes = jdbc.queryForList("""
                SELECT indexname FROM pg_indexes
                WHERE tablename = 'production_submissions'
                """, String.class);
        assertThat(indexes).contains("uq_prod_submission_diagnostic_attempt");
    }
}
