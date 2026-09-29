package com.sejourfr.app.migration;

import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Fige les invariants de <b>V071</b> : le journal des évaluations accueille le
 * civique.
 *
 * <h2>🛑 La garantie de V066 n'est pas desserrée, elle est bornée au côté sans axe</h2>
 * <p>Un examen civique complet doit pouvoir écrire <b>six lignes</b> pour un
 * seul {@code attempt} — une globale, cinq par thématique (R1). La clé passe
 * donc de {@code UNIQUE (journey_id, source_assessment_id)} à deux index
 * partiels jumeaux. Ce qui compte, et que ces tests tiennent : côté
 * {@code theme_id IS NULL} — <b>tout le TCF</b> — la clé est exactement celle de
 * V066, bit pour bit.
 *
 * <h2>⚠️ UNE violation de contrainte PAR TEST</h2>
 * <p>En Postgres un statement en échec <b>aborte</b> la transaction
 * ({@code 25P02}), et chaque test roule dans une transaction annulée à la
 * sortie. Deux {@code assertThatThrownBy} dans le même test feraient échouer le
 * second sur « current transaction is aborted », pas sur la contrainte visée.
 */
class JournalCiviqueSchemaIT extends AbstractIntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private JourneyManager journeyManager;

    // ------------------------------------------------------------------------
    // Les trois natures civiques, et l'axe exact de chacune
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Le diagnostic civique ne mesure aucun axe — et il n'est pas un QUICK_DIAGNOSTIC")
    void leDiagnosticCiviqueNeMesureAucunAxe() {
        UUID cycle = insererJourneyCivique();

        inserer(cycle, UUID.randomUUID(), "CIVIC_DIAGNOSTIC", null, null);

        assertThat(compter(cycle, "CIVIC_DIAGNOSTIC")).isEqualTo(1);
    }

    @Test
    @DisplayName("Un examen de thème mesure SA thématique")
    void lExamenDeThemeMesureSaThematique() {
        UUID cycle = insererJourneyCivique();

        inserer(cycle, UUID.randomUUID(), "CIVIC_THEME_EXAM", null, themeCivique("CIV_PRINCIPES"));

        assertThat(compter(cycle, "CIVIC_THEME_EXAM")).isEqualTo(1);
    }

    @Test
    @DisplayName("L'examen civique COMPLET est un fait global : aucun axe")
    void lExamenCompletEstUnFaitGlobal() {
        UUID cycle = insererJourneyCivique();

        inserer(cycle, UUID.randomUUID(), "CIVIC_EXAM", null, null);

        assertThat(compter(cycle, "CIVIC_EXAM")).isEqualTo(1);
    }

    @Test
    @DisplayName("🛑 Un examen de thème SANS thématique : refusé")
    void examenDeThemeSansThematiqueRefuse() {
        UUID cycle = insererJourneyCivique();

        assertThatThrownBy(() ->
                inserer(cycle, UUID.randomUUID(), "CIVIC_THEME_EXAM", null, null))
                .hasMessageContaining("chk_journey_assessment_mesure");
    }

    @Test
    @DisplayName("🛑 Un examen COMPLET porteur d'une thématique : refusé")
    void examenCompletAvecThematiqueRefuse() {
        UUID cycle = insererJourneyCivique();

        assertThatThrownBy(() -> inserer(
                cycle, UUID.randomUUID(), "CIVIC_EXAM", null, themeCivique("CIV_PRINCIPES")))
                .hasMessageContaining("chk_journey_assessment_mesure");
    }

    @Test
    @DisplayName("🛑 Un diagnostic civique porteur d'un axe : refusé")
    void diagnosticCiviqueAvecAxeRefuse() {
        UUID cycle = insererJourneyCivique();

        assertThatThrownBy(() -> inserer(
                cycle, UUID.randomUUID(), "CIVIC_DIAGNOSTIC", null, themeCivique("CIV_PRINCIPES")))
                .hasMessageContaining("chk_journey_assessment_mesure");
    }

    @Test
    @DisplayName("🛑 Une nature TCF ne porte JAMAIS de thématique — la garantie TCF est intacte")
    void uneNatureTcfNePortePasDeThematique() {
        UUID cycle = insererJourneyCivique();

        assertThatThrownBy(() -> inserer(
                cycle, UUID.randomUUID(), "SECTION_EXAM", "TCF_CO", themeCivique("CIV_PRINCIPES")))
                .hasMessageContaining("chk_journey_assessment_mesure");
    }

    @Test
    @DisplayName("🛑 Une nature inconnue de la base est refusée, même écrite correctement en Java")
    void uneNatureInconnueEstRefusee() {
        UUID cycle = insererJourneyCivique();

        assertThatThrownBy(() ->
                inserer(cycle, UUID.randomUUID(), "CIVIC_SERIE", null, null))
                .hasMessageContaining("chk_journey_assessment_kind");
    }

    @Test
    @DisplayName("L'enum Java est le miroir EXACT du CHECK — ni plus, ni moins")
    void lEnumEstLeMiroirDuCheck() {
        String definition = jdbc.queryForObject("""
                SELECT pg_get_constraintdef(oid) FROM pg_constraint
                WHERE conname = 'chk_journey_assessment_kind'
                """, String.class);

        var enBase = new java.util.TreeSet<String>();
        var motif = java.util.regex.Pattern.compile("'([A-Z_]+)'");
        var trouve = motif.matcher(definition == null ? "" : definition);
        while (trouve.find()) enBase.add(trouve.group(1));

        var enJava = java.util.Arrays.stream(JourneyAssessmentKind.values())
                .map(Enum::name)
                .collect(java.util.stream.Collectors.toCollection(java.util.TreeSet::new));

        // 🛑 L'ÉGALITÉ, pas l'inclusion. Une valeur que seul Java connaît serait
        // refusée à l'insertion ; une valeur que seule la base connaît ferait
        // échouer la RELECTURE d'une ligne déjà écrite.
        assertThat(enBase)
                .as("le CHECK (autorité) et l'enum (miroir) disent les mêmes natures")
                .isEqualTo(enJava);
    }

    // ------------------------------------------------------------------------
    // La clé — six lignes pour un attempt, et pas une de plus
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Un examen complet écrit SIX lignes pour un seul attempt : 1 globale + 5 thèmes")
    void unExamenCompletEcritSixLignes() {
        UUID cycle = insererJourneyCivique();
        UUID attempt = UUID.randomUUID();

        inserer(cycle, attempt, "CIVIC_EXAM", null, null);
        for (UUID theme : themesCiviques()) {
            inserer(cycle, attempt, "CIVIC_THEME_EXAM", null, theme);
        }

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE journey_id = ? AND source_assessment_id = ?
                """, Integer.class, cycle, attempt))
                .as("une ligne globale, plus une par thématique")
                .isEqualTo(6);
    }

    @Test
    @DisplayName("🛑 Deux fois la MÊME thématique pour le même attempt : refusé")
    void deuxFoisLaMemeThematiqueRefuse() {
        UUID cycle = insererJourneyCivique();
        UUID attempt = UUID.randomUUID();
        UUID theme = themeCivique("CIV_PRINCIPES");
        inserer(cycle, attempt, "CIVIC_THEME_EXAM", null, theme);

        assertThatThrownBy(() -> inserer(cycle, attempt, "CIVIC_THEME_EXAM", null, theme))
                .hasMessageContaining("uq_journey_assessment_event_par_theme");
    }

    @Test
    @DisplayName("🛑 Côté SANS axe, la clé de V066 est intacte : deux lignes pour un attempt, refusé")
    void laCleDeV066EstIntacteCoteSansAxe() {
        UUID cycle = insererJourneyCivique();
        UUID attempt = UUID.randomUUID();
        inserer(cycle, attempt, "CIVIC_EXAM", null, null);

        assertThatThrownBy(() -> inserer(cycle, attempt, "CIVIC_DIAGNOSTIC", null, null))
                .hasMessageContaining("uq_journey_assessment_event_sans_axe");
    }

    @Test
    @DisplayName("Le repère de R14 existe côté thématique, comme côté épreuve")
    void leRepereDeR14ExisteCoteThematique() {
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM pg_indexes
                WHERE indexname = 'idx_journey_assessment_event_theme'
                """, Integer.class)).isEqualTo(1);
    }

    // ------------------------------------------------------------------------
    // 🛑 Le couplage garde d'idempotence ⇄ écriture en une seule passe
    // ------------------------------------------------------------------------

    /**
     * <b>Ce test existe pour une raison précise, et il n'est pas un doublon des
     * précédents.</b>
     *
     * <p>Le garde de {@code JourneyService} sort par
     * {@code dejaTraitee(userId, module, sourceAssessmentId)}, <b>sans axe</b>.
     * Il reste juste tant que les six lignes d'un examen complet s'écrivent dans
     * la <b>même passe</b>. Écrites au fil de l'eau, la deuxième thématique
     * serait vue comme un <b>rejeu</b> de la première, et les quatre clôtures
     * suivantes seraient perdues <b>en silence</b>.
     *
     * <p>Une note en commentaire ne tient pas ça : elle ne casse rien le jour où
     * quelqu'un change la stratégie d'écriture. Ce test, si — il montre que dès
     * la <b>première</b> ligne écrite, le garde répond « déjà traitée ».
     */
    @Test
    @DisplayName("🛑 Dès la 1re ligne, le garde dit « déjà traitée » — les six s'écrivent en UNE passe")
    void lesSixLignesDoiventSEcrireDansLaMemePasse() {
        UUID candidat = insererUser();
        UUID cycle = insererJourneyCivique(candidat);
        UUID attempt = UUID.randomUUID();

        assertThat(journeyManager.dejaTraitee(candidat, Module.CIVIQUE, attempt))
                .as("avant toute écriture, l'évaluation n'est pas traitée")
                .isFalse();

        inserer(cycle, attempt, "CIVIC_EXAM", null, null);

        assertThat(journeyManager.dejaTraitee(candidat, Module.CIVIQUE, attempt))
                .as("dès la ligne globale, le garde ferme la porte : les cinq clôtures de "
                        + "thématique DOIVENT être écrites dans la même passe")
                .isTrue();
    }

    // ------------------------------------------------------------------------

    private void inserer(UUID cycle, UUID source, String nature, String epreuve, UUID theme) {
        jdbc.update("""
                INSERT INTO journey_assessment_event
                    (id, journey_id, source_assessment_id, assessment_kind, exam_type,
                     theme_id, completed_at)
                VALUES (gen_random_uuid(), CAST(? AS uuid), CAST(? AS uuid), ?,
                        CAST(? AS varchar), CAST(? AS uuid), ?)
                """, cycle, source, nature, epreuve, theme, java.sql.Timestamp.from(Instant.now()));
    }

    private Integer compter(UUID cycle, String nature) {
        return jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE journey_id = ? AND assessment_kind = ?
                """, Integer.class, cycle, nature);
    }

    private UUID insererUser() {
        var id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO users (id, email, password_hash, role, auth_provider, created_at)
                VALUES (?, ?, 'x', 'USER', 'LOCAL', now())
                """, id, "journal-civique-" + id + "@test.fr");
        return id;
    }

    private UUID insererJourneyCivique() {
        return insererJourneyCivique(insererUser());
    }

    private UUID insererJourneyCivique(UUID candidat) {
        var id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure, next_position)
                VALUES (?, ?, 'CIVIQUE', 'EN_COURS', 'CR', 1)
                """, id, candidat);
        return id;
    }

    private UUID themeCivique(String code) {
        return jdbc.queryForObject("SELECT id FROM themes WHERE code = ?", UUID.class, code);
    }

    private List<UUID> themesCiviques() {
        List<UUID> themes = jdbc.queryForList(
                "SELECT id FROM themes WHERE module = 'CIVIQUE' ORDER BY display_order",
                UUID.class);
        assertThat(themes).as("les cinq thématiques officielles").hasSize(5);
        return themes;
    }
}
