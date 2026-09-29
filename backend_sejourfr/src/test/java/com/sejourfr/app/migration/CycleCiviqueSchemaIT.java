package com.sejourfr.app.migration;

import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Fige les invariants de <b>V069</b> : le cycle accueille le module civique.
 *
 * <h2>🛑 Le plafond d'un score est LU chez son autorité, jamais écrit ici</h2>
 * <p>{@code chk_journey_entry_score} ne borne que {@code >= 0}, volontairement.
 * Le maximum est {@code CivicExamFormat.QUESTIONS}, et un
 * {@code BETWEEN 0 AND 40} en base en aurait fait une 2<sup>e</sup> copie : un
 * changement de l'arrêté demanderait une <b>migration</b> là où il doit demander
 * une ligne de code. Ce test tient le plafond — et il le lit chez
 * {@link CivicExamFormat}, pas en littéral, sinon on aurait <b>déplacé</b> la
 * copie au lieu de la supprimer.
 */
class CycleCiviqueSchemaIT extends AbstractIntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    // ------------------------------------------------------------------------
    // L'objectif : une mention OU un palier, jamais les deux, jamais aucun
    // ------------------------------------------------------------------------

    // ⚠️ UNE violation de contrainte PAR TEST, et ce n'est pas du zèle : en
    // Postgres, un statement en échec ABORTE la transaction (`25P02`), et chaque
    // test roule dans une transaction unique annulée à la sortie. Deux
    // `assertThatThrownBy` dans le même test feraient échouer le second sur
    // « current transaction is aborted », pas sur la contrainte visée -- un vert
    // ou un rouge qui ne dit rien de la règle.

    @Test
    @DisplayName("Un cycle civique porte sa mention, et c'est un objectif valide")
    void cycleCiviquePorteSaMention() {
        jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure, next_position)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE', 'EN_COURS', 'NAT', 1)
                """, insererUser());

        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM journey WHERE target_procedure = 'NAT'", Integer.class))
                .isPositive();
    }

    @Test
    @DisplayName("🛑 Les DEUX objectifs à la fois : refusé")
    void deuxObjectifsRefuses() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_level, target_procedure, next_position)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE', 'EN_COURS', 'B2', 'NAT', 1)
                """, insererUser()))
                .hasMessageContaining("chk_journey_objectif");
    }

    @Test
    @DisplayName("🛑 AUCUN objectif : refusé — « pas de parcours sans niveau cible » (D-3)")
    void aucunObjectifRefuse() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, next_position)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE', 'EN_COURS', 1)
                """, insererUser()))
                .hasMessageContaining("chk_journey_objectif");
    }

    @Test
    @DisplayName("Le plafond d'un score civique est celui du format de l'épreuve, pas un littéral")
    void plafondDuScoreLuChezSonAutorite() {
        var user = insererUser();
        jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure,
                                     entry_score, exit_score, next_position)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE', 'EN_COURS', 'CSP', ?, ?, 1)
                """, user, CivicExamFormat.QUESTIONS, CivicExamFormat.SEUIL_REUSSITE);

        // 🛑 Le plafond est tenu ICI, et lu chez CivicExamFormat : la base ne
        // borne que `>= 0`, pour ne pas dupliquer la loi.
        Integer horsBornes = jdbc.queryForObject("""
                SELECT count(*) FROM journey
                WHERE entry_score > ? OR exit_score > ?
                """, Integer.class, CivicExamFormat.QUESTIONS, CivicExamFormat.QUESTIONS);
        assertThat(horsBornes)
                .as("aucun score civique ne peut dépasser les %d questions de l'épreuve "
                        + "(arrêté du 10 octobre 2025) — plafond lu chez CivicExamFormat",
                        CivicExamFormat.QUESTIONS)
                .isZero();

    }

    @Test
    @DisplayName("Un score négatif, la base le refuse : ça n'a aucun sens")
    void scoreNegatifRefuse() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure, entry_score, next_position)
                VALUES (gen_random_uuid(), ?, 'CIVIQUE', 'EN_COURS', 'CSP', -1, 1)
                """, insererUser()))
                .hasMessageContaining("chk_journey_entry_score");
    }

    // ------------------------------------------------------------------------
    // Le bloc : une épreuve OU une thématique
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("🛑 Un lot porte UN axe de bloc : une épreuve TCF ou une thématique civique")
    void unSeulAxeDeBlocParLot() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey_lot (id, journey_id, exam_type, theme_id, status, source_assessment_id)
                VALUES (gen_random_uuid(), ?, 'TCF_CO', ?, 'OPEN', gen_random_uuid())
                """, journey, theme))
                .hasMessageContaining("chk_journey_lot_bloc");
    }

    @Test
    @DisplayName("Un seul lot OUVERT par thématique et par cycle — jumeau de l'index TCF")
    void unSeulLotOuvertParThematique() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();
        jdbc.update("""
                INSERT INTO journey_lot (id, journey_id, theme_id, status, source_assessment_id)
                VALUES (gen_random_uuid(), ?, ?, 'OPEN', gen_random_uuid())
                """, journey, theme);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey_lot (id, journey_id, theme_id, status, source_assessment_id)
                VALUES (gen_random_uuid(), ?, ?, 'OPEN', gen_random_uuid())
                """, journey, theme))
                .hasMessageContaining("uq_journey_lot_open_par_theme");
    }

    // ------------------------------------------------------------------------
    // L'unité travaillable : une compétence TCF OU une unité officielle
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("🛑 Une étape d'entraînement porte EXACTEMENT UNE unité travaillable")
    void exactementUneUniteTravaillable() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();
        var lot = insererLotCivique(journey, theme);
        var unite = jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = 'P2_LAICITE'", java.util.UUID.class);

        // Une unité officielle civique : accepté.
        jdbc.update("""
                INSERT INTO journey_step (id, journey_id, lot_id, type, theme_id, official_unit_id, position)
                VALUES (gen_random_uuid(), ?, ?, 'TRAIN_SKILL', ?, ?, 1)
                """, journey, lot, theme, unite);

        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM journey_step WHERE official_unit_id = ?", Integer.class, unite))
                .isEqualTo(1);
    }

    @Test
    @DisplayName("🛑 AUCUNE unité travaillable sur un entraînement : refusé")
    void aucuneUniteTravaillableRefusee() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();
        var lot = insererLotCivique(journey, theme);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey_step (id, journey_id, lot_id, type, theme_id, position)
                VALUES (gen_random_uuid(), ?, ?, 'TRAIN_SKILL', ?, 1)
                """, journey, lot, theme))
                .hasMessageContaining("chk_journey_step_train_skill");
    }

    @Test
    @DisplayName("Une étape DIAGNOSTIC n'appartient à aucun bloc et ne porte aucune unité (A45)")
    void diagnosticSansBlocNiUnite() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey_step (id, journey_id, type, theme_id, position)
                VALUES (gen_random_uuid(), ?, 'DIAGNOSTIC', ?, 1)
                """, journey, theme))
                .hasMessageContaining("chk_journey_step_diagnostic");
    }

    @Test
    @DisplayName("Une unité officielle n'apparaît qu'une fois par lot — jumeau de l'index TCF")
    void uneUniteUneFoisParLot() {
        var journey = insererJourneyCivique();
        var theme = themeCivique();
        var lot = insererLotCivique(journey, theme);
        var unite = jdbc.queryForObject(
                "SELECT id FROM civic_official_units WHERE code = 'P1_DEVISE_SYMBOLES'",
                java.util.UUID.class);
        jdbc.update("""
                INSERT INTO journey_step (id, journey_id, lot_id, type, theme_id, official_unit_id, position)
                VALUES (gen_random_uuid(), ?, ?, 'TRAIN_SKILL', ?, ?, 1)
                """, journey, lot, theme, unite);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO journey_step (id, journey_id, lot_id, type, theme_id, official_unit_id, position)
                VALUES (gen_random_uuid(), ?, ?, 'TRAIN_SKILL', ?, ?, 2)
                """, journey, lot, theme, unite))
                .hasMessageContaining("uq_journey_step_lot_unite");
    }

    @Test
    @DisplayName("S-8 a été levé par V070, APRÈS l'arbitrage E-2 — et dans cet ordre")
    void s8LeveApresLArbitrage() {
        // ⚠️ CE TEST A CHANGÉ DE SENS, ET C'EST VOULU (2026-09-19). Il vérifiait
        // d'abord l'ABSENCE de `official_unit_id` : V069 refusait de l'ajouter,
        // parce que ç'aurait PRÉ-DÉCIDÉ E-2 -- « qui fait foi quand l'observation
        // civique et CivicLeitnerResolver divergent ? » -- et qu'une colonne morte
        // dans une migration livrée est définitive.
        //
        // L'arbitrage a eu lieu (D-49 : deux autorités, deux questions), et V070 a
        // posé la colonne. Le test fige donc désormais que S-8 est LEVÉ, et son
        // historique dit dans quel ORDRE -- ce qui est la seule chose qu'un
        // relecteur pourrait vouloir vérifier ici.
        Integer colonne = jdbc.queryForObject("""
                SELECT count(*) FROM information_schema.columns
                WHERE table_name = 'learning_plan_observations' AND column_name = 'official_unit_id'
                """, Integer.class);
        assertThat(colonne)
                .as("V070 lève S-8, après l'arbitrage E-2 et pas avant")
                .isEqualTo(1);
    }

    // ------------------------------------------------------------------------

    private java.util.UUID insererUser() {
        var id = java.util.UUID.randomUUID();
        jdbc.update("""
                INSERT INTO users (id, email, password_hash, role, auth_provider, created_at)
                VALUES (?, ?, 'x', 'USER', 'LOCAL', now())
                """, id, "cycle-civique-" + id + "@test.fr");
        return id;
    }

    private java.util.UUID insererJourneyCivique() {
        var id = java.util.UUID.randomUUID();
        jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure, next_position)
                VALUES (?, ?, 'CIVIQUE', 'EN_COURS', 'CR', 1)
                """, id, insererUser());
        return id;
    }

    private java.util.UUID themeCivique() {
        return jdbc.queryForObject(
                "SELECT id FROM themes WHERE code = 'CIV_PRINCIPES'", java.util.UUID.class);
    }

    private java.util.UUID insererLotCivique(java.util.UUID journey, java.util.UUID theme) {
        var id = java.util.UUID.randomUUID();
        jdbc.update("""
                INSERT INTO journey_lot (id, journey_id, theme_id, status, source_assessment_id)
                VALUES (?, ?, ?, 'OPEN', gen_random_uuid())
                """, id, journey, theme);
        return id;
    }
}
