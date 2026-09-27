package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.support.TestData;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les <b>evaluations</b> que les tests du parcours font passer a un candidat —
 * diagnostic rapide, examens blancs de production et de comprehension —, par
 * les chemins LIVE. Partage par {@code CycleDAffinageIT} et
 * {@code PlanParDefautIT} : deux copies de ces gestes auraient fini par ne plus
 * passer le meme examen.
 */
final class ExamensDuParcours {

    private final TestData data;
    private final JourneyService journeyService;
    private final AttemptService attemptService;
    private final AttemptQuestionManager attemptQuestionManager;
    private final PlatformTransactionManager txManager;
    private final SkillManager skillManager;

    ExamensDuParcours(TestData data, JourneyService journeyService, AttemptService attemptService,
                      AttemptQuestionManager attemptQuestionManager,
                      PlatformTransactionManager txManager, SkillManager skillManager) {
        this.data = data;
        this.journeyService = journeyService;
        this.attemptService = attemptService;
        this.attemptQuestionManager = attemptQuestionManager;
        this.txManager = txManager;
        this.skillManager = skillManager;
    }

    /**
     * Le diagnostic rapide termine, trois fragilites EE clavetees sur sa
     * soumission ecrite — le chemin LIVE, exactement comme
     * {@code JourneyObservationSourcesIT}.
     */
    void diagnosticRapide(User user) {
        DiagnosticSession session = data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        ProductionSubmission ecrit = data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user);
        for (int rang = 0; rang < 3; rang++) {
            data.learningPlanObservation(user, competenceEE(rang),
                    LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                    ObservationConfidence.HIGH, null, Instant.now().minusSeconds(3_600),
                    ecrit.getId());
        }
        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.diagnosticRapide(session.getId(), session.getCompletedAt()));
    }

    /** Un examen blanc EE passe, qui detecte {@code redetectee} en PRIORITE. */
    UUID examenEePasse(User user, Skill redetectee) {
        UUID examen = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1).getId();
        data.learningPlanObservation(user, redetectee,
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, Instant.now(), examen);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE, Instant.now()));
        return examen;
    }

    void examenProductionPasse(User user, EpreuveType epreuve) {
        UUID examen = data.epreuveProductionPassee(user, epreuve, NiveauCecrl.B1).getId();
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, epreuve, Instant.now()));
    }

    /**
     * Un examen blanc CO/CE lance par la porte des examens, repondu juste, et
     * termine par le VRAI {@code AttemptService.finish} — qui previent le
     * parcours apres son commit. Questions de la banque SEEDEE.
     */
    void examenQcmPasse(User user, QuestionType epreuve) {
        AttemptResponse lance = attemptService.start(user.getId(), new StartAttemptRequest(
                AttemptType.MOCK_EXAM, Module.TCF, null, null,
                null, null, null, null, epreuve, 1, null));
        List<SubmitAnswerRequest> reponses = new TransactionTemplate(txManager).execute(status ->
                attemptQuestionManager.findByAttemptOrderedByPosition(lance.id()).stream()
                        .map(aq -> new SubmitAnswerRequest(aq.getId(), List.of(
                                aq.getQuestion().getChoices().stream()
                                        .filter(Choice::isCorrect).map(Choice::getId)
                                        .findFirst().orElseThrow())))
                        .toList());
        assertThat(reponses).isNotEmpty();
        reponses.forEach(reponse -> attemptService.submitAnswer(user.getId(), lance.id(), reponse));
        attemptService.finish(user.getId(), lance.id());
    }

    Skill competenceEE(int rang) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(SkillTaskCode.EE1);
        assertThat(seedees).as("referentiel seede EE1").hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }
}
