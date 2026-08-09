package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.SkillPromptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class LearningPlanServiceTest {

    private ProductionTaskManager taskManager;
    private DiagnosticSessionManager sessionManager;
    private LearningPlanObservationManager observationManager;
    private SkillPromptManager promptManager;
    private LearningPlanService service;
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        sessionManager = mock(DiagnosticSessionManager.class);
        observationManager = mock(LearningPlanObservationManager.class);
        promptManager = mock(SkillPromptManager.class);
        service = new LearningPlanService(new DiagnosticProperties(), taskManager,
                sessionManager, observationManager, promptManager);
    }

    @Test
    void sansSessionLeServeurDemandeLeDiagnostic() {
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.empty());

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.NEEDS_DIAGNOSTIC);
        assertThat(result.currentPriority()).isNull();
    }

    @Test
    void uneSessionExistanteEstRepriseSansPrioritesRecalculeesCoteFront() {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.of(session));

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.DIAGNOSTIC_IN_PROGRESS);
        assertThat(result.diagnosticSessionId()).isEqualTo(session.getId());
    }

    @Test
    void planActifGardeTroisPrioritesMaximumEtPreferePriorityAToReinforce() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now().minusSeconds(60));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));

        Instant now = Instant.now();
        LearningPlanObservation reinforceNewest = observation(
                "EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, now);
        LearningPlanObservation priorityOlder = observation(
                "EE1-C8", LearningPlanSkillStatus.PRIORITY, now.minusSeconds(60));
        LearningPlanObservation priorityThird = observation(
                "EO2-C3", LearningPlanSkillStatus.PRIORITY, now.minusSeconds(120));
        LearningPlanObservation reinforceFourth = observation(
                "EO3-C1", LearningPlanSkillStatus.TO_REINFORCE, now.minusSeconds(180));
        LearningPlanObservation solid = observation(
                "EO1-C1", LearningPlanSkillStatus.SOLID, now.minusSeconds(240));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                reinforceNewest, priorityOlder, priorityThird, reinforceFourth, solid));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        when(promptManager.findActiveBySkillId(any())).thenAnswer(invocation -> {
            SkillPrompt prompt = new SkillPrompt();
            prompt.setId(UUID.randomUUID());
            prompt.setSkill(List.of(reinforceNewest, priorityOlder, priorityThird, reinforceFourth)
                    .stream().map(LearningPlanObservation::getSkill)
                    .filter(skill -> skill.getId().equals(invocation.getArgument(0)))
                    .findFirst().orElse(null));
            prompt.setTitle("Exercice ciblé");
            return List.of(prompt);
        });

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C8");
        assertThat(result.nextPriorities()).hasSize(2);
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
        assertThat(result.observedSkillCount()).isEqualTo(5);
        assertThat(result.activitiesThisWeek()).isEqualTo(2);
    }

    @Test
    void seuleLaDerniereObservationDeChaqueCompetenceFaitFoi() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE2-C2");
        LearningPlanObservation latestSolid = observation(
                skill, LearningPlanSkillStatus.SOLID, Instant.now());
        LearningPlanObservation oldPriority = observation(
                skill, LearningPlanSkillStatus.PRIORITY, Instant.now().minusSeconds(600));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(latestSolid, oldPriority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNull();
        assertThat(result.nextPriorities()).isEmpty();
        assertThat(result.observedSkills()).singleElement()
                .extracting(item -> item.status())
                .isEqualTo(LearningPlanSkillStatus.SOLID);
    }

    @Test
    void absenceDePreuveRecenteNeffacePasUnePrioriteAnterieureObservee() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EO2-C1");
        LearningPlanObservation notObserved = observation(
                skill, LearningPlanSkillStatus.NOT_OBSERVED, Instant.now());
        notObserved.setObserved(false);
        notObserved.setEvidence(null);
        LearningPlanObservation oldPriority = observation(
                skill, LearningPlanSkillStatus.PRIORITY, Instant.now().minusSeconds(600));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(notObserved, oldPriority));
        when(observationManager.countSince(any(), any())).thenReturn(1L);

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().skillCode()).isEqualTo("EO2-C1");
        assertThat(result.currentPriority().status()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(result.observedSkillCount()).isEqualTo(1);
        assertThat(result.observedSkills()).singleElement()
                .extracting(item -> item.status())
                .isEqualTo(LearningPlanSkillStatus.PRIORITY);
    }

    private static LearningPlanObservation observation(
            String code, LearningPlanSkillStatus status, Instant at) {
        return observation(skill(code), status, at);
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, Instant at) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setObserved(true);
        observation.setStatus(status);
        observation.setExplanation("Explication serveur");
        observation.setEvidence("Preuve exacte");
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setObservedAt(at);
        return observation;
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);
        return skill;
    }
}
