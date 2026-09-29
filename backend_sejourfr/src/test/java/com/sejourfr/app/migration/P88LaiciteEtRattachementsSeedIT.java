package com.sejourfr.app.migration;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Fige ce que <b>P8.8</b> a écrit : les 12 questions de « Laïcité » (V203), les
 * 6 rattachements et les 4 désactivations (V299).
 *
 * <h2>🛑 Pourquoi un test, alors que les deux migrations portent un garde</h2>
 * <p>Le garde d'une migration protège <b>l'instant de son application</b> : il
 * s'exécute une fois, puis Flyway ne le rejoue jamais. Ce test protège
 * <b>l'état</b> — une migration ultérieure qui désactiverait une question de
 * Laïcité, ou taguerait une des huit en attente, ferait retomber l'unité sous le
 * seuil de R2 <b>sans que rien ne le dise</b>. C'est exactement le motif du
 * garde-fou 2 de D-38 : ce qui n'est pas testé n'est pas garanti.
 *
 * <h2>🛑 Le test ne fixe aucun choix qu'il ne pose pas lui-même</h2>
 * <p>Il ne lit ni l'ordre du tirage, ni un premier élément, ni une liste
 * plafonnée : il compte, et il nomme les identifiants qu'il vérifie. C'est la
 * règle écrite dans {@code docs/plan-tests-backend.md} après trois tests
 * dormants en deux jours.
 *
 * <h2>⚠️ Ce test tourne sur la base des migrations de PRODUCTION</h2>
 * <p>Zonky applique {@code db/migration}, <b>jamais</b> {@code db/migration-dev}.
 * C'est ce qui a révélé que le « doublon » de Laïcité n'existe que sur une base
 * de dev : l'unité compte <b>8</b> questions en production, pas 9, et les douze
 * de V203 l'amènent à 20 <b>sans</b> la désactivation.
 *
 * <p>⚠️ <b>Il ne lit jamais {@code questions.difficulty}.</b> Les douze portent
 * {@code 'CR'}, et cette valeur est <b>inerte depuis P8.2b</b> (D-42) : la
 * vérifier reviendrait à geler un remplissage.
 */
class P88LaiciteEtRattachementsSeedIT extends AbstractIntegrationTest {

    /** Le seuil de R2 : une unité sous 20 questions ne peut pas se mesurer. */
    private static final int SEUIL_R2 = 20;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    @DisplayName("L'unité « Laïcité » atteint le seuil de R2 — 20 questions actives")
    void laicite_a_vingt_questions_actives() {
        Integer actives = jdbc.queryForObject("""
                SELECT count(*)
                  FROM questions q
                  JOIN civic_notions n ON n.id = q.civic_notion_id
                  JOIN civic_official_units u ON u.id = n.official_unit_id
                 WHERE u.code = 'P2_LAICITE'
                   AND q.is_active AND q.status = 'ACTIVE'
                """, Integer.class);

        assertThat(actives)
                .as("P2_LAICITE : 8 conservées (9 − le doublon) + 12 neuves")
                .isEqualTo(SEUIL_R2);
    }

    @Test
    @DisplayName("Les 12 questions neuves portent leurs 4 choix et UNE bonne réponse")
    void les_douze_portent_quatre_choix_et_une_bonne_reponse() {
        Integer neuves = jdbc.queryForObject(
                "SELECT count(*) FROM questions WHERE id::text LIKE 'c8800001-%'",
                Integer.class);
        assertThat(neuves).isEqualTo(12);

        // 🛑 Un QCM à deux bonnes réponses corrige faux sans que rien ne le dise :
        // le runner en accepte une seule.
        List<String> horsContrat = jdbc.queryForList("""
                SELECT c.question_id::text
                  FROM choices c
                 WHERE c.question_id::text LIKE 'c8800001-%'
                 GROUP BY c.question_id
                HAVING count(*) <> 4
                    OR count(*) FILTER (WHERE c.is_correct) <> 1
                """, String.class);

        assertThat(horsContrat)
                .as("chaque question neuve : exactement 4 choix, exactement 1 correct")
                .isEmpty();
    }

    @Test
    @DisplayName("Les 3 hors programme sont ARCHIVÉES, et elles existent toujours")
    void les_trois_desactivees_sont_archivees_mais_conservees() {
        // 🛑 TROIS, et non quatre. Le quatrième — le doublon de Laïcité,
        // `c0000001-…0002` — n'existe que sur une base de DEV :
        // `migration-dev/V900__seed_dev.sql` l'insère, aucune migration de
        // production ne le fait. V299 l'éteint là où il est, et c'est un no-op
        // ici. Trouvé par le garde de la migration, pas par une relecture.
        List<String> ids = List.of(
                "f4000002-0000-0000-0000-00000000005d",  // traités de Westphalie
                "f4000002-0000-0000-0000-0000000000d7",  // COP21
                "f5000002-0000-0000-0000-00000000001c"); // âge en boîte de nuit

        // 🛑 DESACTIVER, JAMAIS SUPPRIMER : ces lignes sont référencées par des
        // `attempt_questions`. Le test vérifie donc qu'elles SONT LÀ autant
        // qu'elles sont éteintes.
        Integer presentes = jdbc.queryForObject(
                "SELECT count(*) FROM questions WHERE id::text IN (%s)"
                        .formatted(placeholders(ids)),
                Integer.class, ids.toArray());
        assertThat(presentes).as("aucune suppression").isEqualTo(3);

        // 🛑 LES DEUX DRAPEAUX : `findOrdered` (les séries par thème) ne filtre
        // que `is_active`, le tirage conforme filtre les deux. N'en poser qu'un
        // laisserait la question visible dans la moitié des chemins.
        Integer eteintes = jdbc.queryForObject(
                ("SELECT count(*) FROM questions WHERE id::text IN (%s)"
                        + " AND is_active = false AND status = 'ARCHIVED'")
                        .formatted(placeholders(ids)),
                Integer.class, ids.toArray());
        assertThat(eteintes).as("éteintes des DEUX côtés").isEqualTo(3);
    }

    @Test
    @DisplayName("Il reste 8 connaissances sans notion — celles que SIGNAL-T1 attend")
    void huit_connaissances_restent_sans_notion() {
        Integer sansNotion = jdbc.queryForObject("""
                SELECT count(*) FROM questions
                 WHERE module = 'CIVIQUE' AND question_type = 'CONNAISSANCE'
                   AND is_active AND status = 'ACTIVE'
                   AND civic_notion_id IS NULL
                """, Integer.class);

        // 🛑 Ce chiffre est un ARBITRAGE, pas un reliquat (option 3, 2026-09-20) :
        // les 8 ont une unité officielle évidente mais aucune notion interne qui
        // couvre leur sujet. Forcer la moins fausse ferait dire au plan dérivé de
        // travailler autre chose que ce qui a été raté. SIGNAL-T1 porte la liste
        // des notions à créer le jour venu.
        assertThat(sansNotion)
                .as("8 en attente d'une notion qui n'existe pas encore")
                .isEqualTo(8);
    }

    @Test
    @DisplayName("Les 6 rattachements visent la notion nommée, et ne touchent pas theme_id")
    void les_six_rattachements_visent_la_bonne_notion() {
        assertNotion("f0000001-0000-0000-0000-000000000124", "pv_egalite_non_discrimination");
        assertNotion("f3000002-0000-0000-0000-0000000000b5", "inst_gouvernement");
        assertNotion("f3000002-0000-0000-0000-0000000000b6", "inst_gouvernement");
        assertNotion("f2000002-0000-0000-0000-000000000090", "inst_gouvernement");
        assertNotion("f5000002-0000-0000-0000-00000000001e", "inst_gouvernement");
        assertNotion("f3000001-0000-0000-0000-000000000015", "pv_republique_democratie");

        // 🛑 D-47 : le rattachement est CROSS-THÈME et `theme_id` ne bouge pas.
        // La question reste rangée en « Principes » (l'axe du CORPUS) et rejoint
        // une unité de « Droits et devoirs » (l'axe du PROGRAMME).
        String theme = jdbc.queryForObject("""
                SELECT t.code FROM questions q JOIN themes t ON t.id = q.theme_id
                 WHERE q.id = 'f0000001-0000-0000-0000-000000000124'
                """, String.class);
        assertThat(theme).isEqualTo("CIV_PRINCIPES");

        String unite = jdbc.queryForObject("""
                SELECT u.code
                  FROM questions q
                  JOIN civic_notions n ON n.id = q.civic_notion_id
                  JOIN civic_official_units u ON u.id = n.official_unit_id
                 WHERE q.id = 'f0000001-0000-0000-0000-000000000124'
                """, String.class);
        assertThat(unite).isEqualTo("D1_DROITS_FONDAMENTAUX");
    }

    private void assertNotion(String questionId, String notionCode) {
        String code = jdbc.queryForObject("""
                SELECT n.code FROM questions q
                  JOIN civic_notions n ON n.id = q.civic_notion_id
                 WHERE q.id = ?::uuid
                """, String.class, questionId);
        assertThat(code).as(questionId).isEqualTo(notionCode);
    }

    private static String placeholders(List<String> valeurs) {
        return String.join(", ", valeurs.stream().map(v -> "?").toList());
    }
}
