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

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
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
        assertThat(competences(attente, EpreuveType.TCF_CE))
                .containsExactlyInAnyOrder("CE-A2", "CE-B1", "CE-B2");
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

        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(suivant.cycle().numero()).isEqualTo(2);
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CO))
                .containsExactly("CO-A2", "CO-B1", "CO-B2");
        assertThat(competencesDuBloc(suivant, EpreuveType.TCF_CE))
                .containsExactlyInAnyOrder("CE-A2", "CE-B1", "CE-B2");
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

        assertThat(competencesDuBloc(vue, EpreuveType.TCF_CO))
                .containsExactly("CO-A2", "CO-B1", "CO-B2");
        assertThat(competencesDuBloc(vue, EpreuveType.TCF_CE))
                .containsExactly("CE-A2", "CE-B1", "CE-B2");
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
