package com.sejourfr.app.migration;

import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;

/**
 * Fige les <b>16 unités du programme officiel</b> de l'examen civique (V068).
 *
 * <p>Source de droit : <b>arrêté du 10 octobre 2025</b> relatif au programme, aux
 * épreuves et aux modalités d'organisation de l'examen civique — JORF n° 0240 du
 * 12 octobre 2025, <b>NOR INTV2527907A</b>, articles 1 à 3 et <b>annexe I</b>.
 * Vérifié sur Légifrance le 2026-09-19 :
 * {@code https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052381620}
 *
 * <h2>🛑 Pourquoi un test et non un {@code CHECK} (garde-fou 2 de D-38)</h2>
 * <p>« La somme des 16 quotas vaut 40 » ne peut <b>pas</b> être une contrainte de
 * vérification : Postgres refuse une sous-requête en {@code CHECK}
 * (« {@code cannot use subquery in check constraint} ») et un {@code CHECK} est
 * <b>par ligne</b> — il ne peut pas sommer 16 lignes. Un trigger serait
 * disproportionné sur une table seedée une fois et jamais éditée. D-38 autorisait
 * explicitement les deux ; c'est la seconde branche.
 *
 * <h2>Les trois garde-fous de D-38, un par bloc de tests</h2>
 * <ol>
 *   <li>la table est <b>seedée par migration et pas éditable</b> — aucun endpoint
 *       n'existe, et le CHECK de rattachement refuse une notion active orpheline ;</li>
 *   <li>la <b>somme</b> vaut 40, dont 12 en mises en situation ;</li>
 *   <li>les <b>16 lignes et leurs quotas</b> sont verrouillés, l'arrêté cité.</li>
 * </ol>
 *
 * <p>⚠️ <b>Ce test ne lit jamais {@code questions.difficulty}.</b> C'est ce qui
 * rend la séparation P8.2a / P8.2b valide (D-41) : la table se seede et se
 * vérifie <b>sans que le filtre de mention bouge</b>.
 */
class CivicOfficialUnitSeedIT extends AbstractIntegrationTest {

    /** Les 16 unités de l'annexe I. Ni 14, ni 40, ni 46. */
    private static final int UNITES = 16;

    @Autowired
    private JdbcTemplate jdbc;

    // ------------------------------------------------------------------------
    // Garde-fou 3 — les 16 lignes et leurs quotas, verrouillés
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("🛑 Les 16 unités officielles, avec leur thématique et leur quota (annexe I)")
    void les16Unites() {
        final List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT code, theme_code, exam_quota, question_type
                FROM civic_official_units
                ORDER BY theme_code, display_order
                """);

        assertThat(rows)
                .as("Le programme compte %d unités : 14 notions de connaissance + 2 unités "
                        + "de mises en situation. %s", UNITES, ARRETE)
                .hasSize(UNITES);
        // ⚠️ `exam_quota` est un `smallint` : `queryForList` le rend en Integer,
        // pas en Short. Le miroir JPA, lui, le lit en `short` -- deux couches,
        // deux types, et c'est normal.
        assertThat(rows)
                .extracting("code", "theme_code", "exam_quota", "question_type")
                .containsExactlyInAnyOrder(
                        // T1 — Principes et valeurs de la République : 3 + 2 + 6 = 11
                        tuple("P1_DEVISE_SYMBOLES", "CIV_PRINCIPES", 3, "CONNAISSANCE"),
                        tuple("P2_LAICITE", "CIV_PRINCIPES", 2, "CONNAISSANCE"),
                        tuple("P3_MISES_EN_SITUATION", "CIV_PRINCIPES", 6, "MISE_SITUATION"),
                        // T2 — Système institutionnel et politique : 3 + 2 + 1 = 6
                        tuple("I1_DEMOCRATIE_VOTE", "CIV_INSTITUTIONS", 3, "CONNAISSANCE"),
                        tuple("I2_ORGANISATION_REPUBLIQUE", "CIV_INSTITUTIONS", 2, "CONNAISSANCE"),
                        tuple("I3_INSTITUTIONS_EUROPEENNES", "CIV_INSTITUTIONS", 1, "CONNAISSANCE"),
                        // T3 — Droits et devoirs : 2 + 3 + 6 = 11
                        tuple("D1_DROITS_FONDAMENTAUX", "CIV_DROITS_DEVOIRS", 2, "CONNAISSANCE"),
                        tuple("D2_OBLIGATIONS_DEVOIRS", "CIV_DROITS_DEVOIRS", 3, "CONNAISSANCE"),
                        tuple("D3_MISES_EN_SITUATION", "CIV_DROITS_DEVOIRS", 6, "MISE_SITUATION"),
                        // T4 — Histoire, géographie et culture : 3 + 3 + 2 = 8
                        tuple("H1_PERIODES_PERSONNAGES", "CIV_HISTOIRE_GEO", 3, "CONNAISSANCE"),
                        tuple("H2_TERRITOIRES_GEOGRAPHIE", "CIV_HISTOIRE_GEO", 3, "CONNAISSANCE"),
                        tuple("H3_PATRIMOINE", "CIV_HISTOIRE_GEO", 2, "CONNAISSANCE"),
                        // T5 — Vivre dans la société française : 1 + 1 + 1 + 1 = 4
                        tuple("S1_S_INSTALLER", "CIV_SOCIETE", 1, "CONNAISSANCE"),
                        tuple("S2_ACCES_AUX_SOINS", "CIV_SOCIETE", 1, "CONNAISSANCE"),
                        tuple("S3_TRAVAILLER", "CIV_SOCIETE", 1, "CONNAISSANCE"),
                        tuple("S4_AUTORITE_PARENTALE_EDUCATION", "CIV_SOCIETE", 1, "CONNAISSANCE"));
    }

    // ------------------------------------------------------------------------
    // Garde-fou 2 — la somme, que le DDL ne peut pas tenir
    // ------------------------------------------------------------------------

    /**
     * L'arrêté, cité pour le lecteur du message d'échec : c'est le seul rempart
     * qui reste, il doit dire POURQUOI il refuse, pas seulement QUOI.
     */
    private static final String ARRETE =
            "Arrêté du 10 octobre 2025 relatif au programme, aux épreuves et aux modalités "
            + "d'organisation de l'examen civique (JORF n° 0240 du 12 octobre 2025, "
            + "NOR INTV2527907A), annexe I. "
            + "🛑 Ce n'est pas un réglage produit : c'est la loi. Si un quota doit changer, "
            + "c'est que l'arrêté a changé — vérifier le texte sur Légifrance AVANT de "
            + "toucher au seed de V115, et consigner la décision. "
            + "🛑 Aucun CHECK ne peut tenir cette règle : Postgres refuse une sous-requête "
            + "en contrainte, et un CHECK est par ligne — il ne peut pas sommer 16 lignes "
            + "(D-38). CE TEST EST LE SEUL REMPART.";

    @Test
    @DisplayName("🛑 La somme des 16 quotas vaut 40 — et les mises en situation en font 12")
    void laSommeVaut40() {
        final Integer total = jdbc.queryForObject(
                "SELECT sum(exam_quota) FROM civic_official_units", Integer.class);
        final Integer mes = jdbc.queryForObject("""
                SELECT sum(exam_quota) FROM civic_official_units
                WHERE question_type = 'MISE_SITUATION'
                """, Integer.class);

        assertThat(total)
                .as("La somme des 16 quotas de `civic_official_units` doit valoir %d "
                        + "questions, elle vaut %s. %s",
                        CivicExamFormat.QUESTIONS, total, ARRETE)
                .isEqualTo(CivicExamFormat.QUESTIONS);

        assertThat(mes)
                .as("Les quotas de MISE_SITUATION doivent totaliser %d (6 en « Principes et "
                        + "valeurs », 6 en « Droits et devoirs », AUCUNE ailleurs), ils "
                        + "totalisent %s. %s",
                        CivicExamFormat.MISES_EN_SITUATION, mes, ARRETE)
                .isEqualTo(CivicExamFormat.MISES_EN_SITUATION);

        assertThat(total - mes)
                .as("Le reste doit être les %d questions de connaissance du partage officiel. "
                        + "%s", CivicExamFormat.CONNAISSANCES, ARRETE)
                .isEqualTo(CivicExamFormat.CONNAISSANCES);

        // 🛑 Et le partage lui-même : si CivicExamFormat dérive, ce test le dit
        // avant que la base ne soit mise en cause.
        CivicExamFormat.assertionsDeFormat();
    }

    @Test
    @DisplayName("🛑 Les totaux par thématique se DÉRIVENT : 11 / 6 / 11 / 8 / 4, déclarés nulle part")
    void lesTotauxParThematiqueSeDerivent() {
        // 🛑 Ces cinq nombres ne sont déclarés NULLE PART (D-38) : ni en base, ni
        // dans CivicExamFormat. Ce test est le seul endroit du dépôt qui les
        // écrit, et il les compare à une SOMME — pas à une seconde déclaration.
        final List<Map<String, Object>> parTheme = jdbc.queryForList("""
                SELECT theme_code, sum(exam_quota) AS total
                FROM civic_official_units GROUP BY theme_code ORDER BY theme_code
                """);

        assertThat(parTheme)
                .as("Les totaux par thématique doivent valoir 11 / 6 / 11 / 8 / 4 "
                        + "(Principes / Institutions / Droits / Histoire / Société). %s", ARRETE)
                .extracting("theme_code", "total")
                .containsExactly(
                        tuple("CIV_DROITS_DEVOIRS", 11L),
                        tuple("CIV_HISTOIRE_GEO", 8L),
                        tuple("CIV_INSTITUTIONS", 6L),
                        tuple("CIV_PRINCIPES", 11L),
                        tuple("CIV_SOCIETE", 4L));
    }

    @Test
    @DisplayName("Une seule unité de mises en situation par thématique, et seulement dans deux")
    void misesEnSituationDansDeuxThematiques() {
        final List<String> themes = jdbc.queryForList("""
                SELECT theme_code FROM civic_official_units
                WHERE question_type = 'MISE_SITUATION' ORDER BY theme_code
                """, String.class);

        // 🛑 L'arrêté n'en place AUCUNE dans les trois autres thématiques.
        assertThat(themes)
                .as("Les mises en situation ne vivent que dans « Principes et valeurs » et "
                        + "« Droits et devoirs ». %s", ARRETE)
                .containsExactly("CIV_DROITS_DEVOIRS", "CIV_PRINCIPES");
    }

    // ------------------------------------------------------------------------
    // Garde-fou 1 — seedée, pas éditable, et le rattachement est complet
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("🛑 Les 46 notions internes actives sont TOUTES rattachées à une unité")
    void les46NotionsSontRattachees() {
        final Integer orphelines = jdbc.queryForObject("""
                SELECT count(*) FROM civic_notions
                WHERE is_active = true AND official_unit_id IS NULL
                """, Integer.class);
        assertThat(orphelines)
                .as("une notion active sans unité officielle est une notion hors programme")
                .isZero();

        // Les désactivées restent à NULL : elles ne sont plus au programme.
        final Integer desactiveesRattachees = jdbc.queryForObject("""
                SELECT count(*) FROM civic_notions
                WHERE is_active = false AND official_unit_id IS NOT NULL
                """, Integer.class);
        assertThat(desactiveesRattachees).isZero();
    }

    @Test
    @DisplayName("🛑 La base REFUSE une notion active sans unité officielle")
    void uneNotionActiveOrphelineEstRefusee() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO civic_notions (id, code, label, theme_code, display_order, is_active)
                VALUES (gen_random_uuid(), 'tst_orpheline', 'Test', 'CIV_PRINCIPES', 99, true)
                """))
                .hasMessageContaining("chk_civic_notion_rattachee");
    }

    @Test
    @DisplayName("Chaque unité officielle porte au moins une notion interne")
    void aucuneUniteSansNotion() {
        // Une unité de CONNAISSANCE sans notion interne serait un pan du programme
        // que le corpus ne couvre pas du tout — pas un défaut de rattachement,
        // un trou éditorial. Les deux unités de MISES EN SITUATION en sont exclues :
        // elles ne portent jamais de notion, par construction (D-35).
        final List<String> sansNotion = jdbc.queryForList("""
                SELECT u.code FROM civic_official_units u
                WHERE u.question_type = 'CONNAISSANCE'
                  AND NOT EXISTS (
                      SELECT 1 FROM civic_notions n
                      WHERE n.official_unit_id = u.id AND n.is_active = true)
                ORDER BY u.code
                """, String.class);
        assertThat(sansNotion).isEmpty();
    }

    @Test
    @DisplayName("Une notion est rattachée à une unité de SA thématique")
    void rattachementCoherentAvecLeTheme() {
        final List<Map<String, Object>> incoherentes = jdbc.queryForList("""
                SELECT n.code AS notion, n.theme_code AS theme_notion,
                       u.code AS unite, u.theme_code AS theme_unite
                FROM civic_notions n JOIN civic_official_units u ON u.id = n.official_unit_id
                WHERE n.is_active = true AND n.theme_code <> u.theme_code
                ORDER BY n.code
                """);

        // ════════════════════════════════════════════════════════════════════
        // 🛑 AVIS AU RELECTEUR : LES TROIS LIGNES CI-DESSOUS NE SONT PAS UN BUG.
        // ════════════════════════════════════════════════════════════════════
        // Il est tentant de « corriger » une notion de CIV_PRINCIPES rattachée à
        // une unité de CIV_INSTITUTIONS ou de CIV_DROITS_DEVOIRS. Ne le faites
        // pas : ce sont des rattachements LÉGITIMES, et la raison est
        // structurelle, pas accidentelle.
        //
        // L'annexe I de l'arrêté ne donne à « Principes et valeurs de la
        // République » que DEUX notions de connaissance — « Devise et symboles »
        // et « Laïcité » — plus son unité de mises en situation. La taxonomie
        // interne, elle, y a rangé CINQ notions, parce qu'elle a été construite
        // à partir du corpus réel (V058) et non de l'arrêté. Les trois en trop
        // ne sont pas des principes au sens du texte : ce sont des DROITS
        // (égalité, libertés de la DDHC) et de la DÉMOCRATIE (la République
        // comme régime), que l'arrêté range explicitement ailleurs.
        //
        // Les rattacher de force à P1 ou P2 mettrait des questions sur l'égalité
        // dans le quota « Devise et symboles » : le tirage conforme tirerait
        // alors 3 questions de symboles dans un pool qui parle de
        // discrimination. C'est exactement le genre d'erreur que ce test existe
        // pour rendre impossible.
        //
        // ⚠️ CE TEST TOLÈRE LES CHEVAUCHEMENTS, ET C'EST VOULU. La taxonomie
        // interne et l'annexe I ne découpent pas au même endroit : TROIS notions
        // sont rattachées à une unité d'un AUTRE thème, chacune sur la foi de sa
        // propre description (V058 parle de « recouvrement assumé »). Le test
        // fige la liste au lieu de l'interdire : y ajouter une quatrième ligne
        // sans le dire devient impossible.
        //
        // 🛑 Les trois sortent TOUTES de CIV_PRINCIPES, et ce n'est pas un
        // hasard : l'annexe I ne donne à cette thématique que « Devise et
        // symboles » et « Laïcité », là où la taxonomie interne y a rangé cinq
        // notions. Les trois en trop sont donc des DROITS ou de la DÉMOCRATIE,
        // que l'arrêté range ailleurs.
        //
        // ⚠️ Deux cas que l'annexe A de l'audit signalait comme discutables ne
        // sont PAS des chevauchements de thème, et ce test l'a établi :
        // `hg_europe` → H1 et `vs_urgences_secours` → S2 restent chacun DANS
        // leur propre thème. Leur discussion portait sur l'unité voisine
        // (I3 Institutions européennes, S3 Travailler), pas sur le thème.
        assertThat(incoherentes)
                .extracting("notion", "unite")
                .containsExactlyInAnyOrder(
                        // « le principe, pas l'organe » → I1, hors CIV_PRINCIPES
                        tuple("pv_republique_democratie", "I1_DEMOCRATIE_VOTE"),
                        // l'égalité comme DROIT → D1
                        tuple("pv_egalite_non_discrimination", "D1_DROITS_FONDAMENTAUX"),
                        // « recouvrement ASSUMÉ », dit sa propre description → D1
                        tuple("pv_libertes_ddhc", "D1_DROITS_FONDAMENTAUX"));
    }
}
