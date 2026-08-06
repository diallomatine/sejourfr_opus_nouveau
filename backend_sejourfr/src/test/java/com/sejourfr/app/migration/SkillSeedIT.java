package com.sejourfr.app.migration;

import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Fige le CONTENU publie du module « Competences TCF » : 6 taches x 8
 * competences x 5 petits sujets x 3 references.
 *
 * <p><b>Pourquoi un test et non une contrainte.</b> La regle « exactement 8
 * competences actives par tache » vivait dans le DDL
 * ({@code CHECK display_order BETWEEN 1 AND 8} combine a
 * {@code UNIQUE (task_code, display_order)}). Avec 48 lignes seedees, les 8
 * rangs legaux de chaque tache etaient tous occupes : la console admin ne
 * pouvait plus creer aucune competence et son CRUD devenait decoratif. La borne
 * a ete elargie a 50 et la regle deplacee ici, la ou elle est reellement vraie —
 * sur le contenu publie, pas sur la forme du catalogue.
 *
 * <p>Les assertions excluent les codes de la fabrique de test
 * ({@code TST-%}) : chaque test roule dans une transaction annulee, mais
 * l'exclusion rend le compte exact independant de tout voisinage.
 */
class SkillSeedIT extends AbstractIntegrationTest {

    private static final int SKILLS_PER_TASK = 8;
    private static final int PROMPTS_PER_SKILL = 5;
    private static final int REFERENCES_PER_PROMPT = 3;

    private static final int EXPECTED_SKILLS = SkillTaskCode.values().length * SKILLS_PER_TASK;
    private static final int EXPECTED_PROMPTS = EXPECTED_SKILLS * PROMPTS_PER_SKILL;
    private static final int EXPECTED_REFERENCES = EXPECTED_PROMPTS * REFERENCES_PER_PROMPT;

    /** Codes reserves a {@code TestData} : hors perimetre du contenu publie. */
    private static final String NOT_A_FIXTURE = " AND code NOT LIKE 'TST-%'";

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void theCatalogPublishesEightActiveSkillsForEachOfTheSixTasks() {
        assertThat(count("skills", "is_active" + NOT_A_FIXTURE)).isEqualTo(EXPECTED_SKILLS);

        List<Map<String, Object>> perTask = jdbc.queryForList("""
                SELECT task_code, count(*) AS n FROM skills
                WHERE is_active AND code NOT LIKE 'TST-%'
                GROUP BY task_code
                """);

        assertThat(perTask).hasSize(SkillTaskCode.values().length);
        assertThat(perTask)
                .allSatisfy(row -> assertThat(((Number) row.get("n")).intValue())
                        .as("competences actives de %s", row.get("task_code"))
                        .isEqualTo(SKILLS_PER_TASK));
        assertThat(perTask).extracting(row -> row.get("task_code"))
                .containsExactlyInAnyOrder((Object[]) codesDesTaches());
    }

    @Test
    void everySkillPublishesFiveActivePrompts() {
        assertThat(count("skill_prompts", "is_active" + NOT_A_FIXTURE)).isEqualTo(EXPECTED_PROMPTS);

        // Aucune competence hors du compte : ni 4, ni 6.
        assertThat(jdbc.queryForList("""
                SELECT s.code, count(p.id) AS n
                FROM skills s LEFT JOIN skill_prompts p ON p.skill_id = s.id AND p.is_active
                WHERE s.is_active AND s.code NOT LIKE 'TST-%'
                GROUP BY s.code HAVING count(p.id) <> ?
                """, PROMPTS_PER_SKILL))
                .as("competences dont le nombre de sujets n'est pas %d", PROMPTS_PER_SKILL)
                .isEmpty();
    }

    @Test
    void everyPromptPublishesItsThreeReferencesOnePerLevel() {
        Integer total = jdbc.queryForObject("""
                SELECT count(*) FROM skill_references r
                JOIN skill_prompts p ON p.id = r.skill_prompt_id
                WHERE p.code NOT LIKE 'TST-%'
                """, Integer.class);
        assertThat(total).isEqualTo(EXPECTED_REFERENCES);

        // UNIQUE (prompt, level) interdit deja les doublons : ce qui reste a
        // verifier, c'est qu'aucun NIVEAU ne manque. Une reference absente
        // priverait l'ecran de resultat d'un de ses trois onglets.
        assertThat(jdbc.queryForList("""
                SELECT p.code, count(r.id) AS n
                FROM skill_prompts p LEFT JOIN skill_references r ON r.skill_prompt_id = p.id
                WHERE p.is_active AND p.code NOT LIKE 'TST-%'
                GROUP BY p.code HAVING count(r.id) <> ?
                """, REFERENCES_PER_PROMPT))
                .as("sujets dont le nombre de references n'est pas %d", REFERENCES_PER_PROMPT)
                .isEmpty();

        assertThat(jdbc.queryForList("""
                SELECT DISTINCT level FROM skill_references r
                JOIN skill_prompts p ON p.id = r.skill_prompt_id
                WHERE p.code NOT LIKE 'TST-%'
                """))
                .extracting(row -> row.get("level"))
                .containsExactlyInAnyOrder("INSUFFICIENT", "EXPECTED", "EXCELLENT");
    }

    @Test
    void noEditorialCodeIsPublishedTwice() {
        // L'unicite est en base ; ce qui se verifie ici, c'est que le
        // GENERATEUR de seed ne fabrique pas deux fois le meme code — un
        // doublon ferait echouer la migration au deploiement, pas au build.
        assertThat(jdbc.queryForList(
                "SELECT code FROM skills GROUP BY code HAVING count(*) > 1")).isEmpty();
        assertThat(jdbc.queryForList(
                "SELECT code FROM skill_prompts GROUP BY code HAVING count(*) > 1")).isEmpty();
    }

    @Test
    void writtenPromptsCarryWordBoundsAndOralPromptsCarryADuration() {
        int expectedPerSection = EXPECTED_PROMPTS / 2;

        assertThat(count("skill_prompts",
                "section = 'EE' AND is_active" + NOT_A_FIXTURE)).isEqualTo(expectedPerSection);
        assertThat(count("skill_prompts",
                "section = 'EO' AND is_active" + NOT_A_FIXTURE)).isEqualTo(expectedPerSection);

        // Le CHECK chk_skill_prompts_ee_eo_coherence garantit deja la forme ;
        // ce qui se verifie ici, c'est que le seed n'a pas classe un sujet dans
        // la mauvaise section — un sujet EO affichant un compteur de mots.
        assertThat(count("skill_prompts",
                "section = 'EE' AND is_active" + NOT_A_FIXTURE
                        + " AND recommended_min_words IS NOT NULL"
                        + " AND recommended_max_words IS NOT NULL"
                        + " AND recommended_duration_seconds IS NULL"))
                .isEqualTo(expectedPerSection);
        assertThat(count("skill_prompts",
                "section = 'EO' AND is_active" + NOT_A_FIXTURE
                        + " AND recommended_duration_seconds IS NOT NULL"
                        + " AND recommended_min_words IS NULL"
                        + " AND recommended_max_words IS NULL"))
                .isEqualTo(expectedPerSection);
    }

    /**
     * L'ecran d'une competence affiche DEUX textes distincts : une courte
     * explication et le critere general travaille. Un seed qui recopierait l'un
     * dans l'autre rendrait la colonne inutile et l'ecran redondant.
     */
    @Test
    void everySkillCarriesAnExplanationAndAGeneralCriterionThatDiffer() {
        assertThat(count("skills",
                "is_active" + NOT_A_FIXTURE
                        + " AND btrim(general_criterion) <> '' AND general_criterion <> description"))
                .isEqualTo(EXPECTED_SKILLS);
    }

    /** Chaque sujet porte son propre critere unique, distinct de celui des autres. */
    @Test
    void everyPromptCarriesItsOwnUniqueCriterion() {
        assertThat(count("skill_prompts",
                "is_active" + NOT_A_FIXTURE + " AND btrim(unique_criterion) <> ''"))
                .isEqualTo(EXPECTED_PROMPTS);
    }

    private int count(String table, String where) {
        Integer n = jdbc.queryForObject("SELECT count(*) FROM " + table + " WHERE " + where,
                Integer.class);
        return n == null ? 0 : n;
    }

    private static String[] codesDesTaches() {
        return java.util.Arrays.stream(SkillTaskCode.values()).map(Enum::name).toArray(String[]::new);
    }
}
