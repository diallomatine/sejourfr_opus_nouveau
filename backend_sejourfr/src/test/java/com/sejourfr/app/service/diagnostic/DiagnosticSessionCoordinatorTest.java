package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticTaskSkillManager;
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
    private DiagnosticTaskSkillManager taskSkillManager;
    private DiagnosticReconciliationMetrics metrics;
    private DiagnosticSessionCoordinator coordinator;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        analysisManager = mock(DiagnosticProductionAnalysisManager.class);
        sessionManager = mock(DiagnosticSessionManager.class);
        attemptManager = mock(AttemptManager.class);
        taskSkillManager = mock(DiagnosticTaskSkillManager.class);
        // Compteurs reels : une derivation qui ne se compte pas est une
        // decision invisible.
        metrics = new DiagnosticReconciliationMetrics();
        coordinator = new DiagnosticSessionCoordinator(
                submissionManager, analysisManager, sessionManager, attemptManager,
                taskSkillManager, metrics);
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

    /**
     * Échouerait avec l'ancien départage alphabétique du code de compétence, qui
     * faisait toujours passer « EE… » devant « EO… ».
     */
    @Test
    void aConfianceEgaleLordreEditorialDeLallowlistLemporteSurLalphabet() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(priority("EE1-C1", "HIGH")), List.of(priority("EO1-C2", "HIGH")));
        when(taskSkillManager.findActiveByTaskId(session.getWrittenTask().getId()))
                .thenReturn(List.of(allowed("EE1-C1", 5)));
        when(taskSkillManager.findActiveByTaskId(session.getOralTask().getId()))
                .thenReturn(List.of(allowed("EO1-C2", 1)));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EO1-C2", "EE1-C1");
    }

    /**
     * Même confiance et même rang d'allowlist : le Plan alterne écrit et oral
     * plutôt que de servir un bloc de priorités d'une seule épreuve. L'ancien
     * tri alphabétique rendait ici {@code EE1-C1, EE1-C2, EO1-C1}.
     */
    @Test
    void aEgaliteResiduelleLesPrioritesAlternentEcritEtOral() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(priority("EE1-C1", "HIGH"), priority("EE1-C2", "HIGH")),
                List.of(priority("EO1-C1", "HIGH")));
        when(taskSkillManager.findActiveByTaskId(session.getWrittenTask().getId()))
                .thenReturn(List.of(allowed("EE1-C1", 1), allowed("EE1-C2", 2)));
        when(taskSkillManager.findActiveByTaskId(session.getOralTask().getId()))
                .thenReturn(List.of(allowed("EO1-C1", 2)));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EE1-C1", "EO1-C1", "EE1-C2");
    }

    /**
     * Le defaut mesure sur deux diagnostics reels : le correcteur range ses
     * faiblesses en {@code TO_REINFORCE} et ne pose jamais {@code PRIORITY}, si
     * bien que {@code priority_skill_codes} sortait vide et que le Plan restait
     * {@code ACTIVE} sans rien a faire. L'allowlist est ici a l'envers de
     * l'alphabet : un departage alphabetique rendrait {@code EE1-C1} en tete.
     */
    @Test
    void sansAucunePrioriteDesigneeLesFaiblessesObserveesEnTiennentLieu() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(faiblesse("EE1-C1", "MEDIUM"), faiblesse("EE1-C2", "HIGH"),
                        faiblesse("EE1-C3", "HIGH")),
                List.of());
        when(taskSkillManager.findActiveByTaskId(session.getWrittenTask().getId()))
                .thenReturn(List.of(allowed("EE1-C3", 1), allowed("EE1-C2", 2),
                        allowed("EE1-C1", 3)));

        coordinator.onAnalysisCompleted(written.getId());

        // Confiance d'abord (les deux HIGH passent devant la MEDIUM), puis rang
        // d'allowlist — jamais l'alphabet. Plafonne a 2 par production.
        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EE1-C3", "EE1-C2");
        assertThat(session.getSummaryJson().get("main_priority_explanation"))
                .isEqualTo("À renforcer");
        assertThat(metrics.compteurs())
                .containsEntry("PRIORITE_DERIVEE_DE_FAIBLESSE", 2L);
    }

    /** Ce que le correcteur designe l'emporte : on complete, on ne remplace pas. */
    @Test
    void unePrioriteDesigneeResteEnTeteEtLesFaiblessesCompletentJusquAuPlafond() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(priority("EE1-C9", "LOW"), faiblesse("EE1-C1", "HIGH"),
                        faiblesse("EE1-C2", "HIGH")),
                List.of());
        when(taskSkillManager.findActiveByTaskId(session.getWrittenTask().getId()))
                .thenReturn(List.of(allowed("EE1-C2", 1), allowed("EE1-C1", 2),
                        allowed("EE1-C9", 3)));

        coordinator.onAnalysisCompleted(written.getId());

        // La designee passe devant malgre sa confiance LOW ; une seule derivee
        // complete, le plafond par production valant 2.
        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EE1-C9", "EE1-C2");
        assertThat(metrics.compteurs())
                .containsEntry("PRIORITE_DERIVEE_DE_FAIBLESSE", 1L);
    }

    /** Rien a renforcer est un etat legitime : on ne fabrique pas une priorite. */
    @Test
    void queDesCompetencesSolidesNeFabriquentAucunePriorite() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(solide("EE1-C1"), nonObservee("EE1-C2")),
                List.of(solide("EO1-C1")));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.COMPLETED);
        assertThat(session.getSummaryJson().get("priority_skill_codes")).asList().isEmpty();
        assertThat(session.getSummaryJson().get("main_priority_explanation")).isNull();
        assertThat(metrics.compteurs()).doesNotContainKey("PRIORITE_DERIVEE_DE_FAIBLESSE");
    }

    /**
     * Les priorites derivees passent par la meme fusion : 2 par production, 3 au
     * total, et l'alternance ecrit/oral tient — un plan qui ne parlerait que
     * d'une seule epreuve serait faux.
     */
    @Test
    void lesPrioritesDeriveesRestentPlafonneesEtAlternentEcritEtOral() {
        Attempt writtenAttempt = attempt();
        Attempt oralAttempt = attempt();
        ProductionSubmission written = submission(writtenAttempt);
        ProductionSubmission oral = submission(oralAttempt);
        DiagnosticSession session = session(writtenAttempt, oralAttempt);
        stubCompleted(session, written, oral,
                List.of(faiblesse("EE1-C1", "HIGH"), faiblesse("EE1-C2", "HIGH"),
                        faiblesse("EE1-C3", "HIGH")),
                List.of(faiblesse("EO1-C1", "HIGH"), faiblesse("EO1-C2", "HIGH")));
        when(taskSkillManager.findActiveByTaskId(session.getWrittenTask().getId()))
                .thenReturn(List.of(allowed("EE1-C1", 1), allowed("EE1-C2", 2),
                        allowed("EE1-C3", 3)));
        when(taskSkillManager.findActiveByTaskId(session.getOralTask().getId()))
                .thenReturn(List.of(allowed("EO1-C1", 1), allowed("EO1-C2", 2)));

        coordinator.onAnalysisCompleted(written.getId());

        assertThat(session.getSummaryJson().get("priority_skill_codes"))
                .asList().containsExactly("EE1-C1", "EO1-C1", "EE1-C2");
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

    /** Les deux productions rendues, évaluées et analysées : l'assemblage peut se faire. */
    private void stubCompleted(
            DiagnosticSession session,
            ProductionSubmission written,
            ProductionSubmission oral,
            List<Map<String, Object>> writtenPriorities,
            List<Map<String, Object>> oralPriorities) {
        when(submissionManager.findById(written.getId())).thenReturn(Optional.of(written));
        when(sessionManager.findByAttemptIdWithContent(written.getAttempt().getId()))
                .thenReturn(Optional.of(session));
        when(sessionManager.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));
        when(submissionManager.findByAttemptId(written.getAttempt().getId()))
                .thenReturn(List.of(written));
        when(submissionManager.findByAttemptId(oral.getAttempt().getId()))
                .thenReturn(List.of(oral));
        when(analysisManager.findBySubmissionId(written.getId()))
                .thenReturn(Optional.of(analysis(written, writtenPriorities)));
        when(analysisManager.findBySubmissionId(oral.getId()))
                .thenReturn(Optional.of(analysis(oral, oralPriorities)));
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
        session.setWrittenTask(task());
        session.setOralTask(task());
        session.setStatus(DiagnosticSessionStatus.IN_PROGRESS);
        return session;
    }

    private static ProductionTask task() {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        return task;
    }

    /** Une entrée d'allowlist : la compétence et son rang éditorial sur le sujet. */
    private static DiagnosticTaskSkill allowed(String code, int order) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setActive(true);
        DiagnosticTaskSkill link = new DiagnosticTaskSkill();
        link.setSkill(skill);
        link.setDisplayOrder((short) order);
        return link;
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
        Map<String, Object> item = skill(code, confidence, "PRIORITY", true, true);
        item.put("explanation", "À renforcer");
        return item;
    }

    /** Ce que le correcteur produit reellement : une faiblesse, jamais une priorite. */
    private static Map<String, Object> faiblesse(String code, String confidence) {
        Map<String, Object> item = skill(code, confidence, "TO_REINFORCE", true, false);
        item.put("explanation", "À renforcer");
        return item;
    }

    private static Map<String, Object> solide(String code) {
        return skill(code, "HIGH", "SOLID", true, false);
    }

    private static Map<String, Object> nonObservee(String code) {
        return skill(code, "LOW", "NOT_OBSERVED", false, false);
    }

    private static Map<String, Object> skill(
            String code, String confidence, String status, boolean observed, boolean priority) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("skill_code", code);
        item.put("observed", observed);
        item.put("status", status);
        item.put("priority", priority);
        item.put("confidence", confidence);
        return item;
    }
}
