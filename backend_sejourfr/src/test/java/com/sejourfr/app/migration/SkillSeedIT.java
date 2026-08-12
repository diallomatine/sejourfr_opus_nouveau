package com.sejourfr.app.migration;

import com.sejourfr.app.enums.SkillConstraintIcon;
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
 * competences x 15 petits sujets x 3 references.
 *
 * <p>Les sujets sont publies en DEUX lots : les rangs 1 a 5 par V300-V311, les
 * rangs 6 a 15 par V312-V317. Les premieres migrations etaient deja appliquees
 * quand le catalogue est passe de 5 a 15 sujets — on complete par ajout, jamais
 * en reecrivant une migration dont la somme de controle Flyway est figee.
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
    private static final int PROMPTS_PER_SKILL = 15;
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
    void everySkillPublishesFifteenActivePrompts() {
        assertThat(count("skill_prompts", "is_active" + NOT_A_FIXTURE)).isEqualTo(EXPECTED_PROMPTS);

        // Aucune competence hors du compte : ni 14, ni 16. Un sujet oublie par le
        // lot 2 se verrait ici, pas au deploiement.
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

    /**
     * <b>C'est ce test qui garantit la completude du guidage</b>, puisque V026 a
     * ajoute les quatre colonnes NULLABLES : la table portait deja ses lignes,
     * un {@code NOT NULL} sans defaut aurait echoue a l'ajout, et un sujet cree
     * depuis la console reste legalement sans guidage. La regle « tout sujet
     * PUBLIE en a un » n'est donc pas exprimable en DDL — elle vit ici.
     *
     * <p>Un sujet sans check-list ne casse rien (les fronts retombent sur la
     * consigne), mais il perd exactement ce que la refonte de l'ecran apporte :
     * l'exercice redeviendrait explique au lieu d'etre fait.
     */
    @Test
    void everyPublishedPromptCarriesItsCompleteInputGuidance() {
        assertThat(count("skill_prompts",
                "is_active" + NOT_A_FIXTURE
                        + " AND jsonb_typeof(checklist) = 'array'"
                        + " AND jsonb_array_length(checklist) BETWEEN 2 AND 4"
                        + " AND jsonb_typeof(constraint_tags) = 'array'"
                        + " AND jsonb_array_length(constraint_tags) BETWEEN 1 AND 3"
                        + " AND btrim(answer_starter) <> ''"
                        + " AND btrim(tip) <> ''"))
                .as("sujets publies dont le guidage est complet et dans les bornes")
                .isEqualTo(EXPECTED_PROMPTS);

        assertThat(jdbc.queryForList("""
                SELECT p.code FROM skill_prompts p, jsonb_array_elements_text(p.checklist) AS action
                WHERE p.is_active AND p.code NOT LIKE 'TST-%' AND btrim(action) = ''
                """))
                .as("sujets portant une action de check-list vide")
                .isEmpty();

        // L'amorce s'affiche en texte grise DANS le champ : les points de
        // suspension sont ce qui la donne a lire comme un debut a poursuivre, et
        // non comme une reponse deja ecrite.
        assertThat(count("skill_prompts",
                "is_active" + NOT_A_FIXTURE + " AND answer_starter LIKE '%…'"))
                .as("amorces terminees par des points de suspension")
                .isEqualTo(EXPECTED_PROMPTS);

        // Le prefixe « Astuce : » est ajoute par les fronts. Stocke, il
        // s'afficherait deux fois.
        assertThat(count("skill_prompts",
                "is_active" + NOT_A_FIXTURE + " AND tip ILIKE 'astuce%'"))
                .as("astuces qui repetent le prefixe ajoute par les fronts")
                .isZero();
    }

    /**
     * Les etiquettes disent COMMENT produire. La longueur et la duree, elles,
     * sont rendues par les fronts depuis les bornes deja en base : une etiquette
     * qui les redirait creerait une seconde verite, vouee a diverger de la
     * premiere le jour ou un editeur corrige les bornes.
     *
     * <p>L'icone, elle, appartient a une liste fermee que les deux fronts
     * mappent : une valeur inconnue n'afficherait rien du tout.
     */
    @Test
    void everyConstraintTagUsesAKnownIconAndNeverRestatesTheLength() {
        assertThat(jdbc.queryForList("""
                SELECT DISTINCT tag ->> 'icon' AS icon
                FROM skill_prompts p, jsonb_array_elements(p.constraint_tags) AS tag
                WHERE p.is_active AND p.code NOT LIKE 'TST-%'
                """))
                .extracting(row -> row.get("icon"))
                .as("icones employees par le contenu publie")
                .isSubsetOf((Object[]) nomsDesIcones())
                .doesNotContainNull();

        assertThat(jdbc.queryForList("""
                SELECT p.code, tag ->> 'label' AS label
                FROM skill_prompts p, jsonb_array_elements(p.constraint_tags) AS tag
                WHERE p.is_active AND p.code NOT LIKE 'TST-%'
                  AND (btrim(coalesce(tag ->> 'label', '')) = '' OR tag ->> 'label' ~ '[0-9]')
                """))
                .as("etiquettes vides, ou portant un chiffre — donc une longueur ou une duree")
                .isEmpty();
    }

    private int count(String table, String where) {
        Integer n = jdbc.queryForObject("SELECT count(*) FROM " + table + " WHERE " + where,
                Integer.class);
        return n == null ? 0 : n;
    }

    private static String[] codesDesTaches() {
        return java.util.Arrays.stream(SkillTaskCode.values()).map(Enum::name).toArray(String[]::new);
    }

    private static String[] nomsDesIcones() {
        return java.util.Arrays.stream(SkillConstraintIcon.values()).map(Enum::name)
                .toArray(String[]::new);
    }
}
