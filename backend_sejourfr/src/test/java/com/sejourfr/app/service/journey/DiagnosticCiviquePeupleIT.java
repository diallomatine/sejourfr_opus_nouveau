package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.attempt.AttemptInteractionService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>🛑 LE DIAGNOSTIC CIVIQUE PEUPLE, IL NE CLOT PAS</b> — arbitrage du
 * proprietaire (2026-09-20), pendant civique de <b>R11</b>.
 *
 * <h2>Le defaut, mesure en base avant d'etre corrige</h2>
 * <p>Un diagnostic civique est un {@code MOCK_EXAM} <b>sans</b>
 * {@code lot_theme_id} : {@code AttemptInteractionService} n'avait que deux
 * branches et le prenait donc pour un <b>examen blanc complet</b>. ⟦SQL⟧ sur la
 * base de dev, un candidat a <b>11/40</b> avait ses <b>cinq</b> etapes
 * {@code SECTION_EXAM} closes en {@code SATISFIED_BY_ASSESSMENT}, un journal de
 * six lignes {@code CIVIC_EXAM} + {@code CIVIC_THEME_EXAM}, <b>zero</b>
 * {@code journey_lot} et <b>zero</b> {@code TRAIN_SKILL} — donc l'ecran « les
 * cinq thematiques TERMINÉ », avec « Actualiser mon plan » pour seule issue.
 *
 * <p>{@code JourneyEvaluation.diagnosticCivique(...)} existait depuis D-51 et
 * <b>n'avait aucun appelant</b>.
 *
 * <h2>Ce que ces tests figent</h2>
 * <ol>
 *   <li>le <b>scenario mesure</b> : un cycle deja amorce « les cinq a evaluer »,
 *       puis un diagnostic qui se termine ⇒ des blocs <b>peuples</b>, et
 *       <b>aucune</b> etape d'examen close ;</li>
 *   <li>le <b>journal dit la verite</b> : une seule ligne, {@code CIVIC_DIAGNOSTIC},
 *       portant l'id de la <b>session</b> (A08) ;</li>
 *   <li>🛑 l'<b>examen COMPLET</b>, lui, clot toujours — <b>D-51 ne bouge
 *       pas</b> ;</li>
 *   <li>l'<b>examen de theme</b> n'est pas touche non plus ;</li>
 *   <li>le cycle <b>cesse d'etre un cycle de mesure</b> (A33), donc
 *       {@code examenCompletPossible} redevient vrai (A36).</li>
 * </ol>
 *
 * <p>⚠️ <b>Les trois natures passent par le VRAI chemin</b>
 * ({@code AttemptInteractionService.finish}) et non par un appel direct au
 * moteur : c'est l'<b>aiguillage</b> qui etait faux, pas le moteur. Un test qui
 * appellerait {@code onAssessmentCompleted} a la main serait reste vert sur le
 * defaut mesure.
 *
 * <p>⚠️ <b>Non transactionnel</b> (A14) : le moteur ecrit en
 * {@code REQUIRES_NEW}, et une transaction de test l'envelopperait.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class DiagnosticCiviquePeupleIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private CivicDiagnosticService diagnosticService;
    @Autowired private AttemptInteractionService attemptInteraction;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    // ------------------------------------------------------------------------
    // 1 — le scenario mesure
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Cycle amorce « les cinq a evaluer » : le diagnostic PEUPLE les blocs "
            + "et ne clot AUCUN examen")
    void leDiagnosticPeupleEtNeClotRien() {
        User user = candidatCivique();
        Journey cycle = cycleDeMesureAmorce(user);

        CivicDiagnosticSession session = diagnosticPasseEtTermine(user);

        // 🛑 LE FAIT CENTRAL : des unites sont posees. C'est ce qui etait perdu
        // -- la priorite detectee n'entrait nulle part.
        assertThat(unitesOuvertes(cycle))
                .as("les blocs prioritaires portent leurs unites")
                .isNotEmpty();

        // 🛑 ET AUCUNE ETAPE D'EXAMEN N'EST CLOSE : le diagnostic ne mesure
        // aucune thematique, il ne valide donc rien.
        assertThat(etapesCloses(cycle))
                .as("un diagnostic ne clot aucune etape : il peuple")
                .isZero();

        // La regle, pas le resultat (D-53) : on n'impose ni QUELLES thematiques
        // le moteur a retenues, ni combien -- seulement qu'un bloc peuple porte
        // exactement UN examen ouvert, jamais deux.
        for (String bloc : blocsAvecTravail(cycle)) {
            assertThat(examensOuvertsDuBloc(cycle, bloc))
                    .as("le bloc %s porte un seul examen ouvert", bloc)
                    .isEqualTo(1);
        }

        // Les cinq thematiques restent couvertes : un cycle civique n'est jamais
        // partiel (A65).
        assertThat(blocsCouverts(cycle)).hasSize(5);
        assertThat(session.getId()).isNotNull();
    }

    @Test
    @DisplayName("Aucun cycle encore : celui que le diagnostic fait naitre est peuple "
            + "dans la meme passe")
    void leCycleNeAPeineNaitDejaPeuple() {
        User user = candidatCivique();

        diagnosticPasseEtTermine(user);

        Journey cycle = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        // 🛑 Le cycle naît « les cinq a evaluer » (la session est encore
        // IN_PROGRESS quand `getOrCreate` l'amorce), puis le MEME appel le
        // peuple. Sans cela, un candidat qui n'a jamais ouvert son Plan aurait
        // eu un cycle de mesure pour tout resultat de diagnostic.
        assertThat(unitesOuvertes(cycle)).isNotEmpty();
        assertThat(etapesCloses(cycle)).isZero();
        assertThat(blocsCouverts(cycle)).hasSize(5);
    }

    // ------------------------------------------------------------------------
    // 2 — le journal dit la verite
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Le journal : UNE ligne CIVIC_DIAGNOSTIC portant l'id de la SESSION, "
            + "et pas les six lignes d'un examen complet")
    void leJournalPorteLaSessionEtUneSeuleLigne() {
        User user = candidatCivique();
        Journey cycle = cycleDeMesureAmorce(user);

        CivicDiagnosticSession session = diagnosticPasseEtTermine(user);

        List<Map<String, Object>> journal = jdbc.queryForList("""
                SELECT assessment_kind, source_assessment_id, exam_type, theme_id
                FROM journey_assessment_event WHERE journey_id = ?
                """, cycle.getId());

        assertThat(journal).as("une evaluation, une ligne").hasSize(1);
        Map<String, Object> ligne = journal.getFirst();
        assertThat(ligne.get("assessment_kind")).isEqualTo("CIVIC_DIAGNOSTIC");
        // 🛑 L'IDENTITE EST CELLE DE LA SESSION, pas celle de l'attempt : la
        // nature dit de quelle table vient l'identifiant (A08).
        assertThat(ligne.get("source_assessment_id")).isEqualTo(session.getId());
        assertThat(ligne.get("source_assessment_id"))
                .isNotEqualTo(attemptDuDiagnostic(session));
        // `chk_journey_assessment_mesure` (V071) : un CIVIC_DIAGNOSTIC ne porte
        // aucun axe. Verifie EN BASE, pas au vert des tests (DETTE-M1).
        assertThat(ligne.get("exam_type")).isNull();
        assertThat(ligne.get("theme_id")).isNull();
    }

    // ------------------------------------------------------------------------
    // 3 — 🛑 CE QU'IL NE FAUT PAS CASSER : l'examen COMPLET clot toujours
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("D-51 ne bouge pas : l'examen civique COMPLET clot les cinq blocs "
            + "et ecrit ses SIX lignes")
    void lExamenCompletClotToujours() {
        User user = candidatCivique();
        Journey cycle = cycleDeMesureAmorce(user);

        UUID examen = examenCiviquePasse(user, null);

        assertThat(etapesOuvertes(cycle))
                .as("le cycle de mesure est ferme par l'examen complet (D-51)")
                .isZero();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE journey_id = ? AND source_assessment_id = ?
                """, Integer.class, cycle.getId(), examen))
                .as("une ligne globale + une par thematique validee")
                .isEqualTo(6);
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step
                WHERE journey_id = ? AND resolution = 'SATISFIED_BY_ASSESSMENT'
                """, Integer.class, cycle.getId()))
                .isEqualTo(5);
    }

    // ------------------------------------------------------------------------
    // 4 — l'examen de theme n'est pas touche non plus
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("L'examen de theme clot SON bloc, et lui seul")
    void lExamenDeThemeClotSonBloc() {
        User user = candidatCivique();
        Journey cycle = cycleDeMesureAmorce(user);
        UUID theme = jdbc.queryForObject("""
                SELECT id FROM themes WHERE module = 'CIVIQUE' ORDER BY display_order LIMIT 1
                """, UUID.class);

        UUID examen = examenCiviquePasse(user, theme);

        assertThat(jdbc.queryForList("""
                SELECT assessment_kind, theme_id FROM journey_assessment_event
                WHERE journey_id = ? AND source_assessment_id = ?
                """, cycle.getId(), examen))
                .as("l'evaluation EST la ligne de thematique, elle n'est pas reecrite (A73)")
                .singleElement()
                .satisfies(ligne -> {
                    assertThat(ligne.get("assessment_kind")).isEqualTo("CIVIC_THEME_EXAM");
                    assertThat(ligne.get("theme_id")).isEqualTo(theme);
                });
        assertThat(etapesCloses(cycle)).as("un bloc ferme, quatre ouverts").isEqualTo(1);
        assertThat(etapesOuvertes(cycle)).isEqualTo(4);
    }

    // ------------------------------------------------------------------------
    // 5 — le cycle cesse d'etre un cycle de mesure
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Le cycle de mesure redevient un cycle de travail : "
            + "l'ecran retrouve son examen complet")
    void leCycleCesseDEtreUnCycleDeMesure() {
        User user = candidatCivique();
        cycleDeMesureAmorce(user);

        // A33 : cinq blocs ne portant que leur examen ⇒ cycle de MESURE, donc
        // A36 : `examenCompletPossible = !cycleDeMesure` vaut faux.
        assertThat(journeyService.lire(user.getId(), Module.CIVIQUE).cycle().cycleDeMesure())
                .as("avant le diagnostic : un cycle de mesure")
                .isTrue();

        diagnosticPasseEtTermine(user);

        assertThat(journeyService.lire(user.getId(), Module.CIVIQUE).cycle().cycleDeMesure())
                .as("le diagnostic a peuple : ce n'est plus un cycle de mesure")
                .isFalse();
    }

    // ------------------------------------------------------------------------
    // Le referentiel est EMPRUNTE, jamais cree (A14)
    // ------------------------------------------------------------------------

    private User candidatCivique() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /** Le cycle du candidat AVANT tout diagnostic : les cinq a evaluer (A65). */
    private Journey cycleDeMesureAmorce(User user) {
        Journey cycle = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        assertThat(etapesOuvertes(cycle))
                .as("la precondition du scenario mesure : cinq examens, rien d'autre")
                .isEqualTo(5);
        assertThat(unitesOuvertes(cycle)).isEmpty();
        return cycle;
    }

    /**
     * Le diagnostic, passe par le <b>vrai</b> chemin : les 40 questions
     * repondues, puis {@code POST /api/attempts/{id}/finish}.
     *
     * <p>⚠️ 🛑 <b>La session est encore {@code IN_PROGRESS} a cet instant</b>, et
     * c'est le cas reel : elle ne passe a {@code COMPLETED} qu'au
     * {@code POST /civic-diagnostics/{id}/result}, <b>apres</b> le {@code finish}.
     * Un test qui la cloturerait d'abord aurait verifie un ordre que la
     * production ne produit jamais.
     */
    private CivicDiagnosticSession diagnosticPasseEtTermine(User user) {
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        UUID attempt = attemptDuDiagnostic(session);
        repondreFaux(attempt);
        attemptInteraction.finish(user.getId(), attempt);
        return session;
    }

    /**
     * Un examen civique <b>reel</b> : les memes questions que le diagnostic,
     * mais sur un attempt <b>sans</b> {@code civic_diagnostic_id}. C'est
     * exactement ce que l'aiguillage doit distinguer.
     *
     * @param theme la thematique d'un examen de theme, ou {@code null} pour
     *              l'examen COMPLET.
     */
    private UUID examenCiviquePasse(User user, UUID theme) {
        UUID examen = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO attempts (id, user_id, type, mode, module, epreuve, status,
                                      total_questions, started_at, lot_theme_id)
                VALUES (?, ?, 'MOCK_EXAM', 'EXAMEN', 'CIVIQUE', 'CIVIQUE', 'EN_COURS', 40,
                        now(), ?)
                """, examen, user.getId(), theme);
        // 🛑 Le referentiel est EMPRUNTE, jamais cree (A14) : les questions
        // civiques seedees par Flyway suffisent, et l'examen n'a pas besoin
        // d'etre compose « pour de vrai » — ce qu'on fige ici est l'AIGUILLAGE,
        // pas la composition.
        jdbc.update("""
                INSERT INTO attempt_questions (id, attempt_id, question_id, position)
                SELECT gen_random_uuid(), ?, q.id, row_number() OVER (ORDER BY q.id) - 1
                FROM questions q JOIN themes t ON t.id = q.theme_id
                WHERE t.module = 'CIVIQUE' AND q.is_active
                LIMIT 40
                """, examen);

        repondreFaux(examen);
        attemptInteraction.finish(user.getId(), examen);
        return examen;
    }

    private UUID attemptDuDiagnostic(CivicDiagnosticSession session) {
        return jdbc.queryForObject(
                "SELECT attempt_id FROM civic_diagnostic_sessions WHERE id = ?",
                UUID.class, session.getId());
    }

    /** Toutes les questions repondues, toutes fausses : de quoi produire des priorites. */
    private void repondreFaux(UUID attempt) {
        jdbc.update("""
                INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                     is_correct, answered_at)
                SELECT gen_random_uuid(), aq.id, a.user_id, '[]'::jsonb, false, now()
                FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                WHERE aq.attempt_id = ?
                """, attempt);
    }

    // ------------------------------------------------------------------------

    private Integer etapesOuvertes(Journey cycle) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM journey_step WHERE journey_id = ? AND closed_at IS NULL",
                Integer.class, cycle.getId());
    }

    private Integer etapesCloses(Journey cycle) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM journey_step WHERE journey_id = ? AND closed_at IS NOT NULL",
                Integer.class, cycle.getId());
    }

    private List<UUID> unitesOuvertes(Journey cycle) {
        return jdbc.queryForList("""
                SELECT official_unit_id FROM journey_step
                WHERE journey_id = ? AND type = 'TRAIN_SKILL' AND closed_at IS NULL
                """, UUID.class, cycle.getId());
    }

    private List<String> blocsAvecTravail(Journey cycle) {
        return jdbc.queryForList("""
                SELECT DISTINCT t.code FROM journey_step s JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ? AND s.type = 'TRAIN_SKILL'
                """, String.class, cycle.getId());
    }

    private List<String> blocsCouverts(Journey cycle) {
        return jdbc.queryForList("""
                SELECT DISTINCT t.code FROM journey_step s JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ?
                """, String.class, cycle.getId());
    }

    private Integer examensOuvertsDuBloc(Journey cycle, String bloc) {
        return jdbc.queryForObject("""
                SELECT count(*) FROM journey_step s JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ? AND t.code = ? AND s.type = 'SECTION_EXAM'
                  AND s.closed_at IS NULL
                """, Integer.class, cycle.getId(), bloc);
    }
}
