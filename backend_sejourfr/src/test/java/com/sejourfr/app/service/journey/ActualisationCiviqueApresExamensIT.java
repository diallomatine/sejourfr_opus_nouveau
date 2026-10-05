package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le cycle civique SUIVANT se nourrit des examens blancs</b> (2026-10-05,
 * bug remonte par le proprietaire, A177).
 *
 * <p>Constat en base : un compte gratuit sans diagnostic civique passe le cycle
 * d'examens (D-69 ter : un examen blanc par theme — 19, 4, 5, 10 et 17 sur 20),
 * clique « Actualiser mon plan », et recoit un cycle de… cinq examens blancs.
 * Cause : {@code CivicPlanService.ordrePourLeCycle} ne batissait rien sans
 * diagnostic termine, donc les examens n'avaient aucun effet sur la suite.
 *
 * <p>Pendant civique d'{@code ActualisationApresExamensIT} (TCF, D-70).
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ActualisationCiviqueApresExamensIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyCycleService cycleService;
    @Autowired private TcfJourneyConfig config;
    @Autowired private ThemeManager themeManager;
    @Autowired private AttemptManager attemptManager;
    @Autowired private QuestionManager questionManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    @Test
    @DisplayName("Examens faibles ⇒ le cycle suivant porte des unites a travailler dans CES "
            + "themes (≤ 3), les themes solides gardent leur seul examen blanc")
    void lesExamensFaiblesPeuplentLeCycleSuivant() {
        User user = candidatCivique();
        Journey premier = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        assertThat(themes).hasSize(5);

        // Trois themes rates (4/20), deux reussis (18/20) — la forme du constat.
        Map<UUID, Examen> examens = new LinkedHashMap<>();
        for (int i = 0; i < themes.size(); i++) {
            Theme theme = themes.get(i);
            examens.put(theme.getId(), examenDeThemePasse(user, theme, i < 3 ? 4 : 18));
        }
        assertThat(etapesOuvertes(premier.getId())).as("le cycle d'examens est fini").isZero();

        Integer annonce = journeyService.lire(user.getId(), Module.CIVIQUE)
                .cycle().prioritesCycleSuivant();
        cycleService.actualiser(user.getId(), Module.CIVIQUE);
        Journey suivant = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        assertThat(suivant.getId()).isNotEqualTo(premier.getId());

        for (int i = 0; i < themes.size(); i++) {
            Theme theme = themes.get(i);
            List<String> unites = jdbc.queryForList("""
                    SELECT u.code FROM journey_step s
                    JOIN civic_official_units u ON u.id = s.official_unit_id
                    WHERE s.journey_id = ? AND s.theme_id = ? AND s.type = 'TRAIN_SKILL'
                    ORDER BY s.position
                    """, String.class, suivant.getId(), theme.getId());
            int examensDuBloc = jdbc.queryForObject("""
                    SELECT count(*) FROM journey_step
                    WHERE journey_id = ? AND theme_id = ? AND type = 'SECTION_EXAM'
                    """, Integer.class, suivant.getId(), theme.getId());
            assertThat(examensDuBloc).as("un seul examen par bloc").isEqualTo(1);

            if (i < 3) {
                Examen examen = examens.get(theme.getId());
                assertThat(unites).as("theme rate %s : des points a travailler", theme.getCode())
                        .isNotEmpty()
                        .hasSizeLessThanOrEqualTo(config.maxPrioritiesPerLot());
                // Le plus urgent est un point RATE a l'examen, pas un jamais-vu.
                assertThat(examen.unitesRatees()).contains(unites.getFirst());
                // La source journalisee est l'examen qui a mesure ce theme.
                assertThat(jdbc.queryForList("""
                        SELECT source_assessment_id FROM journey_lot
                        WHERE journey_id = ? AND theme_id = ?
                        """, UUID.class, suivant.getId(), theme.getId()))
                        .containsExactly(examen.id());
            } else {
                assertThat(unites).as("theme reussi %s : son examen blanc seul", theme.getCode())
                        .isEmpty();
            }
        }

        // D-67 : le nombre annonce sous « Actualiser » est ce qui a ete pose.
        assertThat(annonce).isPositive();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step
                WHERE journey_id = ? AND type = 'TRAIN_SKILL'
                """, Integer.class, suivant.getId())).isEqualTo(annonce);
    }

    @Test
    @DisplayName("Tous les examens reussis ⇒ aucune priorite inventee : cinq examens blancs")
    void examensReussisNeFabriquentRien() {
        User user = candidatCivique();
        journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        for (Theme theme : themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            examenDeThemePasse(user, theme, 18);
        }

        assertThat(journeyService.lire(user.getId(), Module.CIVIQUE)
                .cycle().prioritesCycleSuivant()).isZero();
        cycleService.actualiser(user.getId(), Module.CIVIQUE);
        Journey suivant = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step WHERE journey_id = ? AND type = 'TRAIN_SKILL'
                """, Integer.class, suivant.getId())).isZero();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step WHERE journey_id = ? AND type = 'SECTION_EXAM'
                """, Integer.class, suivant.getId())).isEqualTo(5);
    }

    @Test
    @DisplayName("D-69 ter intact : des examens passes AVANT le premier cycle ne le peuplent pas")
    void lePremierCycleResteUnCycleDExamens() {
        User user = candidatCivique();
        for (Theme theme : themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            examenDeThemePasse(user, theme, 4, false);
        }

        Journey premier = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();

        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_step WHERE journey_id = ? AND type = 'TRAIN_SKILL'
                """, Integer.class, premier.getId())).isZero();
        assertThat(etapesOuvertes(premier.getId())).isEqualTo(5);
    }

    // ------------------------------------------------------------------------

    /** Un examen de theme passe, et les unites des questions ratees. */
    private record Examen(UUID id, Set<String> unitesRatees) {}

    private Examen examenDeThemePasse(User user, Theme theme, int bonnes) {
        return examenDeThemePasse(user, theme, bonnes, true);
    }

    /**
     * Un examen blanc de theme TERMINE sur 20 questions SEEDEES et taguees
     * (notion rattachee a une unite officielle) — sans elles, aucune unite ne
     * peut etre designee. Signale au parcours si {@code signaler}.
     */
    private Examen examenDeThemePasse(User user, Theme theme, int bonnes, boolean signaler) {
        List<Map<String, Object>> questions = jdbc.queryForList("""
                SELECT q.id, u.code AS unite
                FROM questions q
                JOIN civic_notions n ON n.id = q.civic_notion_id
                JOIN civic_official_units u ON u.id = n.official_unit_id
                WHERE q.theme_id = ? AND q.module = 'CIVIQUE'
                  AND q.is_active = true AND q.status = 'ACTIVE'
                ORDER BY q.id
                LIMIT 20
                """, theme.getId());
        assertThat(questions).as("banque seedee du theme %s", theme.getCode()).hasSize(20);

        Instant fin = Instant.now();
        Attempt examen = data.attempt(user);
        examen.setType(AttemptType.MOCK_EXAM);
        examen.setMode(AttemptMode.EXAMEN);
        examen.setModule(Module.CIVIQUE);
        examen.setEpreuve(EpreuveType.CIVIQUE);
        examen.setStatus(AttemptStatus.TERMINE);
        examen.setLotThemeId(theme.getId());
        examen.setTotalQuestions(20);
        examen.setPassThreshold(16);
        examen.setSlotNumber(1);
        examen.setStartedAt(fin.minus(10, ChronoUnit.MINUTES));
        examen.setFinishedAt(fin);
        examen.setScore(bonnes);
        examen = attemptManager.save(examen);

        Set<String> ratees = new HashSet<>();
        for (int i = 0; i < questions.size(); i++) {
            UUID questionId = (UUID) questions.get(i).get("id");
            boolean juste = i < bonnes;
            data.answer(data.attemptQuestion(examen,
                    questionManager.findById(questionId).orElseThrow()), juste);
            if (!juste) ratees.add((String) questions.get(i).get("unite"));
        }
        if (signaler) {
            journeyService.onAssessmentCompleted(user.getId(),
                    JourneyEvaluation.examenDeTheme(examen.getId(), theme.getId(), fin));
        }
        return new Examen(examen.getId(), ratees);
    }

    private int etapesOuvertes(UUID journeyId) {
        return jdbc.queryForObject("""
                SELECT count(*) FROM journey_step WHERE journey_id = ? AND closed_at IS NULL
                """, Integer.class, journeyId);
    }

    private User candidatCivique() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }
}
