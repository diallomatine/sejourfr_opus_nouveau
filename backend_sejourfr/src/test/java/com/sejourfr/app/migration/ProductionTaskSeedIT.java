package com.sejourfr.app.migration;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Fige le CONTENU publie du catalogue des sujets EO/EE ({@code production_tasks},
 * seeds V700-V753) sur deux invariants que ni le DDL ni le code ne peuvent
 * porter.
 *
 * <p><b>1. Un sujet ne doit jamais demander ce que sa tache penalise.</b> La
 * rubrique {@code EO_T3} exige « une prise de position ET des arguments
 * developpes ET un monologue organise » et demande de « penaliser le propos
 * purement descriptif » ; son descripteur B2 exige une objection envisagee puis
 * traitee, et T3 est la SEULE tache ou ces marqueurs s'observent. Six sujets de
 * la bande A2 imposaient pourtant, en point obligatoire, de decrire ou de
 * raconter (« racontez un souvenir », « decrivez un voyage », « Que faites-vous
 * … ? ») : le candidat etait note en moins pour avoir fait exactement ce qu'on
 * lui demandait, et ne pouvait atteindre aucun marqueur B2. Corrige par V753,
 * verrouille ici.
 *
 * <p><b>2. La composition d'un examen ne doit jamais tomber en repli.</b>
 * {@code ProductionExamCompositionService} choisit le sujet dans le pool
 * (epreuve, tache, niveau de la bande du slot) ; pool vide, il retombe sur le
 * pool toutes-bandes en loggant un WARN. Les 18 triplets doivent donc rester
 * peuples — c'est ce qui garantit qu'un reclassement de sujet ne prive jamais
 * une tache de matiere.
 *
 * <p><b>Pourquoi un test et non une contrainte.</b> Meme raison que
 * {@link SkillSeedIT} : c'est une regle sur le contenu publie, pas sur la forme
 * du catalogue. Un CHECK figerait aussi la console d'administration.
 *
 * <p>Assertions seed-tolerantes : les lignes de {@code TestData} (consigne
 * prefixee « Consigne ») sont exclues, et les comptes sont exprimes en minimum
 * ou sur des ids explicites — jamais un total exact sur une table seedee, a
 * l'exception du pool EO T3 dont l'effectif est precisement ce que V753 ne doit
 * pas avoir bouge.
 */
class ProductionTaskSeedIT extends AbstractIntegrationTest {

    /** Lignes fabriquees par {@code TestData} : hors perimetre du contenu publie. */
    private static final String NOT_A_FIXTURE = " AND consigne NOT LIKE 'Consigne %'";

    /**
     * Marqueurs d'une EXIGENCE ARGUMENTATIVE (accents deja retires). Au moins un
     * doit figurer dans la consigne : c'est ce que la tache 3 note.
     */
    private static final List<String> EXIGENCE_ARGUMENTATIVE = List.of(
            "raison", "argument", "avantage", "inconvenient",
            "avis", "opinion", "position", "these", "objection");

    /**
     * Marqueurs d'une OBLIGATION DESCRIPTIVE OU NARRATIVE (accents deja retires).
     * Aucun ne doit figurer : ce sont les tournures que la rubrique T3 penalise.
     * Un exemple reste bienvenu — il est demande par « donnez un exemple precis
     * … pour illustrer », qui subordonne l'illustration a l'argument.
     */
    private static final List<String> OBLIGATION_DESCRIPTIVE = List.of(
            "decrivez", "racontez", "dites ou", "que faites-vous");

    /** Les six sujets EO T3 A2 reecrits par V753 (theme conserve, ids conserves). */
    private static final List<String> REECRITS_V753 = List.of(
            "88888888-3001-1000-0000-000000000001",
            "88888888-3001-1000-0000-000000000005",
            "88888888-3001-1000-0000-000000000006",
            "88888888-3002-1000-0000-000000000003",
            "88888888-3002-1000-0000-000000000006",
            "88888888-3002-1000-0000-000000000007");

    /** Effectif du pool EO T3 par niveau avant V753 — V753 ne retire aucun sujet. */
    private static final Map<String, Integer> POOL_EO_T3 = Map.of("A2", 8, "B1", 6, "B2", 6);

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void everyActiveEoTask3PromptAsksForAStanceAndNeverForAPlainDescription() {
        List<Map<String, Object>> sujets = jdbc.queryForList("""
                SELECT id, niveau_cible, consigne FROM production_tasks
                WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND is_active
                  AND consigne NOT LIKE 'Consigne %'
                """);

        assertThat(sujets).hasSize(POOL_EO_T3.values().stream().mapToInt(Integer::intValue).sum());

        assertThat(sujets).allSatisfy(row -> {
            String consigne = sansAccents((String) row.get("consigne"));
            String repere = row.get("niveau_cible") + " / " + row.get("id");

            assertThat(EXIGENCE_ARGUMENTATIVE)
                    .as("EO T3 %s doit demander une prise de position argumentee : %s", repere, consigne)
                    .anyMatch(consigne::contains);

            assertThat(OBLIGATION_DESCRIPTIVE)
                    .as("EO T3 %s ne doit rien imposer de purement descriptif : %s", repere, consigne)
                    .noneMatch(consigne::contains);
        });
    }

    @Test
    void theSixPromptsRewrittenByV753KeepTheirTaskLevelAndDuration() {
        List<Map<String, Object>> sujets = jdbc.queryForList("""
                SELECT id::text AS id, epreuve, tache_numero, niveau_cible, is_active,
                       duree_min_sec, duree_max_sec, mots_min, mots_max, consigne
                FROM production_tasks WHERE id IN ('%s')
                """.formatted(String.join("','", REECRITS_V753)));

        assertThat(sujets).hasSameSizeAs(REECRITS_V753);

        assertThat(sujets).allSatisfy(row -> {
            // Rien n'est reclasse ni desactive : les submissions passees restent
            // rattachees a un sujet lisible, et les pools gardent leur effectif.
            assertThat(row.get("epreuve")).isEqualTo("TCF_EO");
            assertThat(((Number) row.get("tache_numero")).intValue()).isEqualTo(3);
            assertThat(row.get("niveau_cible")).isEqualTo("A2");
            assertThat(row.get("is_active")).isEqualTo(Boolean.TRUE);
            assertThat(((Number) row.get("duree_min_sec")).intValue()).isEqualTo(120);
            assertThat(((Number) row.get("duree_max_sec")).intValue()).isEqualTo(210);
            assertThat(row.get("mots_min")).isNull();
            assertThat(row.get("mots_max")).isNull();

            String consigne = sansAccents((String) row.get("consigne"));
            assertThat(EXIGENCE_ARGUMENTATIVE).anyMatch(consigne::contains);
            assertThat(OBLIGATION_DESCRIPTIVE).noneMatch(consigne::contains);
        });
    }

    @Test
    void everyEpreuveTaskLevelTripleKeepsEnoughSubjectsToComposeAnExam() {
        List<Map<String, Object>> pools = jdbc.queryForList("""
                SELECT epreuve, tache_numero, niveau_cible, count(*) AS n
                FROM production_tasks
                WHERE is_active AND consigne NOT LIKE 'Consigne %'
                GROUP BY epreuve, tache_numero, niveau_cible
                """);

        // 2 epreuves x 3 taches x 3 niveaux : aucun pool vide, donc aucun repli
        // toutes-bandes dans ProductionExamCompositionService.pick.
        assertThat(pools).hasSize(18);
        assertThat(pools).allSatisfy(row ->
                assertThat(((Number) row.get("n")).intValue())
                        .as("pool %s T%s %s", row.get("epreuve"), row.get("tache_numero"), row.get("niveau_cible"))
                        .isPositive());

        // Le pool EO T3 garde exactement son effectif : V753 reecrit, ne retire rien.
        POOL_EO_T3.forEach((niveau, attendu) -> assertThat(count(
                "epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = '" + niveau + "' AND is_active"))
                .as("pool EO T3 %s", niveau)
                .isEqualTo(attendu));
    }

    private int count(String where) {
        Integer n = jdbc.queryForObject(
                "SELECT count(*) FROM production_tasks WHERE " + where + NOT_A_FIXTURE, Integer.class);
        return n == null ? 0 : n;
    }

    /** Minuscules + diacritiques retires : le test ne depend d'aucun encodage. */
    private static String sansAccents(String texte) {
        String normalise = Normalizer.normalize(texte, Normalizer.Form.NFD);
        return normalise.replaceAll("\\p{M}+", "").toLowerCase(Locale.ROOT);
    }
}
