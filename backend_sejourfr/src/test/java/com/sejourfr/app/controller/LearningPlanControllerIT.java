package com.sejourfr.app.controller;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le Plan servi sur de vraies données : compteurs de progression et exercice
 * recommandé, calculés en base et non par le client.
 */
class LearningPlanControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private UserSkillAttemptManager attemptManager;
    @Autowired private LearningPlanObservationManager observationManager;
    @Autowired private DiagnosticSessionManager sessionManager;
    @Autowired private ProductionTaskManager taskManager;

    @Test
    void lePlanExposeLaProgressionReelleEtUnExerciceQuiAvance() throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE1);
        SkillPrompt premier = data.skillPrompt(skill);
        SkillPrompt second = data.skillPrompt(skill);
        SkillPrompt jamaisTente = data.skillPrompt(skill);

        // Un sujet validé, un sujet rendu sans analyse (« Fait »), un intact.
        analysed(data.userSkillAttempt(user, premier), SkillCriterionStatus.VALIDATED);
        data.userSkillAttempt(user, second);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").value("ACTIVE"))
                .andExpect(jsonPath("$.currentPriority.skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.currentPriority.promptCount").value(3))
                .andExpect(jsonPath("$.currentPriority.attemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.validatedCount").value(1))
                // Le sujet jamais traité, pas le rang 1 déjà validé.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(jamaisTente.getId().toString()))
                // 15-50 mots conseillés → 32 mots à 12 mots/minute.
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.estimatedMinutes")
                        .value(3))
                .andExpect(jsonPath("$.observedSkills[0].skillCode").value(skill.getCode()))
                .andExpect(jsonPath("$.observedSkills[0].promptCount").value(3))
                .andExpect(jsonPath("$.observedSkills[0].attemptedCount").value(2))
                .andExpect(jsonPath("$.observedSkills[0].validatedCount").value(1));
    }

    @Test
    void tousLesSujetsTraitesLePlanProposeCeluiARenforcerLePlusAncien() throws Exception {
        User user = data.user();
        Skill skill = data.skill(SkillTaskCode.EE2);
        SkillPrompt valide = data.skillPrompt(skill);
        SkillPrompt aRenforcer = data.skillPrompt(skill);

        analysed(data.userSkillAttempt(user, valide), SkillCriterionStatus.VALIDATED);
        analysed(data.userSkillAttempt(user, aRenforcer), SkillCriterionStatus.NOT_VALIDATED);
        observation(user, skill);
        completedSession(user);

        mvc.perform(get("/api/me/plan")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPriority.promptCount").value(2))
                .andExpect(jsonPath("$.currentPriority.attemptedCount").value(2))
                .andExpect(jsonPath("$.currentPriority.validatedCount").value(1))
                .andExpect(jsonPath("$.currentPriority.recommendedExercise.skillPromptId")
                        .value(aRenforcer.getId().toString()));
    }

    private void analysed(UserSkillAttempt attempt, SkillCriterionStatus criterion) {
        attempt.setAnalysisRequested(true);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        attemptManager.save(attempt);
    }

    private void observation(User user, Skill skill) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(user);
        observation.setSkill(skill);
        observation.setSourceType(LearningPlanSourceType.DIAGNOSTIC_EE);
        observation.setSourceId(UUID.randomUUID());
        observation.setObserved(true);
        observation.setStatus(LearningPlanSkillStatus.PRIORITY);
        observation.setEvidence("Bonjour Paul, je t'écris…");
        observation.setExplanation("Le destinataire n'est pas encore pris en compte.");
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setBaseline(true);
        observation.setObservedAt(Instant.now());
        observationManager.save(observation);
    }

    /** Le Plan n'est ACTIF qu'après un diagnostic terminé : on en pose un vrai. */
    private void completedSession(User user) {
        String code = "INITIAL_TCF";
        int version = taskManager.findLatestActiveDiagnosticVersion(code).orElseThrow();
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("priority_skill_codes", java.util.List.of());
        DiagnosticSession session = new DiagnosticSession();
        session.setUser(user);
        session.setDiagnosticCode(code);
        session.setDiagnosticVersion(version);
        session.setWrittenTask(taskManager
                .findActiveDiagnostic(code, version, EpreuveType.TCF_EE).orElseThrow());
        session.setOralTask(taskManager
                .findActiveDiagnostic(code, version, EpreuveType.TCF_EO).orElseThrow());
        session.setWrittenAttempt(data.attempt(user));
        session.setOralAttempt(data.attempt(user));
        session.setStatus(DiagnosticSessionStatus.COMPLETED);
        session.setSummaryJson(summary);
        session.setStartedAt(Instant.now().minusSeconds(600));
        session.setCompletedAt(Instant.now());
        sessionManager.saveAndFlush(session);
    }
}
