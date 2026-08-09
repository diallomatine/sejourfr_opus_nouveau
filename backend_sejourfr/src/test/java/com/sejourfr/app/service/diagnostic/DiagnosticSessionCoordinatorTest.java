package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DiagnosticSessionCoordinatorTest {

    private ProductionSubmissionManager submissionManager;
    private DiagnosticProductionAnalysisManager analysisManager;
    private DiagnosticSessionManager sessionManager;
    private AttemptManager attemptManager;
    private DiagnosticSessionCoordinator coordinator;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        analysisManager = mock(DiagnosticProductionAnalysisManager.class);
        sessionManager = mock(DiagnosticSessionManager.class);
        attemptManager = mock(AttemptManager.class);
        coordinator = new DiagnosticSessionCoordinator(
                submissionManager, analysisManager, sessionManager, attemptManager);
    }

    @Test
    void attendLesDeuxAnalysesPuisProduitTroisPrioritesMaximumSansAppelLlm() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        DiagnosticProductionAnalysis writtenAnalysis = analysis(written, List.of(
                priority("EE1-C1", "MEDIUM"), priority("EE2-C3", "HIGH")));
        DiagnosticProductionAnalysis oralAnalysis = analysis(oral, List.of(
                priority("EO2-C2", "LOW"), priority("EO3-C1", "HIGH")));

        when(submissionManager.findById(written.getId())).thenReturn(Optional.of(written));
        when(sessionManager.findByAttemptIdWithContent(writtenAttempt.getId()))
                .thenReturn(Optional.of(session));
        when(sessionManager.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));
        when(submissionManager.findByAttemptId(writtenAttempt.getId())).thenReturn(List.of(written));
        when(submissionManager.findByAttemptId(oralAttempt.getId())).thenReturn(List.of(oral));
        when(analysisManager.findBySubmissionId(written.getId()))
                .thenReturn(Optional.of(writtenAnalysis));
        when(analysisManager.findBySubmissionId(oral.getId()))
                .thenReturn(Optional.of(oralAnalysis));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.COMPLETED);
        assertThat(session.getCompletedAt()).isNotNull();
        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EE2-C3", "EO3-C1", "EE1-C1");
        assertThat(session.getSummaryJson().get("priority_skill_codes")).asList().hasSize(3);
        assertThat(writtenAttempt.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        assertThat(oralAttempt.getStatus()).isEqualTo(AttemptStatus.TERMINE);
        verify(sessionManager).save(session);
        verify(attemptManager).save(writtenAttempt);
        verify(attemptManager).save(oralAttempt);
    }

    @Test
    void uneSeuleAnalyseLaisseLaSessionAnalyzingEtLesAttemptsOuverts() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        when(submissionManager.findById(written.getId())).thenReturn(Optional.of(written));
        when(sessionManager.findByAttemptIdWithContent(writtenAttempt.getId()))
                .thenReturn(Optional.of(session));
        when(sessionManager.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));
        when(submissionManager.findByAttemptId(writtenAttempt.getId())).thenReturn(List.of(written));
        when(submissionManager.findByAttemptId(oralAttempt.getId())).thenReturn(List.of(oral));
        when(analysisManager.findBySubmissionId(written.getId()))
                .thenReturn(Optional.of(analysis(written, List.of())));
        when(analysisManager.findBySubmissionId(oral.getId())).thenReturn(Optional.empty());

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.ANALYZING);
        assertThat(session.getCompletedAt()).isNull();
        assertThat(writtenAttempt.getFinishedAt()).isNull();
        assertThat(oralAttempt.getFinishedAt()).isNull();
    }

    @Test
    void secondeSoumissionNeMasquePasLechecDeLaPremiere() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        written.setStatut(SubmissionStatut.FAILED);
        ProductionSubmission oral = submission(oralAttempt);
        oral.setStatut(SubmissionStatut.SUBMITTED);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        session.setStatus(DiagnosticSessionStatus.FAILED);
        session.setErrorMessage("Analyse écrite indisponible");

        when(submissionManager.findById(oral.getId())).thenReturn(Optional.of(oral));
        when(sessionManager.findByAttemptIdWithContent(oralAttempt.getId()))
                .thenReturn(Optional.of(session));
        when(sessionManager.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));
        when(submissionManager.findByAttemptId(writtenAttempt.getId())).thenReturn(List.of(written));
        when(submissionManager.findByAttemptId(oralAttempt.getId())).thenReturn(List.of(oral));

        coordinator.onAnalysisCompleted(oral.getId());

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.FAILED);
        assertThat(session.getErrorMessage()).isEqualTo("Analyse écrite indisponible");
        verify(sessionManager).save(session);
    }

    @Test
    void analysesAnciennesNeCompletentPasUneSoumissionEncoreEnCoursDeFinalisation() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        oral.setStatut(SubmissionStatut.SUBMITTED);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);

        when(submissionManager.findById(written.getId())).thenReturn(Optional.of(written));
        when(sessionManager.findByAttemptIdWithContent(writtenAttempt.getId()))
                .thenReturn(Optional.of(session));
        when(sessionManager.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));
        when(submissionManager.findByAttemptId(writtenAttempt.getId())).thenReturn(List.of(written));
        when(submissionManager.findByAttemptId(oralAttempt.getId())).thenReturn(List.of(oral));
        when(analysisManager.findBySubmissionId(written.getId()))
                .thenReturn(Optional.of(analysis(written, List.of())));
        when(analysisManager.findBySubmissionId(oral.getId()))
                .thenReturn(Optional.of(analysis(oral, List.of())));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.ANALYZING);
        assertThat(session.getCompletedAt()).isNull();
        assertThat(session.getSummaryJson()).isNull();
        assertThat(writtenAttempt.getFinishedAt()).isNull();
        assertThat(oralAttempt.getFinishedAt()).isNull();
    }

    private static Attempt attempt() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setStatus(AttemptStatus.EN_COURS);
        return attempt;
    }

    private static ProductionSubmission submission(Attempt attempt) {
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setAttempt(attempt);
        submission.setStatut(SubmissionStatut.EVALUATED);
        return submission;
    }

    private static DiagnosticSession session(Attempt written, Attempt oral) {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setWrittenAttempt(written);
        session.setOralAttempt(oral);
        session.setStatus(DiagnosticSessionStatus.IN_PROGRESS);
        return session;
    }

    private static DiagnosticProductionAnalysis analysis(
            ProductionSubmission submission, List<Map<String, Object>> priorities) {
        DiagnosticProductionAnalysis analysis = new DiagnosticProductionAnalysis();
        analysis.setSubmission(submission);
        Map<String, Object> json = new LinkedHashMap<>();
        json.put("strengths", List.of("Point fort"));
        json.put("skills", priorities);
        analysis.setAnalysisJson(json);
        return analysis;
    }

    private static Map<String, Object> priority(String code, String confidence) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("skill_code", code);
        item.put("priority", true);
        item.put("confidence", confidence);
        item.put("explanation", "À renforcer");
        return item;
    }
}
