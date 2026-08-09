package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.DiagnosticSkillObservationDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.ProductionEvaluationService;
import com.sejourfr.app.service.RecommendedExerciseSelector;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DiagnosticServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final SkillManager skills = mock(SkillManager.class);
    private final RecommendedExerciseSelector exerciseSelector =
            mock(RecommendedExerciseSelector.class);

    private final DiagnosticService service = new DiagnosticService(
            new DiagnosticProperties(), mock(ProductionTaskManager.class),
            mock(DiagnosticSessionManager.class), mock(DiagnosticSessionCreator.class),
            mock(ProductionSubmissionManager.class),
            mock(DiagnosticProductionAnalysisManager.class), skills, exerciseSelector,
            mock(ProductionEvaluationService.class),
            mock(DiagnosticSessionCoordinator.class), mock(RateLimitGuard.class));

    @Test
    void resultatSansPrioriteProposeQuandMemeUnMicroExerciceDisponible() {
        Skill skill = skill("EE1-C1");
        PlanRecommendedExerciseDto exercise = exercise(skill);
        when(skills.findByCodes(anyCollection())).thenReturn(Map.of(skill.getCode(), skill));
        when(exerciseSelector.selectAll(eq(userId), anyCollection()))
                .thenReturn(Map.of(skill.getId(), exercise));

        var action = service.recommendedAction(userId, observations(observed(skill)), List.of());

        assertThat(action).isNotNull();
        assertThat(action.skillPromptId()).isEqualTo(exercise.skillPromptId());
        assertThat(action.skillCode()).isEqualTo("EE1-C1");
        assertThat(action.estimatedMinutes()).isEqualTo(4);
    }

    @Test
    void laCompetenceSansSujetActifEstSauteeAuProfitDeLaSuivante() {
        Skill sansSujet = skill("EE1-C1");
        Skill avecSujet = skill("EO2-C3");
        PlanRecommendedExerciseDto exercise = exercise(avecSujet);
        when(skills.findByCodes(anyCollection())).thenReturn(Map.of(
                sansSujet.getCode(), sansSujet, avecSujet.getCode(), avecSujet));
        when(exerciseSelector.selectAll(eq(userId), anyCollection()))
                .thenReturn(Map.of(avecSujet.getId(), exercise));

        var action = service.recommendedAction(
                userId, observations(observed(sansSujet), observed(avecSujet)), List.of());

        assertThat(action.skillCode()).isEqualTo("EO2-C3");
    }

    private static Map<String, DiagnosticSkillObservationDto> observations(
            DiagnosticSkillObservationDto... items) {
        Map<String, DiagnosticSkillObservationDto> observations = new LinkedHashMap<>();
        for (DiagnosticSkillObservationDto item : items) {
            observations.put(item.skillCode(), item);
        }
        return observations;
    }

    private static DiagnosticSkillObservationDto observed(Skill skill) {
        return new DiagnosticSkillObservationDto(
                skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                true, LearningPlanSkillStatus.SOLID, "Bonjour Paul…",
                "Le destinataire est clairement pris en compte.",
                ObservationConfidence.HIGH, false);
    }

    private static PlanRecommendedExerciseDto exercise(Skill skill) {
        return new PlanRecommendedExerciseDto(
                UUID.randomUUID(), skill.getId(), skill.getCode(), "Écrire à un proche",
                skill.getSection(), 4);
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Adapter son message au destinataire");
        skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);
        return skill;
    }
}
