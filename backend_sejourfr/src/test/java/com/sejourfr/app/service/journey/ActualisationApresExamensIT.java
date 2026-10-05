package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
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
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le scenario de prod du 2026-10-03</b> ({@code user@sejourfr.fr}) : un cycle
 * d'examens fini, « Actualiser mon plan », et un cycle suivant dont les blocs CO
 * et CE etaient VIDES — affiches « termines » sans qu'aucune etape n'y ait ete
 * faite.
 *
 * <p>Non transactionnel : le parcours ecrit en {@link Propagation#REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ActualisationApresExamensIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyCycleService cycleService;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        // 🛑 Ce test n'est pas transactionnel : les items QCM fabriques par
        // `examenQcmTcfPasse` (une thematique chacun) survivraient a la classe
        // et fausseraient les tests qui comptent les cinq thematiques civiques.
        List<UUID> themes = candidats.isEmpty() ? List.of() : jdbc.queryForList("""
                SELECT DISTINCT q.theme_id FROM attempt_questions aq
                JOIN attempts a ON a.id = aq.attempt_id
                JOIN questions q ON q.id = aq.question_id
                WHERE a.user_id IN (:ids)
                """.replace(":ids", String.join(",",
                        candidats.stream().map(id -> "'" + id + "'").toList())), UUID.class);
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
        for (UUID theme : themes) {
            jdbc.update("DELETE FROM questions WHERE theme_id = ?", theme);
            jdbc.update("DELETE FROM themes WHERE id = ?", theme);
        }
    }

    // =====================================================================
    // Bug 1 — l'examen « plus ancien que lui-meme »
    // =====================================================================

    @Test
    @DisplayName("Un examen CE dont la fin porte des nanosecondes arrondies a la hausse par "
            + "la base n'est JAMAIS ignore pour anciennete : ses priorites vont au cycle suivant")
    void unExamenNEstJamaisPlusAncienQueLuiMeme() {
        User user = candidat();
        // Le Plan par defaut : le cycle d'examens (D-69).
        journeyService.lire(user.getId(), Module.TCF);
        // 🛑 La valeur exacte du journal de prod : `.331182712` en Java,
        // `.331183` relu en base (timestamptz arrondit a la microseconde).
        Instant fin = Instant.now().truncatedTo(ChronoUnit.SECONDS)
                .plusSeconds(1).plusNanos(331_182_712);
        Attempt examenCe = examenQcm(user, EpreuveType.TCF_CE, fin);
        for (Skill competence : comprehension(SkillSection.CE)) {
            priorite(user, competence, LearningPlanSourceType.TCF_CE, examenCe.getId(), fin);
        }

        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCe.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CE, fin));

        Journey attente = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE).orElseThrow(
                        () -> new AssertionError("l'examen CE a ete ignore pour anciennete"));
        // D-72 : l'examen (A1 non atteint) designe trois paliers, le cycle
        // suivant n'en travaille qu'un, le plus bas a acquerir.
        assertThat(competences(attente, EpreuveType.TCF_CE)).containsExactly("CE-A2");
    }

    // =====================================================================
    // D-70 — aucun bloc d'un cycle de travail ne reste vide
    // =====================================================================

    @Test
    @DisplayName("Scenario de prod — cycle d'examens fini, CO et CE a A1, Actualiser : le "
            + "cycle suivant propose A2, B1, B2 en CO comme en CE, et rien n'y est « termine »")
    void actualiserApresLeCycleDExamensProposeLesPaliersCoCe() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        Instant fin = Instant.now().plusSeconds(1);
        // CO : examen a A1, trop peu de reponses par palier pour observer quoi
        // que ce soit — AUCUNE priorite (le cas de prod, CO-A2 NOT_OBSERVED).
        Attempt examenCo = examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, fin);
        data.learningPlanObservation(user, comprehension(SkillSection.CO).get(0),
                LearningPlanSourceType.TCF_CO, LearningPlanSkillStatus.NOT_OBSERVED,
                ObservationConfidence.LOW, examenCo.getId(), fin, examenCo.getId());
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCo.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, fin));
        // CE : examen a A1, les trois paliers PRIORITY.
        Attempt examenCe = examenQcm(user, EpreuveType.TCF_CE, NiveauCecrl.A1, fin);
        for (Skill competence : comprehension(SkillSection.CE)) {
            priorite(user, competence, LearningPlanSourceType.TCF_CE, examenCe.getId(), fin);
        }
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCe.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CE, fin));
        // EO / EE : examens passes, hors du sujet de ce test.
        Journey cycleDExamens = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
        cloreLesExamens(cycleDExamens, EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        JourneyDto fini = journeyService.lire(user.getId(), Module.TCF);
        assertThat(fini.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(fini.nextStep()).isNotNull();

        int annonce = fini.cycle().prioritesCycleSuivant();

        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(suivant.cycle().numero()).isEqualTo(2);
        // 🛑 D-72 (2026-10-05) : UN palier par cycle en CO/CE, le plus bas a
        // acquerir — D-70 posait A2, B1 et B2.
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-A2");
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CE)).containsExactly("CE-A2");
        // Le nombre annonce sous « Actualiser » inclut le complement D-70 du CO.
        assertThat(annonce).isEqualTo(entrainementsPoses(suivant)).isEqualTo(2);
        // 🛑 Jamais une epreuve « terminee » sans etape realisee dans CE cycle.
        assertThat(suivant.blocs()).noneMatch(b -> b.status() == JourneyBlocStatus.TERMINE);
        assertThat(suivant.blocs()).allSatisfy(b -> assertThat(b.exam())
                .as("chaque bloc finit par son examen blanc : " + b.bloc().code()).isNotNull());
        assertThat(suivant.state()).isNotEqualTo(JourneyState.CYCLE_COMPLETED);
    }

    @Test
    @DisplayName("Le cycle de prod tel qu'il est (CO et CE vides, EO et EE peuples) est "
            + "repare a la LECTURE, une seule fois, sans script")
    void laLectureRepareUnCyclePromuAvecDesBlocsVides() {
        User user = candidat();
        Instant avant = Instant.now().minusSeconds(3600);
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, avant);
        examenQcm(user, EpreuveType.TCF_CE, NiveauCecrl.A1_NON_ATTEINT, avant);
        data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        Journey promu = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        lotDExpression(promu, EpreuveType.TCF_EO);
        lotDExpression(promu, EpreuveType.TCF_EE);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(vue, EpreuveType.TCF_CO)).containsExactly("CO-A2");
        assertThat(competencesDuBloc(vue, EpreuveType.TCF_CE)).containsExactly("CE-A2");
        assertThat(vue.blocs()).noneMatch(b -> b.status() == JourneyBlocStatus.TERMINE);
        // 🛑 Un examen anterieur au cycle ne ferme RIEN (D-69 ter) : l'examen de
        // bloc pose est ouvert.
        assertThat(blocDe(vue, EpreuveType.TCF_CO).exam().status())
                .isNotEqualTo(JourneyStepStatus.COMPLETED);

        int etapes = steps.findAllByJourney(promu.getId()).size();
        journeyService.lire(user.getId(), Module.TCF);
        assertThat(steps.findAllByJourney(promu.getId())).as("idempotent").hasSize(etapes);
    }

    @Test
    @DisplayName("Rien a travailler : objectif atteint ⇒ examen blanc REASSESS ; expression ⇒ "
            + "examen blanc ; jamais mesuree ⇒ examen INITIAL")
    void rienATravaillerDonneToujoursUnExamenBlanc() {
        User user = candidat();
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.B2, Instant.now().minusSeconds(3600));
        data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        Journey promu = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        lotDExpression(promu, EpreuveType.TCF_EE);

        journeyService.lire(user.getId(), Module.TCF);

        List<JourneyStep> file = steps.findAllByJourney(promu.getId());
        assertThat(examenSeul(file, EpreuveType.TCF_CO).getPurpose())
                .isEqualTo(JourneyStepPurpose.REASSESS);
        assertThat(examenSeul(file, EpreuveType.TCF_CE).getPurpose())
                .isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
        assertThat(examenSeul(file, EpreuveType.TCF_EO).getPurpose())
                .isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
        assertThat(file).filteredOn(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .allMatch(step -> step.getExamType() == EpreuveType.TCF_EE);
    }

    // =====================================================================
    // D-72 — en CO/CE, un cycle ne travaille qu'UN palier : le plus bas a acquerir
    // =====================================================================

    @Test
    @DisplayName("D-72 — CO mesuree A2, fragilites B1 et B2 : le cycle suivant ne travaille "
            + "que le B1, puis l'examen ; CE mesuree B1 sans fragilite : le B2")
    void unSeulPalierAuDessusDuNiveauMesure() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        Instant fin = Instant.now().plusSeconds(1);
        Attempt examenCo = examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A2, fin);
        for (Skill competence : comprehension(SkillSection.CO)) {
            if ("A2".equals(competence.getTargetLevel())) continue;
            priorite(user, competence, LearningPlanSourceType.TCF_CO, examenCo.getId(), fin);
        }
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCo.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, fin));
        Attempt examenCe = examenQcm(user, EpreuveType.TCF_CE, NiveauCecrl.B1, fin);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCe.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CE, fin));
        cloreLesExamens(enCours(user), EpreuveType.TCF_EO, EpreuveType.TCF_EE);

        int annonce = journeyService.lire(user.getId(), Module.TCF).cycle().prioritesCycleSuivant();
        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-B1");
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CE)).containsExactly("CE-B2");
        assertThat(blocDe(suivant, EpreuveType.TCF_CO).exam()).isNotNull();
        assertThat(blocDe(suivant, EpreuveType.TCF_CE).exam()).isNotNull();
        assertThat(annonce).isEqualTo(entrainementsPoses(suivant)).isEqualTo(2);
    }

    @Test
    @DisplayName("D-72 — niveau INCONNU (CE jamais evaluee) : examen blanc seul, jamais un palier")
    void unNiveauInconnuNeFabriqueAucunPalier() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        Instant fin = Instant.now().plusSeconds(1);
        Attempt examenCo = examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, fin);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examenCo.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, fin));
        cloreLesExamens(enCours(user),
                EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);

        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-A2");
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CE)).isEmpty();
        assertThat(blocDe(suivant, EpreuveType.TCF_CE).exam().purpose())
                .isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
    }

    @Test
    @DisplayName("D-72 — examen rate : un cycle d'A2 travaille, l'examen redonne A1 ⇒ le cycle "
            + "suivant retravaille l'A2")
    void unExamenRateRedonneLeMemePalier() {
        User user = candidat();
        Skill coA2 = palier(SkillSection.CO, "A2");
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, Instant.now().minusSeconds(7200));
        data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        Journey cycle = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        lot(cycle, EpreuveType.TCF_CO, List.of(coA2));
        cloreTout(cycle, step -> step.getType() == JourneyStepType.TRAIN_SKILL,
                JourneyStepResolution.QUOTA_REACHED);
        for (EpreuveType epreuve : List.of(
                EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE)) {
            examenFait(cycle, epreuve);
        }

        Instant fin = Instant.now().plusSeconds(1);
        Attempt rate = examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, fin);
        priorite(user, coA2, LearningPlanSourceType.TCF_CO, rate.getId(), fin);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                rate.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, fin));
        // R12 a pose « Évaluer mon niveau » sur les epreuves jamais mesurees : hors sujet ici.
        cloreLesExamens(cycle, EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);

        JourneyDto fini = journeyService.lire(user.getId(), Module.TCF);
        assertThat(fini.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        int annonce = fini.cycle().prioritesCycleSuivant();
        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-A2");
        assertThat(annonce).isEqualTo(entrainementsPoses(suivant));
    }

    @Test
    @DisplayName("D-72 — un cycle en attente compose AVANT la regle (A2, B1, B2) est relu a "
            + "l'actualisation : seul le palier du jour reste ; EE inchangee ; N annonce = N pose")
    void lActualisationRelitLePalierDuCycleEnAttente() {
        User user = candidat();
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, Instant.now().minusSeconds(7200));
        cycleTermine(user);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        lot(attente, EpreuveType.TCF_CO, comprehension(SkillSection.CO));
        List<Skill> ee = skillManager.findActiveBySection(SkillSection.EE).subList(0, 3);
        lot(attente, EpreuveType.TCF_EE, ee);

        int annonce = journeyService.lire(user.getId(), Module.TCF).cycle().prioritesCycleSuivant();
        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-A2");
        // 🛑 L'expression n'est pas concernee : ses trois priorites restent.
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_EE))
                .containsExactlyElementsOf(ee.stream().map(Skill::getCode).toList());
        assertThat(annonce).isEqualTo(entrainementsPoses(suivant)).isEqualTo(4);
        // Les etapes ecartees ne sont jamais montrees (SUPERSEDED).
        assertThat(steps.findAllByJourney(attente.getId()))
                .filteredOn(step -> step.getExamType() == EpreuveType.TCF_CO
                        && step.getType() == JourneyStepType.TRAIN_SKILL)
                .filteredOn(step -> step.getResolution() == JourneyStepResolution.SUPERSEDED)
                .hasSize(2);
    }

    @Test
    @DisplayName("D-72 — le niveau a monte depuis la mise en attente (A1 ⇒ A2) : le lot A2 est "
            + "ecarte en entier et le bloc recompose au B1, examen compris")
    void unNiveauMonteRecomposeLeBloc() {
        User user = candidat();
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A1, Instant.now().minusSeconds(7200));
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.A2, Instant.now().minusSeconds(3600));
        cycleTermine(user);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        JourneyLot perime = lot(attente, EpreuveType.TCF_CO, List.of(palier(SkillSection.CO, "A2")));

        int annonce = journeyService.lire(user.getId(), Module.TCF).cycle().prioritesCycleSuivant();
        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO)).containsExactly("CO-B1");
        assertThat(blocDe(suivant, EpreuveType.TCF_CO).exam()).isNotNull();
        assertThat(lots.findById(perime.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyLotStatus.SUPERSEDED);
        assertThat(annonce).isEqualTo(entrainementsPoses(suivant)).isEqualTo(1);
    }

    // ------------------------------------------------------------- fabriques

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        data.userSubscription(user, data.plan());
        return user;
    }

    /** Un examen blanc QCM termine a {@code fin}, tout faux (A1 non atteint). */
    private Attempt examenQcm(User user, EpreuveType epreuve, Instant fin) {
        return examenQcm(user, epreuve, NiveauCecrl.A1_NON_ATTEINT, fin);
    }

    private void priorite(User user, Skill competence, LearningPlanSourceType source,
                          UUID examen, Instant quand) {
        data.learningPlanObservation(user, competence, source, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.MEDIUM, examen, quand, examen);
    }

    /** Les competences de comprehension seedees d'un domaine (A2, B1, B2). */
    private List<Skill> comprehension(SkillSection section) {
        return skillManager.findActiveComprehension().stream()
                .filter(skill -> skill.getSection() == section)
                .toList();
    }

    private List<String> competences(Journey journey, EpreuveType epreuve) {
        return steps.findAllByJourney(journey.getId()).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getExamType() == epreuve)
                .filter(JourneyStep::estOuverte)
                .map(step -> step.getSkill().getCode())
                .toList();
    }

    /** Un examen blanc QCM termine a {@code fin}, au niveau demande. */
    private Attempt examenQcm(User user, EpreuveType epreuve, NiveauCecrl niveau, Instant fin) {
        Attempt attempt = data.examenQcmTcfPasse(user, epreuve, niveau);
        attempt.setFinishedAt(fin);
        return data.saveAttempt(attempt);
    }

    private void cloreLesExamens(Journey journey, EpreuveType... epreuves) {
        for (JourneyStep step : steps.findAllByJourney(journey.getId())) {
            if (step.getType() != JourneyStepType.SECTION_EXAM) continue;
            if (!List.of(epreuves).contains(step.getExamType())) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                    Instant.now())) {
                steps.saveAndFlush(step);
            }
        }
    }

    /** Un lot d'expression du cycle : une competence de l'epreuve, puis son examen. */
    private void lotDExpression(Journey journey, EpreuveType epreuve) {
        SkillSection section = epreuve == EpreuveType.TCF_EO ? SkillSection.EO : SkillSection.EE;
        Skill competence = skillManager.findActiveBySection(section).get(0);
        JourneyLot lot = new JourneyLot();
        lot.setJourney(journey);
        lot.setExamType(epreuve);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        lot = lots.saveAndFlush(lot);
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(epreuve);
        step.setSkill(competence);
        step.setPosition(journey.consommerPosition());
        steps.saveAndFlush(step);
        JourneyStep examen = new JourneyStep();
        examen.setJourney(journey);
        examen.setLot(lot);
        examen.setType(JourneyStepType.SECTION_EXAM);
        examen.setPurpose(JourneyStepPurpose.REASSESS);
        examen.setExamType(epreuve);
        examen.setPosition(journey.consommerPosition());
        steps.saveAndFlush(examen);
        journeys.saveAndFlush(journey);
    }

    private Journey enCours(User user) {
        return journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
    }

    /** La competence de comprehension seedee d'un domaine a un palier. */
    private Skill palier(SkillSection section, String palier) {
        return comprehension(section).stream()
                .filter(skill -> palier.equals(skill.getTargetLevel()))
                .findFirst().orElseThrow();
    }

    /** Un cycle de rang 2, termine : chaque bloc porte un examen deja fait. */
    private Journey cycleTermine(User user) {
        data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        Journey cycle = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        for (EpreuveType epreuve : List.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EO, EpreuveType.TCF_EE)) {
            examenFait(cycle, epreuve);
        }
        return cycle;
    }

    private void examenFait(Journey journey, EpreuveType epreuve) {
        JourneyStep examen = new JourneyStep();
        examen.setJourney(journey);
        examen.setType(JourneyStepType.SECTION_EXAM);
        examen.setPurpose(JourneyStepPurpose.REASSESS);
        examen.setExamType(epreuve);
        examen.setPosition(journey.consommerPosition());
        examen.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(), Instant.now());
        steps.saveAndFlush(examen);
        journeys.saveAndFlush(journey);
    }

    /** Un lot ouvert : ses competences, dans l'ordre, puis son examen. */
    private JourneyLot lot(Journey journey, EpreuveType epreuve, List<Skill> competences) {
        JourneyLot lot = new JourneyLot();
        lot.setJourney(journey);
        lot.setExamType(epreuve);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        lot = lots.saveAndFlush(lot);
        for (Skill competence : competences) {
            JourneyStep step = new JourneyStep();
            step.setJourney(journey);
            step.setLot(lot);
            step.setType(JourneyStepType.TRAIN_SKILL);
            step.setExamType(epreuve);
            step.setSkill(competence);
            step.setPosition(journey.consommerPosition());
            steps.saveAndFlush(step);
        }
        JourneyStep examen = new JourneyStep();
        examen.setJourney(journey);
        examen.setLot(lot);
        examen.setType(JourneyStepType.SECTION_EXAM);
        examen.setPurpose(JourneyStepPurpose.REASSESS);
        examen.setExamType(epreuve);
        examen.setPosition(journey.consommerPosition());
        steps.saveAndFlush(examen);
        journeys.saveAndFlush(journey);
        return lot;
    }

    private void cloreTout(Journey journey, java.util.function.Predicate<JourneyStep> lesquelles,
                           JourneyStepResolution motif) {
        for (JourneyStep step : steps.findAllByJourney(journey.getId())) {
            if (lesquelles.test(step) && step.clore(motif, UUID.randomUUID(), Instant.now())) {
                steps.saveAndFlush(step);
            }
        }
    }

    /** Les etapes d'entrainement que le cycle promu porte, tous blocs confondus. */
    private static int entrainementsPoses(JourneyDto vue) {
        return vue.blocs().stream().mapToInt(bloc -> bloc.steps().size()).sum();
    }

    private static JourneyStep examenSeul(List<JourneyStep> file, EpreuveType epreuve) {
        List<JourneyStep> duBloc = file.stream()
                .filter(step -> step.getExamType() == epreuve).toList();
        assertThat(duBloc).as("un examen blanc seul pour " + epreuve).hasSize(1);
        assertThat(duBloc.get(0).getType()).isEqualTo(JourneyStepType.SECTION_EXAM);
        return duBloc.get(0);
    }

    private static JourneyBlocDto blocDe(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }

    private static List<String> competencesDuBloc(JourneyDto vue, EpreuveType epreuve) {
        return blocDe(vue, epreuve).steps().stream()
                .map(step -> step.skillCode())
                .toList();
    }
}
