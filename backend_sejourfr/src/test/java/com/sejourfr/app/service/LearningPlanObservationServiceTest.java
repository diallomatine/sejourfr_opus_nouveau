package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LearningPlanObservationServiceTest {

    private LearningPlanObservationManager observationManager;
    private UserSkillAttemptManager skillAttemptManager;
    private LearningPlanObservationService service;

    @BeforeEach
    void setUp() {
        observationManager = mock(LearningPlanObservationManager.class);
        skillAttemptManager = mock(UserSkillAttemptManager.class);
        service = new LearningPlanObservationService(observationManager, skillAttemptManager);
    }

    @Test
    void uneSeuleReussiteMicroNeDeclareJamaisLaCompetenceSolide() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(saved.getValue().getStatus()).isNotEqualTo(LearningPlanSkillStatus.SOLID);
        assertThat(saved.getValue().getSourceType()).isEqualTo(LearningPlanSourceType.SKILL_TRAINING);
        assertThat(saved.getValue().isBaseline()).isFalse();
    }

    @Test
    void unMicroExerciceNonValideResteUnePriorite() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.NOT_VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
    }

    /**
     * Regle levee le 2026-08-12. Avant, rien n'etait enregistre tant qu'aucun
     * diagnostic n'etait termine : un candidat qui travaillait ses competences
     * sans passer le diagnostic n'accumulait aucun historique, et tout son
     * travail etait perdu le jour ou il le passait. C'est le PLAN qui reclame
     * encore un diagnostic pour s'activer, pas l'observation.
     */
    @Test
    void leSignalEstEnregistreMemeSansAucunDiagnostic() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        verify(observationManager).save(any());
    }

    /** Le SUJET, pas la tentative : c'est lui qui porte la diversite des contextes. */
    @Test
    void leSujetTravailleEstEnregistreAvecLeSignal() {
        UserSkillAttempt attempt = attempt(SkillCriterionStatus.VALIDATED);
        when(skillAttemptManager.findByIdWithPrompt(attempt.getId()))
                .thenReturn(Optional.of(attempt));
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordSkillAttempt(attempt.getId());

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getSubjectId())
                .isEqualTo(attempt.getSkillPrompt().getId())
                .isNotEqualTo(saved.getValue().getSourceId());
    }

    @Test
    void uneProductionDExamenBlancEstSourceeCommeTelle() {
        ProductionSubmission submission = submission(EpreuveType.TCF_EE);
        submission.getAttempt().setSlotNumber(1);
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordProduction(submission, List.of(skill()), analyse(), false);

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getSourceType())
                .isEqualTo(LearningPlanSourceType.MOCK_EXAM_EE);
        assertThat(saved.getValue().getSubjectId())
                .isEqualTo(submission.getProductionTask().getId());
    }

    /** Une epreuve d'examen blanc COMPLET est un sous-attempt, sans slot propre. */
    @Test
    void uneEpreuveDExamenCompletEstAussiUnExamenBlanc() {
        ProductionSubmission submission = submission(EpreuveType.TCF_EO);
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        submission.getAttempt().setParentAttempt(parent);
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordProduction(submission, List.of(skill()), analyse(), false);

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getSourceType())
                .isEqualTo(LearningPlanSourceType.MOCK_EXAM_EO);
    }

    @Test
    void uneProductionDEntrainementResteUneProductionStandard() {
        ProductionSubmission submission = submission(EpreuveType.TCF_EE);
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordProduction(submission, List.of(skill()), analyse(), false);

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getSourceType())
                .isEqualTo(LearningPlanSourceType.PRODUCTION_EE);
    }

    /**
     * Quand le correcteur pose {@code PRIORITY} — ce qu'il ne fait quasiment
     * jamais, d'ou la derivation cote diagnostic — le statut doit traverser la
     * chaine intact : c'est lui qui met la competence en tete du Plan, et la
     * contrainte {@code chk_learning_plan_observation_status} l'admet.
     */
    @Test
    void unStatutPrioritaireDuCorrecteurEstPersisteTelQuel() {
        ProductionSubmission submission = submission(EpreuveType.TCF_EE);
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordProduction(submission, List.of(skill()), analyse("PRIORITY"), true);

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(saved.getValue().getSourceType())
                .isEqualTo(LearningPlanSourceType.DIAGNOSTIC_EE);
        assertThat(saved.getValue().isBaseline()).isTrue();
    }

    /** Une faiblesse : c'est de CE statut que le Plan derive une priorite. */
    @Test
    void uneFaiblesseObserveeEstPersisteeCommeToReinforce() {
        ProductionSubmission submission = submission(EpreuveType.TCF_EO);
        when(observationManager.findBySource(any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        service.recordProduction(submission, List.of(skill()), analyse("TO_REINFORCE"), true);

        ArgumentCaptor<LearningPlanObservation> saved =
                ArgumentCaptor.forClass(LearningPlanObservation.class);
        verify(observationManager).save(saved.capture());
        assertThat(saved.getValue().getStatus()).isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(saved.getValue().isObserved()).isTrue();
    }

    private static Map<String, Object> analyse(String status) {
        return Map.of("skills", List.of(Map.of(
                "skill_code", "EE1-C1",
                "observed", true,
                "status", status,
                "evidence", "Je vous écris pour vous inviter à mon anniversaire.",
                "explanation", "Le destinataire n'est pas encore pris en compte.",
                "confidence", "HIGH")));
    }

    private static Map<String, Object> analyse() {
        return Map.of("skills", List.of(Map.of(
                "skill_code", "EE1-C1",
                "observed", true,
                "status", "SOLID",
                "evidence", "Je vous écris pour vous inviter à mon anniversaire.",
                "explanation", "Le message atteint son destinataire.",
                "confidence", "HIGH")));
    }

    private static Skill skill() {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EE1-C1");
        return skill;
    }

    private static ProductionSubmission submission(EpreuveType epreuve) {
        User user = new User();
        user.setId(UUID.randomUUID());
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(epreuve);
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        submission.setUser(user);
        submission.setProductionTask(task);
        submission.setAttempt(attempt);
        return submission;
    }

    private static UserSkillAttempt attempt(SkillCriterionStatus criterion) {
        User user = new User();
        user.setId(UUID.randomUUID());
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode("EE1-C1");
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setCriterionStatus(criterion);
        attempt.setWrittenProduction("Je donne une raison précise et un exemple.");
        attempt.setAnalysisJson(Map.of("improvement_priority", "Ajouter une conséquence."));
        attempt.setUpdatedAt(Instant.now());
        return attempt;
    }
}
