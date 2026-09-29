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
import com.sejourfr.app.service.diagnostic.exemplecible.DiagnosticExempleCibleService;
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
    private AiEvaluationService aiEvaluationService;
    private ProductionPipelineFailureRecorder failureRecorder;
    private ProductionVersionCibleeService versionCibleeService;
    private DiagnosticProductionAnalysisService diagnosticAnalysisService;
    private DiagnosticSessionCoordinator coordinator;
    private DiagnosticSessionFailureRecorder diagnosticFailureRecorder;
    private DiagnosticExempleCibleService exempleCibleService;
    private FreeExamEntitlementService freeExamEntitlementService;
    private ProductionPipelineAsyncRunner runner;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        aiEvaluationService = mock(AiEvaluationService.class);
        failureRecorder = mock(ProductionPipelineFailureRecorder.class);
        versionCibleeService = mock(ProductionVersionCibleeService.class);
        diagnosticAnalysisService = mock(DiagnosticProductionAnalysisService.class);
        coordinator = mock(DiagnosticSessionCoordinator.class);
        diagnosticFailureRecorder = mock(DiagnosticSessionFailureRecorder.class);
        exempleCibleService = mock(DiagnosticExempleCibleService.class);
        freeExamEntitlementService = mock(FreeExamEntitlementService.class);
        runner = new ProductionPipelineAsyncRunner(
                submissionManager, transcriptionManager, aiEvaluationService,
                failureRecorder, freeExamEntitlementService, versionCibleeService,
                diagnosticAnalysisService, coordinator, diagnosticFailureRecorder,
                exempleCibleService);
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
        // SECOND appel du diagnostic, lance APRES l'analyse et l'assemblage.
        verify(exempleCibleService).enrichir(submission.getId());
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
        // Une production standard n'est pas un diagnostic : aucun avant / apres.
        verify(exempleCibleService, never()).enrichir(any());
    }

    // ====================================================================
    // D-17 — la gratuite d'examen blanc se consomme a la REMISE DE L'ANALYSE
    // ====================================================================

    /**
     * 🛑 <b>Le point d'ecriture, et il est unique</b> : la gratuite se consomme
     * quand la correction est produite et persistee — la submission est
     * {@code EVALUATED}. Ce test fixe la <b>place</b> de l'appel ; ses
     * conditions (examen blanc, epreuve EE/EO, compte gratuit, hors diagnostic)
     * sont verrouillees par {@code FreeExamEntitlementServiceTest}.
     */
    @Test
    void laGratuiteSeConsommeQuandLAnalyseEstRendue_D17() {
        ProductionSubmission submission = submission(false, false);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(aiEvaluationService.evaluate(submission.getId())).thenReturn(new AiEvaluation());

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(freeExamEntitlementService).consommerApresAnalyse(submission.getId());
    }

    /**
     * 🛑 <b>Un echec du correcteur laisse la gratuite INTACTE</b> (D-17) : le
     * candidat n'a recu aucune analyse, il la retrouve. Sinon « offert une fois »
     * voudrait dire « perdu une fois ».
     */
    @Test
    void unEchecDuCorrecteurNeConsommeAucuneGratuite_D17() {
        ProductionSubmission submission = submission(false, false);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(aiEvaluationService.evaluate(submission.getId()))
                .thenThrow(new com.sejourfr.app.exception.AiEvaluationException("LLM indisponible"));

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(failureRecorder).markFailed(submission.getId(), "LLM indisponible");
        verify(freeExamEntitlementService, never()).consommerApresAnalyse(any());
    }

    /** Une correction qui ne produit rien n'est pas une analyse rendue. */
    @Test
    void uneCorrectionSansResultatNeConsommeAucuneGratuite_D17() {
        ProductionSubmission submission = submission(false, false);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(aiEvaluationService.evaluate(submission.getId())).thenReturn(null);

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(freeExamEntitlementService, never()).consommerApresAnalyse(any());
    }

    /**
     * Un sujet de <b>diagnostic</b> ne passe meme pas par le correcteur : il ne
     * peut donc jamais consommer une gratuite d'examen blanc. Le diagnostic
     * rapide est gratuit par lui-meme (D-17).
     */
    @Test
    void unDiagnosticNeConsommeAucuneGratuite_D17() {
        ProductionSubmission submission = submission(true, true);
        when(submissionManager.findByIdWithTask(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(diagnosticAnalysisService.analyseDiagnostic(submission.getId()))
                .thenReturn(new DiagnosticProductionAnalysis());

        runner.runPipelineAsync(submission.getId(), false).join();

        verify(freeExamEntitlementService, never()).consommerApresAnalyse(any());
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
