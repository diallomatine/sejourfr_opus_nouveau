package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.LearningPlanObservationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SkillAnalysisAsyncRunnerTest {

    private UserSkillAttemptManager attempts;
    private SkillTranscriptionService transcription;
    private CompetenceAnalysisService analysis;
    private SkillAnalysisFailureRecorder failureRecorder;
    private LearningPlanObservationService observations;
    private SkillAnalysisAsyncRunner runner;

    @BeforeEach
    void setUp() {
        attempts = mock(UserSkillAttemptManager.class);
        transcription = mock(SkillTranscriptionService.class);
        analysis = mock(CompetenceAnalysisService.class);
        failureRecorder = mock(SkillAnalysisFailureRecorder.class);
        observations = mock(LearningPlanObservationService.class);
        runner = new SkillAnalysisAsyncRunner(
                attempts, transcription, analysis, failureRecorder, observations);
    }

    @Test
    void panneDuPlanNeTransformePasUneAnalyseReussieEnEchec() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(attemptId);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));
        doThrow(new IllegalStateException("plan indisponible"))
                .when(observations).recordSkillAttempt(attemptId);

        runner.runAsync(attemptId, false).join();

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATING);
        verify(analysis).analyse(attemptId);
        verify(observations).recordSkillAttempt(attemptId);
        verify(failureRecorder, never()).markFailed(attemptId, "plan indisponible");
    }

    @Test
    void panneDeLanalyseResteUnEchecDeTentative() {
        UUID attemptId = UUID.randomUUID();
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(attemptId);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        when(attempts.findByIdWithPrompt(attemptId)).thenReturn(Optional.of(attempt));
        doThrow(new IllegalStateException("analyse indisponible"))
                .when(analysis).analyse(attemptId);

        runner.runAsync(attemptId, false).join();

        verify(failureRecorder).markFailed(attemptId, "analyse indisponible");
        verify(observations, never()).recordSkillAttempt(attemptId);
    }
}
