package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>L'examen blanc d'une epreuve est reconnu par le cycle, d'ou qu'il soit
 * lance</b> (bug du 2026-09-26).
 *
 * <p>Constat en base : un examen blanc CO termine fermait bien l'etape
 * d'examen du bloc CO, puis une <b>seconde</b> etape « Examen a passer » CO
 * etait recreee dans la foulee — le parcours, appele en {@code REQUIRES_NEW}
 * depuis la transaction de cloture, lisait l'attempt encore {@code EN_COURS}
 * et jugeait l'epreuve « jamais mesuree » (R12). Le Plan affichait donc
 * toujours l'examen a passer, l'Accueil (lu apres le commit) etait juste.
 *
 * <p>🛑 Ces tests passent par le <b>vrai</b> {@code AttemptService.finish} —
 * celui qu'appellent tous les points de lancement (Plan, Accueil, Reviser,
 * Examens blancs, examen complet) : aucune session n'est rattachee a une
 * etape, et c'est voulu. Et ils ne sont pas transactionnels, pour que la
 * cloture commite comme en production.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ExamenBlancHorsPlanIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private AttemptService attemptService;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository journeySteps;
    @Autowired private AttemptManager attemptManager;
    @Autowired private AttemptQuestionManager attemptQuestionManager;
    @Autowired private PlatformTransactionManager txManager;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    @Test
    @DisplayName("Un examen blanc CO passe hors du Plan clot l'etape CO, et aucune n'est recreee")
    void unExamenCoHorsDuPlanClotLEtape() {
        User user = candidatAvecCycleAmorce();
        assertThat(examensCo(user)).singleElement()
                .satisfies(step -> assertThat(step.estOuverte()).isTrue());

        UUID examen = examenCoRepondu(user, null);
        attemptService.finish(user.getId(), examen);

        // 🛑 Lu en BASE, avant toute lecture du Plan : c'est l'ecriture de fin
        // d'examen qui est verrouillee ici, pas le filet de lecture.
        assertThat(examensCo(user)).singleElement().satisfies(step -> {
            assertThat(step.estOuverte()).isFalse();
            assertThat(step.getResolution())
                    .isEqualTo(JourneyStepResolution.SATISFIED_BY_ASSESSMENT);
            assertThat(step.getResolvedByAssessmentId()).isEqualTo(examen);
        });

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        assertThat(blocDe(vue, EpreuveType.TCF_CO).status()).isEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(vue.cycle().etapesTerminees()).isEqualTo(1);
    }

    @Test
    @DisplayName("La sous-epreuve CO d'un examen blanc COMPLET clot l'etape CO")
    void laSousEpreuveCoDUnExamenCompletClotLEtape() {
        User user = candidatAvecCycleAmorce();

        Attempt parent = data.attempt(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setMode(AttemptMode.EXAMEN);
        parent = data.saveAttempt(parent);
        UUID sousEpreuve = examenCoRepondu(user, parent);

        attemptService.finish(user.getId(), sousEpreuve);

        assertThat(examensCo(user)).singleElement().satisfies(step -> {
            assertThat(step.estOuverte()).isFalse();
            assertThat(step.getResolvedByAssessmentId()).isEqualTo(sousEpreuve);
        });
        assertThat(blocDe(journeyService.lire(user.getId(), Module.TCF), EpreuveType.TCF_CO)
                .status()).isEqualTo(JourneyBlocStatus.TERMINE);
    }

    @Test
    @DisplayName("Un examen commence mais NON termine ne clot rien")
    void unExamenNonTermineNeClotRien() {
        User user = candidatAvecCycleAmorce();
        examenCoRepondu(user, null);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(examensCo(user)).singleElement()
                .satisfies(step -> assertThat(step.estOuverte()).isTrue());
        // D-69 : le cycle d'examens porte l'examen CO, et il n'est pas termine.
        assertThat(blocDe(vue, EpreuveType.TCF_CO).status())
                .isNotEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(vue.cycle().etapesTerminees()).isZero();
    }

    @Test
    @DisplayName("Un examen passe AVANT le cycle ne ferme rien : son examen est pose, OUVERT (D-69)")
    void unExamenAnterieurAuCycleNePoseNiNeCloturien() {
        User user = candidat();
        observationDExamenEe(user);
        termineSansSignal(examenCoRepondu(user, null));

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        // ⚠️ REVU LE 2026-09-28 (D-69) : le premier cycle d'un compte sans
        // diagnostic est le cycle d'examens — l'examen CO y est pose meme
        // mesure (« Vérifier mes progrès »). R19 tient : un examen ANTERIEUR au
        // cycle ne ferme rien, aucune etape « deja faite ».
        assertThat(examensCo(user)).singleElement().satisfies(step -> {
            assertThat(step.getPurpose()).isEqualTo(JourneyStepPurpose.REASSESS);
            assertThat(step.estOuverte()).isTrue();
        });
        assertThat(blocDe(vue, EpreuveType.TCF_CO).status()).isNotEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(vue.cycle().etapesTerminees()).isZero();
    }

    @Test
    @DisplayName("Filet de lecture : une etape « Evaluer » ouverte sur une epreuve mesuree depuis est close")
    void leFiletDeLectureRattrapeUneMesureNonSignalee() {
        User user = candidatAvecCycleAmorce();
        // Un examen termine dont le cycle n'a jamais recu le signal — le cas
        // d'un compte touche avant le correctif, ou d'un signal best-effort perdu.
        UUID examen = examenCoRepondu(user, null);
        termineSansSignal(examen);
        assertThat(examensCo(user)).singleElement()
                .satisfies(step -> assertThat(step.estOuverte()).isTrue());

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(examensCo(user)).singleElement().satisfies(step -> {
            assertThat(step.getResolution())
                    .isEqualTo(JourneyStepResolution.SATISFIED_BY_ASSESSMENT);
            assertThat(step.getResolvedByAssessmentId()).isEqualTo(examen);
        });
        assertThat(blocDe(vue, EpreuveType.TCF_CO).status()).isEqualTo(JourneyBlocStatus.TERMINE);
    }

    // ------------------------------------------------------------------ outils

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /**
     * Le cycle du proprietaire au moment du bug : un lot EE issu d'une
     * evaluation, et « Évaluer mon niveau » sur les trois autres epreuves.
     */
    private User candidatAvecCycleAmorce() {
        User user = candidat();
        observationDExamenEe(user);
        journeyService.lire(user.getId(), Module.TCF);
        assertThat(examensCo(user)).singleElement().satisfies(step ->
                assertThat(step.getPurpose()).isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT));
        return user;
    }

    private void observationDExamenEe(User user) {
        Skill ee = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).getFirst();
        data.learningPlanObservation(user, ee, LearningPlanSourceType.MOCK_EXAM_EE,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.HIGH, null,
                Instant.now().minusSeconds(86_400), UUID.randomUUID());
    }

    /**
     * Un examen blanc CO <b>lance par la porte des examens</b> (slot 1, sans
     * aucun lien d'etape), repondu juste partout, pas encore termine.
     *
     * <p>🛑 Questions de la banque SEEDEE, jamais fabriquees : ce test n'est
     * pas transactionnel, et une question creee ici laisserait derriere elle
     * une thematique qui fausse les tests qui comptent les cinq thematiques
     * civiques.
     *
     * @param parent l'examen complet dont c'est la sous-epreuve, ou
     *               {@code null} pour un examen d'epreuve seul
     */
    private UUID examenCoRepondu(User user, Attempt parent) {
        AttemptResponse lance = attemptService.start(user.getId(), new StartAttemptRequest(
                AttemptType.MOCK_EXAM, Module.TCF, null, null,
                null, null, null, null, QuestionType.CO, 1, null));
        if (parent != null) {
            new TransactionTemplate(txManager).executeWithoutResult(status -> {
                Attempt sous = attemptManager.findById(lance.id()).orElseThrow();
                sous.setParentAttempt(parent);
                sous.setSlotNumber(null);
                attemptManager.save(sous);
            });
        }
        List<SubmitAnswerRequest> reponses = new TransactionTemplate(txManager).execute(status ->
                attemptQuestionManager.findByAttemptOrderedByPosition(lance.id()).stream()
                        .map(aq -> new SubmitAnswerRequest(aq.getId(), List.of(
                                aq.getQuestion().getChoices().stream()
                                        .filter(Choice::isCorrect).map(Choice::getId)
                                        .findFirst().orElseThrow())))
                        .toList());
        assertThat(reponses).isNotEmpty();
        reponses.forEach(reponse -> attemptService.submitAnswer(user.getId(), lance.id(), reponse));
        return lance.id();
    }

    /** Termine la session en base SANS passer par la cloture : aucun signal. */
    private void termineSansSignal(UUID attemptId) {
        new TransactionTemplate(txManager).executeWithoutResult(status -> {
            Attempt attempt = attemptManager.findById(attemptId).orElseThrow();
            attempt.setFinishedAt(Instant.now());
            attempt.setStatus(AttemptStatus.TERMINE);
            attemptManager.save(attempt);
        });
    }

    private List<JourneyStep> examensCo(User user) {
        Journey journey = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
        return journeySteps.findAllByJourney(journey.getId()).stream()
                .filter(step -> step.getType() == JourneyStepType.SECTION_EXAM)
                .filter(step -> step.getExamType() == EpreuveType.TCF_CO)
                .toList();
    }

    private static JourneyBlocDto blocDe(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }
}
