package com.sejourfr.app.migration;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.text.Normalizer;
import java.util.HashMap;
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

    /**
     * Fige les BORNES DE MOTS publiees des trois taches EE : T1 30-60, T2 et T3
     * <b>40-90</b> (volume officiel du TCF IRN). Elles sont strictes — aucune
     * tolerance serveur, aucune tolerance front — donc un minimum trop haut
     * refuse une copie recevable : V723 avait fige T2/T3 a 60, ce qui bloquait
     * toute production de 40 a 59 mots ; V724 corrige le minimum, les maximums
     * et la tache 1 etant deja justes.
     *
     * <p>Assertions seed-tolerantes : on ne compte aucun total, on verifie que
     * <b>chaque</b> sujet publie de chaque tache porte exactement ces bornes.
     */
    @Test
    void everyPublishedEeTaskCarriesTheOfficialTcfIrnWordBounds() {
        Map<Integer, int[]> attendu = Map.of(1, new int[]{30, 60}, 2, new int[]{40, 90}, 3, new int[]{40, 90});

        attendu.forEach((tache, bornes) -> {
            List<Map<String, Object>> sujets = jdbc.queryForList("""
                    SELECT id::text AS id, mots_min, mots_max FROM production_tasks
                    WHERE epreuve = 'TCF_EE' AND tache_numero = ? AND is_active
                      AND consigne NOT LIKE 'Consigne %'
                    """, tache);

            assertThat(sujets).as("pool EE T%d", tache).isNotEmpty().allSatisfy(row -> {
                assertThat(((Number) row.get("mots_min")).intValue())
                        .as("EE T%d %s : mots_min", tache, row.get("id"))
                        .isEqualTo(bornes[0]);
                assertThat(((Number) row.get("mots_max")).intValue())
                        .as("EE T%d %s : mots_max", tache, row.get("id"))
                        .isEqualTo(bornes[1]);
            });
        });
    }

    /**
     * Les 9 exemples-modeles EE livres (V761, reecrits par V762) restent dans la
     * fourchette de leur tache apres l'elargissement de V724 : la borne basse
     * descend, aucune borne haute ne bouge, donc aucun exemple ne sort. Comptage
     * identique au backend : {@code contenu.trim().split("\\s+").length}.
     */
    @Test
    void theNineDeliveredEeExamplesStayWithinTheirTaskBounds() {
        List<Map<String, Object>> exemples = jdbc.queryForList("""
                SELECT e.id::text AS id, t.tache_numero, t.mots_min, t.mots_max,
                       array_length(regexp_split_to_array(btrim(e.contenu), '\\s+'), 1) AS mots
                FROM production_examples e
                JOIN production_tasks t ON t.id = e.task_id
                WHERE t.epreuve = 'TCF_EE' AND t.consigne NOT LIKE 'Consigne %'
                """);

        assertThat(exemples).hasSize(9).allSatisfy(row ->
                assertThat(((Number) row.get("mots")).intValue())
                        .as("exemple EE T%s %s", row.get("tache_numero"), row.get("id"))
                        .isBetween(((Number) row.get("mots_min")).intValue(),
                                ((Number) row.get("mots_max")).intValue()));
    }

    /**
     * Fige les TITRES EDITORIAUX publies par V754 (colonne posee par V028).
     *
     * <p>Leur raison d'etre est de <b>distinguer</b> deux sujets d'une meme
     * tache : les consignes d'une tache commencent toutes de la meme facon, et
     * une carte « Sujet 01 » + debut de consigne ne se lisait pas. Un titre
     * duplique dans une tache, un titre absent ou un titre qui redit ce que la
     * carte affiche deja (tache, palier, nombre de mots) ruine cette raison
     * d'etre — le generateur le refuse, ce test le verrouille en base.
     *
     * <p>Le titre reste NULLABLE : c'est le CONTENU PUBLIE qu'on exige complet,
     * pas la colonne. Les lignes de {@code TestData} en sont exclues, comme
     * partout ici.
     */
    @Test
    void everyPublishedSubjectCarriesADistinctiveEditorialTitle() {
        List<Map<String, Object>> sujets = jdbc.queryForList("""
                SELECT id::text AS id, epreuve, tache_numero, titre
                FROM production_tasks
                WHERE consigne NOT LIKE 'Consigne %'
                """);

        assertThat(sujets).hasSize(103);

        Map<String, String> vusParTache = new HashMap<>();
        assertThat(sujets).allSatisfy(row -> {
            String titre = (String) row.get("titre");
            String repere = row.get("epreuve") + " T" + row.get("tache_numero") + " / " + row.get("id");

            assertThat(titre).as("titre de %s", repere).isNotNull();
            assertThat(titre.strip()).as("titre blanc sur %s", repere).isEqualTo(titre).isNotEmpty();
            assertThat(titre.length()).as("longueur du titre de %s", repere).isLessThanOrEqualTo(80);

            // 2 a 5 mots : au-dela, le titre passe a la ligne sur une carte de
            // telephone et cesse d'etre lisible d'un coup d'oeil.
            int mots = titre.split("\\s+").length;
            assertThat(mots).as("« %s » (%s)", titre, repere).isBetween(2, 5);

            // Aucun chiffre : ni numero de tache, ni nombre de mots, ni duree —
            // ces informations vivent deja dans les autres badges de la carte.
            assertThat(titre).as("« %s » (%s) porte un chiffre", titre, repere)
                    .matches("[^0-9]+");

            String cle = row.get("epreuve") + "/" + row.get("tache_numero") + "/" + sansAccents(titre);
            String deja = vusParTache.put(cle, repere);
            assertThat(deja).as("« %s » se confond avec %s dans la meme tache", titre, deja).isNull();
        });
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
