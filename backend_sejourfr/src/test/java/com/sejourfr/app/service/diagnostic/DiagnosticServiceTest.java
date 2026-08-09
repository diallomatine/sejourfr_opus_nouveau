package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.DiagnosticSkillObservationDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.ProductionEvaluationService;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DiagnosticServiceTest {

    @Test
    void resultatSansPrioriteProposeQuandMemeUnMicroExerciceDisponible() {
        SkillManager skills = mock(SkillManager.class);
        SkillPromptManager prompts = mock(SkillPromptManager.class);
        DiagnosticService service = new DiagnosticService(
                new DiagnosticProperties(), mock(ProductionTaskManager.class),
                mock(DiagnosticSessionManager.class), mock(DiagnosticSessionCreator.class),
                mock(ProductionSubmissionManager.class),
                mock(DiagnosticProductionAnalysisManager.class), skills, prompts,
                mock(ProductionEvaluationService.class),
                mock(DiagnosticSessionCoordinator.class), mock(RateLimitGuard.class));

        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EE1-C1");
        skill.setTitle("Adapter son message au destinataire");
        skill.setSection(SkillSection.EE);
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setTitle("Écrire à un proche");
        when(skills.findByCode(skill.getCode())).thenReturn(Optional.of(skill));
        when(prompts.findActiveBySkillId(skill.getId())).thenReturn(List.of(prompt));

        DiagnosticSkillObservationDto solid = new DiagnosticSkillObservationDto(
                skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                true, LearningPlanSkillStatus.SOLID, "Bonjour Paul…",
                "Le destinataire est clairement pris en compte.",
                ObservationConfidence.HIGH, false);
        Map<String, DiagnosticSkillObservationDto> observations = new LinkedHashMap<>();
        observations.put(solid.skillCode(), solid);

        var action = service.recommendedAction(observations, List.of());

        assertThat(action).isNotNull();
        assertThat(action.skillPromptId()).isEqualTo(prompt.getId());
        assertThat(action.skillCode()).isEqualTo("EE1-C1");
        assertThat(action.estimatedMinutes()).isEqualTo(4);
    }
}
