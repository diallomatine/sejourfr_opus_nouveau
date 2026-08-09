package com.sejourfr.app.service;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LearningPlanObservationServiceTest {

    private LearningPlanObservationManager observationManager;
    private DiagnosticSessionManager sessionManager;
    private UserSkillAttemptManager skillAttemptManager;
    private LearningPlanObservationService service;

    @BeforeEach
    void setUp() {
        observationManager = mock(LearningPlanObservationManager.class);
        sessionManager = mock(DiagnosticSessionManager.class);
        skillAttemptManager = mock(UserSkillAttemptManager.class);
        service = new LearningPlanObservationService(
                observationManager, sessionManager, skillAttemptManager);
    }

    @Test
    void uneSeuleReussiteMicroNeDeclareJamaisLaCompetenceSolide() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(sessionManager.findLatestCompleted(attempt.getUser().getId()))
                .thenReturn(Optional.of(new DiagnosticSession()));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(saved.getValue().getStatus()).isNotEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(saved.getValue().getSourceType()).isEqualTo(LearningPlanSourceType.SKILL_TRAINING);
        assertThat(saved.getValue().isBaseline()).isFalse();
    }

    @Test
    void unMicroExerciceNonValideResteUnePriorite() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.NOT_VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(sessionManager.findLatestCompleted(attempt.getUser().getId()))
                .thenReturn(Optional.of(new DiagnosticSession()));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
    }

    @Test
    void aucunSignalNestAjouteAvantUnDiagnosticTermine() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(sessionManager.findLatestCompleted(attempt.getUser().getId()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        verify(observationManager, never()).save(any());
    }

    private static UserSkillAttempt attempt(SkillCriterionStatus criterion) {
        User user = new User();
        user.setId(UUID.randomUUID());
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EE1-C1");
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        attempt.setWrittenProduction("Je donne une raison précise et un exemple.");
        attempt.setAnalysisJson(Map.of("improvement_priority", "Ajouter une conséquence."));
        attempt.setUpdatedAt(Instant.now());
        return attempt;
    }
}
