package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LearningPlanServiceTest {

    private ProductionTaskManager taskManager;
    private DiagnosticSessionManager sessionManager;
    private LearningPlanObservationManager observationManager;
    private RecommendedExerciseSelector exerciseSelector;
    private ReassessmentExerciseSelector reassessmentSelector;
    private SkillProgressCounter progressCounter;
    private SkillAccessService accessService;
    private LearningPlanService service;
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        sessionManager = mock(DiagnosticSessionManager.class);
        observationManager = mock(LearningPlanObservationManager.class);
        exerciseSelector = mock(RecommendedExerciseSelector.class);
        progressCounter = mock(SkillProgressCounter.class);
        accessService = mock(SkillAccessService.class);
        // Le resolveur de priorites est utilise POUR DE VRAI : c'est le meme
        // ordre que consomme SkillAccessService, on ne le double pas.
        when(accessService.resolve(userId))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        // Le moteur de maitrise tourne POUR DE VRAI, sur les memes observations
        // que le resolveur de priorites : c'est ce qui garantit qu'un candidat
        // ne lit pas « À renforcer » dans son Plan et « En consolidation » dans
        // le module Competences.
        LearningPlanProperties planProperties = new LearningPlanProperties();
        reassessmentSelector = mock(ReassessmentExerciseSelector.class);
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of());
        service = new LearningPlanService(new DiagnosticProperties(), taskManager,
                sessionManager, observationManager,
                new LearningPlanPriorityResolver(observationManager),
                exerciseSelector, reassessmentSelector, progressCounter,
                new SkillMasteryResolver(observationManager,
                        new SkillMasteryEngine(planProperties), planProperties),
                accessService);
    }

    @Test
    void sansSessionLeServeurDemandeLeDiagnostic() {
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.empty());

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.NEEDS_DIAGNOSTIC);
        assertThat(result.currentPriority()).isNull();
    }

    @Test
    void uneSessionExistanteEstRepriseSansPrioritesRecalculeesCoteFront() {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.of(session));

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.DIAGNOSTIC_IN_PROGRESS);
        assertThat(result.diagnosticSessionId()).isEqualTo(session.getId());
    }

    @Test
    void planActifGardeTroisPrioritesMaximumEtPreferePriorityAToReinforce() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now().minusSeconds(60));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));

        Instant now = Instant.now();
        LearningPlanObservation reinforceNewest = observation(
                "EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, now);
        LearningPlanObservation priorityOlder = observation(
                "EE1-C8", LearningPlanSkillStatus.PRIORITY, now.minusSeconds(60));
        LearningPlanObservation priorityThird = observation(
                "EO2-C3", LearningPlanSkillStatus.PRIORITY, now.minusSeconds(120));
        LearningPlanObservation reinforceFourth = observation(
                "EO3-C1", LearningPlanSkillStatus.TO_REINFORCE, now.minusSeconds(180));
        LearningPlanObservation solid = observation(
                "EO1-C1", LearningPlanSkillStatus.SOLID, now.minusSeconds(240));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                reinforceNewest, priorityOlder, priorityThird, reinforceFourth, solid));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C8");
        assertThat(result.nextPriorities()).hasSize(2);
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
        assertThat(result.observedSkillCount()).isEqualTo(5);
        assertThat(result.activitiesThisWeek()).isEqualTo(2);
    }

    @Test
    void seuleLaDerniereObservationDeChaqueCompetenceFaitFoi() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE2-C2");
        LearningPlanObservation latestSolid = observation(
                skill, LearningPlanSkillStatus.SOLID, Instant.now());
        LearningPlanObservation oldPriority = observation(
                skill, LearningPlanSkillStatus.PRIORITY, Instant.now().minusSeconds(600));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(latestSolid, oldPriority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNull();
        assertThat(result.nextPriorities()).isEmpty();
        assertThat(result.observedSkills()).singleElement()
                .extracting(item -> item.status())
                .isEqualTo(LearningPlanSkillStatus.SOLID);
    }

    @Test
    void absenceDePreuveRecenteNeffacePasUnePrioriteAnterieureObservee() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EO2-C1");
        LearningPlanObservation notObserved = observation(
                skill, LearningPlanSkillStatus.NOT_OBSERVED, Instant.now());
        notObserved.setObserved(false);
        notObserved.setEvidence(null);
        LearningPlanObservation oldPriority = observation(
                skill, LearningPlanSkillStatus.PRIORITY, Instant.now().minusSeconds(600));
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(notObserved, oldPriority));
        when(observationManager.countSince(any(), any())).thenReturn(1L);

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().skillCode()).isEqualTo("EO2-C1");
        assertThat(result.currentPriority().status()).isEqualTo(LearningPlanSkillStatus.PRIORITY);
        assertThat(result.observedSkillCount()).isEqualTo(1);
        assertThat(result.observedSkills()).singleElement()
                .extracting(item -> item.status())
                .isEqualTo(LearningPlanSkillStatus.PRIORITY);
    }

    /**
     * Les compteurs de COMPETENCE (15 sujets, semantique de {@code SkillDto})
     * et ceux de l'ETAPE (5 sujets) voyagent cote a cote : le Plan n'en
     * detourne aucun, sinon la fiche de competence et le Plan se
     * contrediraient sur une meme competence.
     */
    @Test
    void chaquePrioriteEtChaqueCompetenceObserveePorteSaProgressionReelle() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();
        stubProgress(priority, new SkillProgressCounter.SkillProgress(
                15, 4, 2, 2, new LearningPlanStep.Progress(5, 2, 1)));

        var result = service.get(userId);

        assertThat(result.currentPriority().promptCount()).isEqualTo(15);
        assertThat(result.currentPriority().attemptedCount()).isEqualTo(4);
        assertThat(result.currentPriority().validatedCount()).isEqualTo(2);
        assertThat(result.currentPriority().stepPromptCount()).isEqualTo(5);
        assertThat(result.currentPriority().stepAttemptedCount()).isEqualTo(2);
        assertThat(result.currentPriority().stepValidatedCount()).isEqualTo(1);
        assertThat(result.currentPriority().stepCompleted()).isFalse();
        // La carte « competence observee » n'est PAS une etape : elle garde les
        // seuls compteurs de competence, sans champ d'etape.
        assertThat(result.observedSkills()).singleElement().satisfies(skill -> {
            assertThat(skill.promptCount()).isEqualTo(15);
            assertThat(skill.attemptedCount()).isEqualTo(4);
            assertThat(skill.validatedCount()).isEqualTo(2);
        });
    }

    /**
     * Une etape terminee <b>reste affichee</b> : les priorites ne changent qu'a
     * l'arrivee d'une nouvelle observation, donc a la prochaine production. La
     * faire disparaitre se lirait comme un bug et priverait le candidat de son
     * resultat.
     */
    @Test
    void uneEtapeTermineeResteDansLePlan() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();
        stubProgress(priority, new SkillProgressCounter.SkillProgress(
                15, 5, 2, 3, new LearningPlanStep.Progress(5, 5, 2)));

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C4");
        assertThat(result.currentPriority().stepCompleted()).isTrue();
        // Terminee n'est pas « tout valide » — les deux restent distincts.
        assertThat(result.currentPriority().stepValidatedCount()).isEqualTo(2);
        // Et l'exercice recommande reste designe : rien ne s'eteint.
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
    }

    @Test
    void uneCompetenceSansSujetActifNaPasDeCompteurInvente() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EO3-C7", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        when(exerciseSelector.selectAll(eq(userId), anyCollection(), any())).thenReturn(Map.of());
        when(progressCounter.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of());

        var result = service.get(userId);

        assertThat(result.currentPriority().recommendedExercise()).isNull();
        assertThat(result.currentPriority().promptCount()).isZero();
        assertThat(result.currentPriority().attemptedCount()).isZero();
        assertThat(result.currentPriority().validatedCount()).isZero();
        assertThat(result.currentPriority().stepPromptCount()).isZero();
        assertThat(result.currentPriority().stepAttemptedCount()).isZero();
        assertThat(result.currentPriority().stepValidatedCount()).isZero();
        // Rien a faire n'est pas « fini » : une etape vide n'est jamais terminee.
        assertThat(result.currentPriority().stepCompleted()).isFalse();
    }

    /**
     * Le Plan reste INTEGRALEMENT visible pour un compte sans acces TCF : rien
     * n'est masque, ni une priorite, ni une competence observee, ni un
     * compteur. Seul {@code locked} passe a vrai — masquer priverait le candidat
     * du resultat de sa propre production.
     */
    @Test
    void sansAccesTcfLePlanResteVisibleEtSeContenteDePoserLeCadenas() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();
        // Rien d'ouvert : la competence de la priorite est verrouillee.
        when(accessService.resolve(userId)).thenReturn(
                new SkillAccessService.SkillAccess(false, Set.of(), Set.of()));

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C4");
        assertThat(result.currentPriority().locked()).isTrue();
        assertThat(result.observedSkills()).singleElement()
                .satisfies(skill -> assertThat(skill.locked()).isTrue());
        assertThat(result.observedSkillCount()).isEqualTo(1);
    }

    @Test
    void unAbonneTcfNaAucunCadenasSurSonPlan() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority().locked()).isFalse();
        assertThat(result.observedSkills()).singleElement()
                .satisfies(skill -> assertThat(skill.locked()).isFalse());
    }

    /**
     * L'etat de maitrise voyage avec la priorite, et il vient du MEME historique
     * que l'ordre des priorites. Les deux compteurs de sujets restent la : ils
     * servent l'anneau de progression, pas le verdict.
     */
    @Test
    void lePlanPorteLetatDeMaitriseEtLeSignalDeVerification() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE3-C2");
        Instant now = Instant.now();
        // Deux micro-exercices reussis sur des sujets differents : le candidat a
        // compris le moyen, il n'a pas encore prouve qu'il le transfere.
        LearningPlanObservation dernier = observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                now.minusSeconds(3600), LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        LearningPlanObservation precedent = observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                now.minusSeconds(7200), LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(dernier, precedent));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority().masteryState())
                .isEqualTo(SkillMasteryState.CONSOLIDATING);
        assertThat(result.currentPriority().readyForReassessment()).isTrue();
        assertThat(result.observedSkills()).singleElement()
                .satisfies(item -> assertThat(item.masteryState())
                        .isEqualTo(SkillMasteryState.CONSOLIDATING));
    }

    @Test
    void sansObservationExploitableAucunEtatDeMaitriseNestInvente() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE1-C4");
        // Une observation trop ancienne pour la fenetre du moteur, mais qui
        // reste la derniere preuve connue : la priorite s'affiche, l'etat non.
        LearningPlanObservation ancienne = observation(skill, LearningPlanSkillStatus.PRIORITY,
                Instant.now().minus(java.time.Duration.ofDays(400)),
                LearningPlanSourceType.DIAGNOSTIC_EE, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(ancienne));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().masteryState()).isNull();
        assertThat(result.currentPriority().readyForReassessment()).isFalse();
    }

    // ------------------------------------------------------------------------
    // L'etape change de NATURE, elle ne se dedouble pas
    // ------------------------------------------------------------------------

    @Test
    void quandLaCompetenceEstPreteLetapeProposeUneVerificationEnSituation() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        UUID sujetDeProduction = UUID.randomUUID();
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of(
                skill.getId(), PlanRecommendedExerciseDto.reassessment(
                        sujetDeProduction, skill.getId(), skill.getCode(), "Donner son opinion",
                        skill.getSection(), (short) 3, 7, false)));

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isTrue();
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.REASSESSMENT);
        assertThat(priority.recommendedExercise().productionTaskId()).isEqualTo(sujetDeProduction);
        assertThat(priority.recommendedExercise().skillPromptId()).isNull();
        assertThat(priority.recommendedExercise().estimatedMinutes()).isEqualTo(7);
    }

    /** Le sujet de verification est verrouille : il reste DESIGNE, avec son cadenas. */
    @Test
    void unSujetDeVerificationVerrouilleResteDesigne() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of(
                skill.getId(), PlanRecommendedExerciseDto.reassessment(
                        UUID.randomUUID(), skill.getId(), skill.getCode(), "Donner son opinion",
                        skill.getSection(), (short) 3, 7, true)));

        var exercise = service.get(userId).currentPriority().recommendedExercise();

        assertThat(exercise.kind()).isEqualTo(PlanExerciseKind.REASSESSMENT);
        assertThat(exercise.locked()).isTrue();
    }

    @Test
    void sansSujetPublieLetapeResteUnMicroExercice() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of());

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isTrue();
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.MICRO_TRAINING);
        assertThat(priority.recommendedExercise().skillPromptId()).isNotNull();
    }

    @Test
    void sansSignalAucuneVerificationNestMemeCherchee() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE1-C4");
        LearningPlanObservation baseline = observation(skill, LearningPlanSkillStatus.PRIORITY,
                Instant.now().minusSeconds(3600), LearningPlanSourceType.DIAGNOSTIC_EE,
                UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(baseline));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        stubExercisesForEverySkill();

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isFalse();
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.MICRO_TRAINING);
        verify(reassessmentSelector, never()).selectAll(any(), anyCollection());
    }

    // ------------------------------------------------------------------------
    // « Le Plan a change » apres une production
    // ------------------------------------------------------------------------

    @Test
    void uneProductionQuiConfirmeUneCompetenceLeDit() {
        UUID submissionId = UUID.randomUUID();
        Skill confirmee = skill("EE3-C2");
        LearningPlanObservation observation = observation(confirmee, LearningPlanSkillStatus.SOLID,
                Instant.now(), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        observation.setSourceId(submissionId);
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(observation));

        var change = service.changeAfterProduction(userId, submissionId);

        assertThat(change).isPresent();
        assertThat(change.get().confirmedSkill().skillId()).isEqualTo(confirmee.getId());
        assertThat(change.get().confirmedSkill().title()).isEqualTo(confirmee.getTitle());
        assertThat(change.get().newPriority()).isNull();
    }

    @Test
    void laNouvellePrioriteIssueDeCetteProductionEstAnnoncee() {
        UUID submissionId = UUID.randomUUID();
        Skill confirmee = skill("EE3-C2");
        Skill nouvelle = skill("EE3-C5");
        LearningPlanObservation solide = observation(confirmee, LearningPlanSkillStatus.SOLID,
                Instant.now(), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        solide.setSourceId(submissionId);
        LearningPlanObservation faiblesse = observation(nouvelle, LearningPlanSkillStatus.PRIORITY,
                Instant.now(), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        faiblesse.setSourceId(submissionId);
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(solide, faiblesse));

        var change = service.changeAfterProduction(userId, submissionId).orElseThrow();

        assertThat(change.confirmedSkill().skillId()).isEqualTo(confirmee.getId());
        assertThat(change.newPriority().skillId()).isEqualTo(nouvelle.getId());
    }

    /**
     * La course avec l'ecriture des observations (best-effort, hors transaction,
     * apres la correction) : le bloc est simplement <b>absent</b>, jamais une
     * erreur — la lecture suivante le rendra.
     */
    @Test
    void tantQueLesObservationsNeSontPasEcritesLeBlocEstAbsentSansErreur() {
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());

        assertThat(service.changeAfterProduction(userId, UUID.randomUUID())).isEmpty();
        assertThat(service.changeAfterProduction(userId, null)).isEmpty();
    }

    @Test
    void uneProductionQuiNeConfirmeRienEtNeChangeRienNaffichePasDeBloc() {
        UUID submissionId = UUID.randomUUID();
        Skill deja = skill("EE3-C2");
        // Cette production confirme le statut existant, mais la priorite n°1
        // vient d'une AUTRE production : rien de neuf a annoncer ici.
        LearningPlanObservation autrePriorite = observation(skill("EE1-C1"),
                LearningPlanSkillStatus.PRIORITY, Instant.now(),
                LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        autrePriorite.setSourceId(UUID.randomUUID());
        LearningPlanObservation celleCi = observation(deja, LearningPlanSkillStatus.TO_REINFORCE,
                Instant.now().minusSeconds(10), LearningPlanSourceType.PRODUCTION_EE,
                UUID.randomUUID());
        celleCi.setSourceId(submissionId);
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(autrePriorite, celleCi));

        assertThat(service.changeAfterProduction(userId, submissionId)).isEmpty();
    }

    /** Le diagnostic est la baseline : il ne « confirme » jamais rien. */
    @Test
    void uneObservationDeDiagnosticNeConfirmeJamais() {
        UUID submissionId = UUID.randomUUID();
        LearningPlanObservation baseline = observation(skill("EE1-C1"),
                LearningPlanSkillStatus.SOLID, Instant.now(),
                LearningPlanSourceType.DIAGNOSTIC_EE, UUID.randomUUID());
        baseline.setSourceId(submissionId);
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(baseline));

        assertThat(service.changeAfterProduction(userId, submissionId)).isEmpty();
    }

    /**
     * Historique d'un candidat qui a compris le moyen en cible (deux sujets
     * differents reussis) sans jamais l'avoir prouve en situation : c'est
     * exactement ce que le moteur appelle « pret a etre verifie ».
     */
    private void stubPlanPretAVerifier(Skill skill) {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Instant now = Instant.now();
        LearningPlanObservation dernier = observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                now.minusSeconds(3600), LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        LearningPlanObservation precedent = observation(skill, LearningPlanSkillStatus.TO_REINFORCE,
                now.minusSeconds(7200), LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(dernier, precedent));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();
    }

    private void stubProgress(
            LearningPlanObservation observation, SkillProgressCounter.SkillProgress progress) {
        Map<UUID, SkillProgressCounter.SkillProgress> counts = new LinkedHashMap<>();
        counts.put(observation.getSkill().getId(), progress);
        when(progressCounter.bySkillIds(eq(userId), anyCollection())).thenReturn(counts);
    }

    /** Le choix DU sujet est vérifié par {@code RecommendedExerciseSelectorTest}. */
    private void stubExercisesForEverySkill() {
        when(exerciseSelector.selectAll(eq(userId), anyCollection(), any()))
                .thenAnswer(invocation -> {
            Collection<Skill> skills = invocation.getArgument(1);
            Map<UUID, PlanRecommendedExerciseDto> exercises = new LinkedHashMap<>();
            for (Skill skill : skills) {
                exercises.put(skill.getId(), PlanRecommendedExerciseDto.microTraining(
                        UUID.randomUUID(), skill.getId(), skill.getCode(), "Exercice ciblé",
                        skill.getSection(), 3, false));
            }
            return exercises;
        });
    }

    private static LearningPlanObservation observation(
            String code, LearningPlanSkillStatus status, Instant at) {
        return observation(skill(code), status, at);
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, Instant at) {
        return observation(skill, status, at, LearningPlanSourceType.PRODUCTION_EE, null);
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, Instant at,
            LearningPlanSourceType source, UUID subjectId) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setObserved(true);
        observation.setStatus(status);
        observation.setSourceType(source);
        observation.setSubjectId(subjectId);
        observation.setExplanation("Explication serveur");
        observation.setEvidence("Preuve exacte");
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setObservedAt(at);
        return observation;
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(code.startsWith("EO") ? SkillSection.EO : SkillSection.EE);
        return skill;
    }
}
