package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.DiagnosticPlanPriorityDto;
import com.sejourfr.app.dto.DiagnosticSkillObservationDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.JourneyStepManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Les priorites du rapport, LUES sur le lot du Plan : quel cycle, quel ordre,
 * quel constat, et quand dire « deja dans votre plan ».
 */
class DiagnosticPlanPrioritiesTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID sessionId = UUID.randomUUID();
    private final JourneyStepManager steps = mock(JourneyStepManager.class);
    private final DiagnosticPlanPriorities reader = new DiagnosticPlanPriorities(steps);

    @Test
    @DisplayName("Sans lot : liste vide — jamais un repli")
    void sansLotListeVide() {
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId)).thenReturn(List.of());

        assertThat(reader.lire(userId, sessionId, Map.of())).isEmpty();
    }

    @Test
    @DisplayName("L'ordre de la file, rangs 1..n, constat joint par skillId (null s'il manque)")
    void ordreRangsEtConstats() {
        Journey enCours = cycle(JourneyStatus.EN_COURS);
        Skill premiere = skill("EE3-C3");
        Skill seconde = skill("EE3-C2");
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId)).thenReturn(List.of(
                etape(enCours, premiere, null), etape(enCours, seconde, null)));

        List<DiagnosticPlanPriorityDto> priorites = reader.lire(userId, sessionId,
                Map.of(premiere.getId(), constat(premiere, "Argument non développé.")));

        assertThat(priorites).extracting(DiagnosticPlanPriorityDto::skillCode)
                .containsExactly("EE3-C3", "EE3-C2");
        assertThat(priorites).extracting(DiagnosticPlanPriorityDto::rank).containsExactly(1, 2);
        assertThat(priorites.get(0).explanation()).isEqualTo("Argument non développé.");
        assertThat(priorites.get(1).explanation()).isNull();
        assertThat(priorites.get(0).generalCriterion()).isEqualTo("Critère de EE3-C3");
        assertThat(priorites.get(0).taskCode()).isEqualTo(SkillTaskCode.EE3);
        assertThat(priorites.get(0).section()).isEqualTo(SkillSection.EE);
        assertThat(priorites).allSatisfy(p -> assertThat(p.inCurrentCycle()).isTrue());
    }

    @Test
    @DisplayName("Plusieurs cycles : le cycle EN_COURS l'emporte sur un historisé plus récent")
    void leCycleEnCoursLEmporte() {
        Journey historise = cycle(JourneyStatus.HISTORISE);
        Journey enCours = cycle(JourneyStatus.EN_COURS);
        // Les etapes arrivent du cycle le plus recent au plus ancien.
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId)).thenReturn(List.of(
                etape(historise, skill("EE1-C8"), null),
                etape(enCours, skill("EE3-C3"), null)));

        assertThat(reader.lire(userId, sessionId, Map.of()))
                .extracting(DiagnosticPlanPriorityDto::skillCode).containsExactly("EE3-C3");
    }

    @Test
    @DisplayName("Lot en attente, ou étape rendue obsolète : pas « déjà dans votre plan »")
    void horsDuCycleCourant() {
        Journey attente = cycle(JourneyStatus.EN_ATTENTE);
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId))
                .thenReturn(List.of(etape(attente, skill("EE3-C3"), null)));
        assertThat(reader.lire(userId, sessionId, Map.of()))
                .singleElement().satisfies(p -> assertThat(p.inCurrentCycle()).isFalse());

        Journey enCours = cycle(JourneyStatus.EN_COURS);
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId)).thenReturn(List.of(
                etape(enCours, skill("EE3-C3"), JourneyStepResolution.SUPERSEDED),
                etape(enCours, skill("EE3-C2"), JourneyStepResolution.MASTERED)));
        assertThat(reader.lire(userId, sessionId, Map.of()))
                .extracting(DiagnosticPlanPriorityDto::inCurrentCycle).containsExactly(false, true);
    }

    @Test
    @DisplayName("Une compétence présente deux fois dans le cycle ne compte qu'une fois")
    void pasDeDoublon() {
        Journey enCours = cycle(JourneyStatus.EN_COURS);
        Skill meme = skill("EE3-C3");
        when(steps.findEntrainementsDeLEvaluation(userId, sessionId)).thenReturn(List.of(
                etape(enCours, meme, null), etape(enCours, meme, null)));

        assertThat(reader.lire(userId, sessionId, Map.of())).hasSize(1);
    }

    private static Journey cycle(JourneyStatus status) {
        Journey journey = new Journey();
        journey.setId(UUID.randomUUID());
        journey.setStatus(status);
        return journey;
    }

    private static JourneyStep etape(Journey journey, Skill skill, JourneyStepResolution resolution) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setSkill(skill);
        step.setResolution(resolution);
        return step;
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Titre " + code);
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.parse(code.substring(0, 3)));
        skill.setGeneralCriterion("Critère de " + code);
        return skill;
    }

    private static DiagnosticSkillObservationDto constat(Skill skill, String explication) {
        return new DiagnosticSkillObservationDto(skill.getId(), skill.getCode(), skill.getTitle(),
                skill.getSection(), true, LearningPlanSkillStatus.TO_REINFORCE, "Extrait.",
                explication, ObservationConfidence.MEDIUM, false);
    }
}
