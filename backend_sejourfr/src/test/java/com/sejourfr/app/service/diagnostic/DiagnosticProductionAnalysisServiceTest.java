package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticTaskSkillManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.LearningPlanObservationService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DiagnosticProductionAnalysisServiceTest {

    @Test
    void repriseApresPersistanceAnalyseFinaliseStatutEtObservationsSansNouvelAppelLlm() {
        ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        SkillManager skills = mock(SkillManager.class);
        DiagnosticAnalysisPromptBuilder prompts = mock(DiagnosticAnalysisPromptBuilder.class);
        DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        DiagnosticProductionAnalysisManager analyses = mock(DiagnosticProductionAnalysisManager.class);
        DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        LearningPlanObservationService observations = mock(LearningPlanObservationService.class);
        DiagnosticProductionAnalysisService service = new DiagnosticProductionAnalysisService(
                submissions, transcriptions, taskSkills, skills, prompts, llm,
                validator, analyses, rubrics, observations);

        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setStatut(SubmissionStatut.EVALUATING);
        submission.setDiagnostic(true);
        DiagnosticProductionAnalysis existing = new DiagnosticProductionAnalysis();
        existing.setSubmission(submission);
        existing.setAnalysisJson(Map.of("skills", List.of()));
        when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.of(existing));
        when(submissions.findByIdWithTaskAndUser(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of());

        assertThat(service.analyseDiagnostic(submission.getId())).isSameAs(existing);

        assertThat(submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(submissions).save(submission);
        verify(observations).recordProduction(
                submission, List.of(), existing.getAnalysisJson(), true);
        verify(llm, never()).analyse(any(), any());
    }

    @Test
    void panneObservationLaisseLaProductionNonEvalueePourUneRepriseSure() {
        ProductionSubmissionManager submissions = mock(ProductionSubmissionManager.class);
        TranscriptionManager transcriptions = mock(TranscriptionManager.class);
        DiagnosticTaskSkillManager taskSkills = mock(DiagnosticTaskSkillManager.class);
        SkillManager skills = mock(SkillManager.class);
        DiagnosticAnalysisPromptBuilder prompts = mock(DiagnosticAnalysisPromptBuilder.class);
        DiagnosticAnalysisLlmClient llm = mock(DiagnosticAnalysisLlmClient.class);
        DiagnosticAnalysisValidator validator = mock(DiagnosticAnalysisValidator.class);
        DiagnosticProductionAnalysisManager analyses = mock(DiagnosticProductionAnalysisManager.class);
        DiagnosticRubricsProvider rubrics = mock(DiagnosticRubricsProvider.class);
        LearningPlanObservationService observations = mock(LearningPlanObservationService.class);
        DiagnosticProductionAnalysisService service = new DiagnosticProductionAnalysisService(
                submissions, transcriptions, taskSkills, skills, prompts, llm,
                validator, analyses, rubrics, observations);

        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setDiagnosticCode("INITIAL_TCF");
        task.setDiagnosticVersion(1);
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setProductionTask(task);
        submission.setUser(user);
        submission.setStatut(SubmissionStatut.EVALUATING);
        submission.setDiagnostic(true);
        DiagnosticProductionAnalysis existing = new DiagnosticProductionAnalysis();
        existing.setSubmission(submission);
        existing.setAnalysisJson(Map.of("skills", List.of()));
        when(analyses.findBySubmissionId(submission.getId())).thenReturn(Optional.of(existing));
        when(submissions.findByIdWithTaskAndUser(submission.getId()))
                .thenReturn(Optional.of(submission));
        when(taskSkills.findActiveByTaskId(task.getId())).thenReturn(List.of());
        doThrow(new IllegalStateException("plan indisponible"))
                .when(observations).recordProduction(
                        submission, List.of(), existing.getAnalysisJson(), true);

        assertThatThrownBy(() -> service.analyseDiagnostic(submission.getId()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("plan indisponible");

        assertThat(submission.getStatut()).isEqualTo(SubmissionStatut.EVALUATING);
        verify(submissions, never()).save(submission);
        verify(llm, never()).analyse(any(), any());
    }
}
