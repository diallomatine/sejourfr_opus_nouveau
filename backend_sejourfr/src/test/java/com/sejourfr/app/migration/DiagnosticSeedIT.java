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
                SELECT id, epreuve, titre, consigne, mots_min, mots_max,
                       duree_min_sec, duree_max_sec,
                       diagnostic_code, diagnostic_version, instruction_audio_url
                FROM production_tasks
                WHERE diagnostic_code = 'INITIAL_TCF' AND diagnostic_version = 1
                ORDER BY epreuve
                """);

        assertThat(rows).hasSize(2);
        assertThat(rows).extracting(row -> row.get("id"))
                .as("les UUID sont la clé de diagnostic_sessions ET de l'audio R2 : ils ne bougent jamais")
                .containsExactlyInAnyOrder(WRITTEN_ID, ORAL_ID);
        assertThat(rows).extracting(row -> row.get("epreuve"))
                .containsExactlyInAnyOrder("TCF_EE", "TCF_EO");

        Map<String, Object> written = rows.stream()
                .filter(row -> "TCF_EE".equals(row.get("epreuve"))).findFirst().orElseThrow();
        assertThat(((Number) written.get("mots_min")).intValue()).isEqualTo(100);
        assertThat(((Number) written.get("mots_max")).intValue()).isEqualTo(120);
        assertThat(written.get("titre")).isEqualTo("Une nouvelle activité");

        Map<String, Object> oral = rows.stream()
                .filter(row -> "TCF_EO".equals(row.get("epreuve"))).findFirst().orElseThrow();
        assertThat(((Number) oral.get("duree_min_sec")).intValue()).isEqualTo(90);
        assertThat(((Number) oral.get("duree_max_sec")).intValue()).isEqualTo(150);
        assertThat(oral.get("titre")).isEqualTo("Trouver une activité dans une nouvelle ville");
        assertThat(oral.get("instruction_audio_url"))
                .as("Flyway référence l'objet versionné généré et vérifié hors migration")
                .isEqualTo(ORAL_AUDIO_URL);
    }

    /**
     * Les consignes ont été raccourcies en place (V756) parce qu'elles se lisaient
     * comme un examen complet. Trois incises font tout le travail de rattrapage de
     * l'allowlist : sans elles, les compétences visées reviennent NOT_OBSERVED à
     * chaque diagnostic. Elles sont gelées ici, pas seulement recommandées.
     */
    @Test
    void lesConsignesPortentLesIncisesQuiRendentLAllowlistObservable() {
        String written = jdbc.queryForObject(
                "SELECT consigne FROM production_tasks WHERE id = ?", String.class, WRITTEN_ID);
        assertThat(written)
                .as("EE2-C7 · Exprimer une réaction ou un ressenti")
                .contains("ce que vous en avez pensé");
        assertThat(written).contains("Écrivez environ 100 à 120 mots.");
        assertThat(written)
                .as("l'ancienne consigne annonçait 130 mots et une quatrième puce")
                .doesNotContain("130");

        String oral = jdbc.queryForObject(
                "SELECT consigne FROM production_tasks WHERE id = ?", String.class, ORAL_ID);
        assertThat(oral)
                .as("EO1-C3 · Développer une réponse avec une précision")
                .contains("dites ce que vous cherchez");
        assertThat(oral)
                .as("EO2-C4 · Demander les conditions et les modalités")
                .contains("(activités, horaires, tarif, inscription)");
        assertThat(oral).contains("Parlez environ 2 minutes.");
        assertThat(oral)
                .as("l'ancienne consigne demandait 2 à 3 minutes et quatre étapes")
                .doesNotContain("2 à 3 minutes");
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

        // Les deux allowlists sont le contrat contre lequel les consignes sont
        // calibrées : V756 réécrit les consignes, jamais diagnostic_task_skills.
        assertThat(codesOf(WRITTEN_ID)).containsExactly(
                "EE1-C1", "EE1-C8", "EE2-C2", "EE2-C3", "EE2-C5", "EE2-C7", "EE3-C1", "EE3-C3");
        assertThat(codesOf(ORAL_ID)).containsExactly(
                "EO1-C1", "EO1-C3", "EO2-C2", "EO2-C3", "EO2-C4", "EO2-C7", "EO3-C1", "EO3-C3");

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

    private List<String> codesOf(UUID taskId) {
        return jdbc.queryForList("""
                SELECT s.code FROM diagnostic_task_skills d
                JOIN skills s ON s.id = d.skill_id
                WHERE d.production_task_id = ?
                ORDER BY d.display_order
                """, String.class, taskId);
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
