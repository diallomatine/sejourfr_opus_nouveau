package com.sejourfr.app.service;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.diagnostic.DiagnosticProductionAnalysisService;
import com.sejourfr.app.service.diagnostic.DiagnosticSessionCoordinator;
import com.sejourfr.app.service.diagnostic.DiagnosticSessionFailureRecorder;
import com.sejourfr.app.service.versionciblee.ProductionVersionCibleeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.when;

class ProductionPipelineAsyncRunnerDiagnosticTest {

    private ProductionSubmissionManager submissionManager;
    private TranscriptionManager transcriptionManager;
    private WhisperTranscriptionService whisperService;
    private AiEvaluationService aiEvaluationService;
    private ProductionPipelineFailureRecorder failureRecorder;
    private ProductionVersionCibleeService versionCibleeService;
    private DiagnosticProductionAnalysisService diagnosticAnalysisService;
    private DiagnosticSessionCoordinator coordinator;
    private DiagnosticSessionFailureRecorder diagnosticFailureRecorder;
    private ProductionPipelineAsyncRunner runner;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        whisperService = mock(WhisperTranscriptionService.class);
        aiEvaluationService = mock(AiEvaluationService.class);
        failureRecorder = mock(ProductionPipelineFailureRecorder.class);
        versionCibleeService = mock(ProductionVersionCibleeService.class);
        diagnosticAnalysisService = mock(DiagnosticProductionAnalysisService.class);
        coordinator = mock(DiagnosticSessionCoordinator.class);
        diagnosticFailureRecorder = mock(DiagnosticSessionFailureRecorder.class);
        runner = new ProductionPipelineAsyncRunner(
                submissionManager, transcriptionManager, whisperService, aiEvaluationService,
                failureRecorder, versionCibleeService, diagnosticAnalysisService,
                coordinator, diagnosticFailureRecorder);
    }

    @Test
    void diagnosticPersistedBifurqueAvantTouteNotationSurVingt() {
        ProductionSubmission submission = submission(true, true);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(diagnosticAnalysisService.analyseDiagnostic(submission.getId()))
                .thenReturn(new DiagnosticProductionAnalysis());

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(diagnosticAnalysisService).analyseDiagnostic(submission.getId());
        verify(coordinator, times(2)).onAnalysisCompleted(submission.getId());
        verify(aiEvaluationService, never()).evaluate(any());
        verify(versionCibleeService, never()).enrichir(any());
    }

    @Test
    void metadataTaskEtSubmissionIncoherentesEchouentSansPolluerLePipelineStandard() {
        ProductionSubmission submission = submission(false, true);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(aiEvaluationService, never()).evaluate(any());
        verify(diagnosticAnalysisService, never()).analyseDiagnostic(any());
        verify(failureRecorder).markFailed(
                submission.getId(), "Purpose diagnostic incohérent avec la tâche");
        verify(diagnosticFailureRecorder).markFailedByAttempt(
                submission.getAttempt().getId(), "Purpose diagnostic incohérent avec la tâche");
    }

    @Test
    void productionStandardConserveCorrectionVersionCibleeEtObservateurPlanSepare() {
        ProductionSubmission submission = submission(false, false);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(aiEvaluationService.evaluate(submission.getId())).thenReturn(new AiEvaluation());

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(aiEvaluationService).evaluate(submission.getId());
        verify(versionCibleeService).enrichir(submission.getId());
        verify(diagnosticAnalysisService).observeStandardProduction(submission.getId());
        verify(coordinator, never()).onAnalysisCompleted(any());
    }

    private static ProductionSubmission submission(
            boolean persistedDiagnostic, boolean taskDiagnostic) {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EE);
        if (taskDiagnostic) {
            task.setDiagnosticCode("INITIAL_TCF");
            task.setDiagnosticVersion(1);
        }
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setAttempt(attempt);
        submission.setProductionTask(task);
        submission.setDiagnostic(persistedDiagnostic);
        return submission;
    }
}
