package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.CivicObservationService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>UN PARCOURS CIVIQUE, JOUÉ DE BOUT EN BOUT</b> — le livrable de preuve de la
 * lancée 2 (P8.4 + P8.5).
 *
 * <p>Il suit un candidat du premier diagnostic à l'historisation de son premier
 * cycle, en passant par tout ce que le moteur sait faire :
 *
 * <ol>
 *   <li><b>l'amorce</b> — les thématiques prioritaires peuplées d'unités
 *       officielles, les autres en « Évaluer mon niveau » (spec §2) ;</li>
 *   <li><b>le travail d'une unité</b> — deux séries réussies closent l'étape
 *       (R2 / D-16, au grain de l'unité) ;</li>
 *   <li><b>le verrou du bloc</b> — l'examen d'un bloc reste verrouillé tant
 *       qu'une unité y est ouverte (D-15) ;</li>
 *   <li><b>l'examen de thème</b> — il clôt l'étape d'examen du bloc débloqué, et
 *       lui seul (R1) ;</li>
 *   <li><b>l'examen complet</b> — il clôt tous les blocs débloqués et écrit
 *       <b>six lignes</b> de journal (D-51) ;</li>
 *   <li><b>la fin de cycle</b> — historisation, score de sortie recopié, cycle
 *       suivant ré-amorcé, et <b>aucun</b> cycle en attente (D-36).</li>
 * </ol>
 *
 * <p>⚠️ <b>Non transactionnel</b> : le moteur écrit en {@code REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ParcoursCiviqueDeBoutEnBoutIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyCycleService cycleService;
    @Autowired private CivicObservationService observationService;
    @Autowired private CivicDiagnosticService diagnosticService;
    @Autowired private TcfJourneyConfig config;
    @Autowired private JourneySerieVerdict verdict;
    @Autowired private com.sejourfr.app.manager.JourneyStepManager stepManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private TestData data;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    @Test
    @DisplayName("Un candidat civique : diagnostic → unités → examen de thème → examen complet → "
            + "cycle historisé")
    void leParcoursCiviqueEntier() {
        User user = candidat();
        diagnosticTermine(user);

        // ------------------------------------------------------------------ 1
        // L'AMORCE : des blocs peuplés, et les cinq thématiques couvertes.
        // ------------------------------------------------------------------
        Journey cycle = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        assertThat(cycle.getTargetProcedure()).isEqualTo(TargetProcedure.NAT);
        assertThat(cycle.getTargetLevel())
                .as("un cycle porte UN objectif, du type de son module")
                .isNull();

        List<Map<String, Object>> etapes = etapes(cycle);
        assertThat(etapes).as("le cycle n'est jamais vide").isNotEmpty();
        assertThat(codesDeBloc(etapes)).as("les cinq thématiques de l'arrêté").hasSize(5);
        assertThat(etapes).anyMatch(e -> "TRAIN_SKILL".equals(e.get("type")));

        String bloc = premierBlocPeuple(etapes);
        List<UUID> unites = unitesOuvertes(cycle, bloc);
        assertThat(unites).as("le bloc prioritaire porte ses unités").isNotEmpty();

        // ------------------------------------------------------------------ 2
        // L'EXAMEN DU BLOC EST VERROUILLÉ tant qu'une unité y est ouverte.
        // ------------------------------------------------------------------
        assertThat(examenDuBlocEstVerrouille(user, bloc))
                .as("D-15 : l'examen attend que le bloc soit fini")
                .isTrue();

        // ------------------------------------------------------------------ 3
        // LE TRAVAIL : deux séries réussies par unité closent chaque étape.
        // ------------------------------------------------------------------
        for (UUID unite : unites) {
            toutesLesCartesReussies(user, cycle, unite);
            journeyService.onTrainingProgressCivique(user.getId(), Set.of(unite));
        }
        assertThat(unitesOuvertes(cycle, bloc))
                .as("R2 au grain de l'unité : tout le bloc est travaillé")
                .isEmpty();

        // ------------------------------------------------------------------ 4
        // L'EXAMEN DE THÈME clôt l'étape de CE bloc, et lui seul (R1).
        // ------------------------------------------------------------------
        UUID theme = jdbc.queryForObject(
                "SELECT id FROM themes WHERE code = ?", UUID.class, bloc);
        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.examenDeTheme(UUID.randomUUID(), theme, Instant.now()));

        assertThat(etapesOuvertes(cycle, bloc)).as("le bloc est fermé").isZero();
        assertThat(etapesOuvertes(cycle, null)).as("les autres blocs attendent").isPositive();

        // ------------------------------------------------------------------ 5
        // L'EXAMEN COMPLET clôt tout ce qui était débloqué, et écrit SIX lignes.
        // ------------------------------------------------------------------
        // ⚠️ Le diagnostic a peuplé PLUSIEURS blocs : R1 ne valide que les
        // blocs débloqués, donc il faut finir le travail dû avant que l'examen
        // complet puisse clore quoi que ce soit. C'est la règle, pas un détour
        // de test — et c'est ce qui rend ce parcours réaliste.
        for (UUID unite : toutesLesUnitesOuvertes(cycle)) {
            toutesLesCartesReussies(user, cycle, unite);
            journeyService.onTrainingProgressCivique(user.getId(), Set.of(unite));
        }
        assertThat(toutesLesUnitesOuvertes(cycle)).isEmpty();

        UUID examenComplet = examenCompletPasse(user, 29);
        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.examenCivique(examenComplet, Instant.now()));

        assertThat(etapesOuvertes(cycle, null)).as("plus rien d'ouvert").isZero();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey_assessment_event
                WHERE journey_id = ? AND source_assessment_id = ?
                """, Integer.class, cycle.getId(), examenComplet))
                // 🛑 CINQ, ET PAS SIX, et c'est la règle qui le dit : une
                // ligne globale + une par thématique que CET examen a validée.
                // La première thématique avait déjà été close par son examen de
                // thème — elle n'est pas revalidée. Le journal dit ce qui a été
                // VALIDÉ, pas ce qui a été passé (A73).
                .as("une ligne globale + une par thématique validée par CET examen")
                .isEqualTo(5);

        // ------------------------------------------------------------------ 6
        // LA FIN DE CYCLE : historisation, score recopié, cycle ré-amorcé.
        // ------------------------------------------------------------------
        cycleService.actualiser(user.getId(), Module.CIVIQUE);

        Map<String, Object> historise = jdbc.queryForMap(
                "SELECT status, exit_score, historise_at FROM journey WHERE id = ?",
                cycle.getId());
        assertThat(historise.get("status")).isEqualTo("HISTORISE");
        assertThat(historise.get("historise_at")).isNotNull();
        // 🛑 Le score de sortie est le score que le candidat a VU à la fin de
        // son examen complet. Recopié, jamais recalculé.
        assertThat(historise.get("exit_score")).isEqualTo(29);

        Journey suivant = journeyService
                .getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        assertThat(suivant.getId()).isNotEqualTo(cycle.getId());
        assertThat(etapes(suivant)).as("le cycle suivant est amorcé, pas vide").isNotEmpty();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM journey
                WHERE user_id = ? AND module = 'CIVIQUE' AND status = 'EN_ATTENTE'
                """, Integer.class, user.getId()))
                .as("aucun cycle en attente civique : les priorités sont dérivées (D-36)")
                .isZero();
    }

    // ------------------------------------------------------------------------

    private List<Map<String, Object>> etapes(Journey cycle) {
        return jdbc.queryForList("""
                SELECT s.type, s.purpose, s.closed_at, s.official_unit_id, t.code AS bloc
                FROM journey_step s
                LEFT JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ?
                ORDER BY s.position
                """, cycle.getId());
    }

    private static List<String> codesDeBloc(List<Map<String, Object>> etapes) {
        return etapes.stream()
                .map(e -> (String) e.get("bloc"))
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
    }

    private static String premierBlocPeuple(List<Map<String, Object>> etapes) {
        return etapes.stream()
                .filter(e -> "TRAIN_SKILL".equals(e.get("type")))
                .map(e -> (String) e.get("bloc"))
                .findFirst()
                .orElseThrow();
    }

    private List<UUID> unitesOuvertes(Journey cycle, String bloc) {
        return jdbc.queryForList("""
                SELECT s.official_unit_id FROM journey_step s
                JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ? AND t.code = ? AND s.type = 'TRAIN_SKILL'
                  AND s.closed_at IS NULL
                """, UUID.class, cycle.getId(), bloc);
    }

    private List<UUID> toutesLesUnitesOuvertes(Journey cycle) {
        return jdbc.queryForList("""
                SELECT official_unit_id FROM journey_step
                WHERE journey_id = ? AND type = 'TRAIN_SKILL' AND closed_at IS NULL
                """, UUID.class, cycle.getId());
    }

    private Integer etapesOuvertes(Journey cycle, String bloc) {
        if (bloc == null) {
            return jdbc.queryForObject(
                    "SELECT count(*) FROM journey_step WHERE journey_id = ? AND closed_at IS NULL",
                    Integer.class, cycle.getId());
        }
        return jdbc.queryForObject("""
                SELECT count(*) FROM journey_step s
                JOIN themes t ON t.id = s.theme_id
                WHERE s.journey_id = ? AND t.code = ? AND s.closed_at IS NULL
                """, Integer.class, cycle.getId(), bloc);
    }

    /** Le `locked` servi de l'examen de ce bloc — la lecture que l'écran fait. */
    private boolean examenDuBlocEstVerrouille(User user, String bloc) {
        return journeyService.lire(user.getId(), Module.CIVIQUE).blocs().stream()
                .filter(b -> bloc.equals(b.bloc().code()))
                .findFirst()
                .map(b -> b.exam() != null && b.exam().locked())
                .orElse(false);
    }

    private static List<CivicObservationService.ReponseCivique> serieReussie(UUID unite) {
        return IntStream.range(0, 10)
                .mapToObj(i -> new CivicObservationService.ReponseCivique(unite, true, true))
                .toList();
    }

    private UUID examenCompletPasse(User user, int score) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO attempts (id, user_id, type, mode, module, epreuve, status,
                                      total_questions, score, started_at, finished_at)
                VALUES (?, ?, 'MOCK_EXAM', 'EXAMEN', 'CIVIQUE', 'CIVIQUE', 'TERMINE', 40, ?,
                        now(), now())
                """, id, user.getId(), score);
        return id;
    }

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private CivicDiagnosticSession diagnosticTermine(User user) {
        CivicDiagnosticSession session = diagnosticService.ouvrir(user.getId());
        for (UUID aq : jdbc.queryForList("""
                SELECT id FROM attempt_questions WHERE attempt_id = ? ORDER BY position
                """, UUID.class, session.getAttempt().getId())) {
            jdbc.update("""
                    INSERT INTO answers (id, attempt_question_id, user_id, selected_choice_ids,
                                         is_correct, answered_at)
                    SELECT gen_random_uuid(), ?, a.user_id, '[]'::jsonb, false, now()
                    FROM attempt_questions aq JOIN attempts a ON a.id = aq.attempt_id
                    WHERE aq.id = ?
                    """, aq, aq);
        }
        diagnosticService.cloturer(user.getId(), session.getId());
        entityManager.clear();
        return session;
    }

    /**
     * <b>Les deux cartes de l'etape d'une unite, reussies</b> — ce que
     * {@code JourneyStepDetailService} ecrit quand le candidat joue ses series.
     *
     * <p>🛑 On pose un <b>score</b>, jamais un verdict : « reussie » se relit
     * ({@code JourneySerieVerdict}), et c'est la meme fonction que celle qui
     * clot l'etape.
     */
    private void toutesLesCartesReussies(User user, Journey cycle, UUID unite) {
        com.sejourfr.app.entity.JourneyStep etape = stepManager.findAll(cycle.getId()).stream()
                .filter(step -> unite.equals(step.uniteId()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucune etape pour l'unite " + unite));
        int seuil = verdict.seuilReussite(Module.CIVIQUE);
        for (int carte = 1; carte <= config.trainSeriesQuota(); carte++) {
            data.serieDEtape(etape, carte, user, Module.CIVIQUE, seuil);
        }
    }

}
