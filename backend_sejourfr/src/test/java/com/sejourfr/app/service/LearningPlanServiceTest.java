package com.sejourfr.app.service;

import com.sejourfr.app.progression.service.ProgressionPlanBridge;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.PlanSeanceItemDto;
import com.sejourfr.app.enums.PlanActionNature;
import org.mockito.ArgumentCaptor;
import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LearningPlanServiceTest {

    private ProductionTaskManager taskManager;
    private DiagnosticSessionManager sessionManager;
    private LearningPlanObservationManager observationManager;
    private RecommendedExerciseSelector exerciseSelector;
    private ReassessmentExerciseSelector reassessmentSelector;
    private PlanMilestoneSelector milestoneSelector;
    private PlanAcquisitionSelector acquisitionSelector;
    private SkillProgressCounter progressCounter;
    private SkillAccessService accessService;
    private TcfProfileService profileService;
    private SkillManager skillManager;
    private User user;
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
        when(accessService.resolve(eq(userId), any()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        // Le moteur de maitrise tourne POUR DE VRAI, sur les memes observations
        // que le resolveur de priorites : c'est ce qui garantit qu'un candidat
        // ne lit pas « À renforcer » dans son Plan et « En consolidation » dans
        // le module Competences.
        LearningPlanProperties planProperties = new LearningPlanProperties();
        reassessmentSelector = mock(ReassessmentExerciseSelector.class);
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of());
        milestoneSelector = mock(PlanMilestoneSelector.class);
        acquisitionSelector = mock(PlanAcquisitionSelector.class);
        // Par defaut, RIEN a acquerir : la tres grande majorite de ces tests
        // decrivent la remediation, et un selecteur qui rendrait du contenu
        // ferait passer des competences supplementaires dans chaque assertion.
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of());
        when(milestoneSelector.select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any()))
                .thenReturn(Optional.empty());
        SkillMasteryResolver masteryResolver = new SkillMasteryResolver(observationManager,
                new SkillMasteryEngine(planProperties), planProperties);
        // Le cycle et les domaines tournent POUR DE VRAI : c'est lui qui decide
        // du gate, et le Plan ne doit pas pouvoir dire autre chose que lui.
        profileService = mock(TcfProfileService.class);
        skillManager = mock(SkillManager.class);
        when(profileService.levelProfile(userId)).thenReturn(profil(null, null, null, null));
        when(skillManager.findActiveComprehension()).thenReturn(List.of());
        when(skillManager.findActiveExpression()).thenReturn(List.of());
        UserManager userManager = mock(UserManager.class);
        user = new User();
        user.setId(userId);
        // Naturalisation : l'objectif du Plan vaut B2 parce que la DEMARCHE
        // l'exige, jamais parce qu'une constante le dit.
        user.setTargetProcedure(TargetProcedure.NAT);
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        service = new LearningPlanService(new DiagnosticProperties(), taskManager,
                sessionManager, observationManager,
                new LearningPlanPriorityResolver(observationManager, masteryResolver),
                exerciseSelector, reassessmentSelector, milestoneSelector, progressCounter,
                masteryResolver, accessService,
                new PlanCycleResolver(profileService, new ComprehensionLevelResolver(),
                mock(ProgressionPlanBridge.class),
                        masteryResolver, skillManager),
                // « Completer mon profil » tourne POUR DE VRAI : il ne fait que
                // lire les domaines que le cycle vient de resoudre, le doubler
                // reviendrait a tester le mock.
                new PlanDomainAssessmentResolver(),
                acquisitionSelector,
                // Les competences par epreuve tournent POUR DE VRAI : elles ne
                // font que ranger ce que le service vient de decider.
                new PlanDomainSkillResolver(),
                // La seance et le bloc « ce qui a change » tournent POUR DE VRAI :
                // ce sont des vues de ce que le service vient de decider, les
                // doubler reviendrait a tester le mock.
                new PlanSeanceBuilder(),
                new PlanRecentChangesResolver(new SkillMasteryEngine(planProperties)),
                userManager);
    }

    /** Un profil TCF, epreuve par epreuve ; {@code null} = jamais mesuree. */
    private static TcfLevelProfile profil(
            NiveauCecrl co, NiveauCecrl ce, NiveauCecrl ee, NiveauCecrl eo) {
        NiveauCecrl global = null;
        for (NiveauCecrl niveau : new NiveauCecrl[]{co, ce, ee, eo}) {
            if (niveau == null) continue;
            if (global == null || niveau.ordinal() < global.ordinal()) global = niveau;
        }
        return new TcfLevelProfile(co, ce, ee, eo, global);
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
    void planActifPrefereLesPrioritesAuxFaiblessesEtEcarteLeSolide() {
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
        // Quatre fragilites, un SOLID ecarte : le plafond de 5 ne coupe rien
        // ici, et rien n'est fabrique pour atteindre 5.
        assertThat(result.nextPriorities()).hasSize(3);
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
        assertThat(result.observedSkillCount()).isEqualTo(5);
        assertThat(result.activitiesThisWeek()).isEqualTo(2);
    }

    /**
     * Le defaut mesure : le correcteur ne pose jamais {@code PRIORITY}, il range
     * ses faiblesses en {@code TO_REINFORCE}. Le Plan doit designer une etape et
     * un exercice dans ce cas — sinon il reste {@code ACTIVE} sans rien a faire,
     * alors que l'ecran du diagnostic, lui, propose un exercice.
     *
     * <p>Et la <b>confiance</b> departage avant la recence, comme la regle du
     * diagnostic : les deux productions du diagnostic sont observees au meme
     * instant, la recence n'y trie rien.
     */
    @Test
    void sansAucunePrioriteDesigneeLesFaiblessesFontLetapeLaPlusSureEnTete() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Instant now = Instant.now();
        LearningPlanObservation recenteMoinsSure = observation(
                "EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, now);
        recenteMoinsSure.setConfidence(ObservationConfidence.MEDIUM);
        LearningPlanObservation ancienneSure = observation(
                "EO2-C4", LearningPlanSkillStatus.TO_REINFORCE, now.minusSeconds(3600));
        ancienneSure.setConfidence(ObservationConfidence.HIGH);
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(recenteMoinsSure, ancienneSure));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().skillCode()).isEqualTo("EO2-C4");
        assertThat(result.currentPriority().status())
                .isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
        assertThat(result.nextPriorities()).singleElement()
                .satisfies(next -> assertThat(next.skillCode()).isEqualTo("EE1-C1"));
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
                15, 4, 2, 2, etape(5, 2, 1)));

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
     * Le <b>perimetre</b> de l'etape voyage avec elle : un front qui ouvre la
     * competence depuis le Plan affiche ces sujets-la, dans cet ordre-la, au
     * lieu de retomber sur la fiche generique et son « 1/15 ». Il ne
     * reimplemente pas « les 5 premiers actifs » : deux copies finiraient par
     * designer deux etapes differentes.
     */
    @Test
    void lePerimetreDeLetapeEstServiAvecLaPriorite() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        List<UUID> sujets = List.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
                UUID.randomUUID(), UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();
        stubProgress(priority, new SkillProgressCounter.SkillProgress(
                15, 4, 2, 2, new LearningPlanStep.Progress(sujets, 2, 1)));

        var priorite = service.get(userId).currentPriority();

        assertThat(priorite.stepPromptIds()).containsExactlyElementsOf(sujets);
        assertThat(priorite.stepPromptCount()).isEqualTo(sujets.size());
    }

    /** Aucun sujet actif : liste vide, pas de denominateur invente, pas d'erreur. */
    @Test
    void uneCompetenceSansSujetActifRendUnPerimetreVide() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EO3-C7", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();
        when(progressCounter.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of());

        var priorite = service.get(userId).currentPriority();

        assertThat(priorite.stepPromptIds()).isEmpty();
        assertThat(priorite.stepPromptCount()).isZero();
        assertThat(priorite.stepCompleted()).isFalse();
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
                15, 5, 2, 3, etape(5, 5, 2)));

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
        when(accessService.resolve(eq(userId), any())).thenReturn(
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
        stubStep(skill, etape(5, 5, 2));
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

    /**
     * L'etape entiere traitee (5/5) et le signal du moteur : la carte bascule.
     * C'est le seul cas ou elle le fait, et il suppose un abonnement — les 5
     * sujets ne sont jouables qu'avec.
     */
    @Test
    void uneEtapeTermineeAvecLeSignalBasculeEnVerification() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        stubStep(skill, etape(5, 5, 4));
        UUID sujet = UUID.randomUUID();
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of(
                skill.getId(), PlanRecommendedExerciseDto.reassessment(
                        sujet, skill.getId(), skill.getCode(), "Donner son opinion",
                        skill.getSection(), (short) 3, 7, false)));

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isTrue();
        assertThat(priority.stepCompleted()).isTrue();
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.REASSESSMENT);
        assertThat(priority.recommendedExercise().productionTaskId()).isEqualTo(sujet);
    }

    /**
     * Le cas signale en production le 2026-08-14 : le moteur dit « pret », mais
     * l'etape n'est qu'a 2 sujets sur 5 (compte abonne, qui peut donc les jouer
     * tous). La carte ne bascule pas — proposer « verifier ma progression » sous
     * un anneau a 2/5 etait la contradiction a corriger.
     */
    @Test
    void uneEtapeInacheveeNeBasculePasEnVerification() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        stubStep(skill, etape(5, 2, 2));
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of(
                skill.getId(), PlanRecommendedExerciseDto.reassessment(
                        UUID.randomUUID(), skill.getId(), skill.getCode(), "Donner son opinion",
                        skill.getSection(), (short) 3, 7, false)));

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isFalse();
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.MICRO_TRAINING);
        verify(reassessmentSelector, never()).selectAll(any(), anyCollection());
    }

    /**
     * <b>CHOIX PRODUIT, pas un bug freemium</b> (arbitre le 2026-08-14) : la
     * verification de progression est PREMIUM. Un compte gratuit plafonne a 2
     * sujets sur les 5 de l'etape ; il a beau les avoir tous joues et remplir le
     * signal du moteur, l'etape n'est pas <b>terminee</b>, donc la carte reste un
     * micro-exercice. Consequences voulues : aucune de ses competences n'atteint
     * SOLID (la preuve contextualisee vient de cette verification), et il ne voit
     * donc pas non plus les jalons d'examen blanc. Ne pas « reparer » en comptant
     * les sujets que son acces lui ouvre.
     */
    @Test
    void unCompteGratuitNeBasculeJamaisEnVerificationCarElleEstPremium() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        // Les 2 sujets ouverts d'un compte gratuit, tous deux traites et valides.
        stubStep(skill, etape(5, 2, 2));
        when(reassessmentSelector.selectAll(eq(userId), anyCollection())).thenReturn(Map.of(
                skill.getId(), PlanRecommendedExerciseDto.reassessment(
                        UUID.randomUUID(), skill.getId(), skill.getCode(), "Donner son opinion",
                        skill.getSection(), (short) 3, 7, false)));

        var priority = service.get(userId).currentPriority();

        assertThat(priority.readyForReassessment()).isFalse();
        assertThat(priority.stepCompleted()).isFalse();
        assertThat(priority.stepAttemptedCount()).isEqualTo(2);
        assertThat(priority.stepPromptCount()).isEqualTo(5);
        assertThat(priority.recommendedExercise().kind())
                .isEqualTo(PlanExerciseKind.MICRO_TRAINING);
        verify(reassessmentSelector, never()).selectAll(any(), anyCollection());
    }

    // ------------------------------------------------------------------------
    // Une verification reussie fait passer a la competence suivante
    // ------------------------------------------------------------------------

    /**
     * « Une fois reussi, on passe a la competence suivante » : la competence dont
     * le transfert vient d'etre prouve en situation quitte les priorites, la
     * suivante prend l'etape n&deg;1. Elle reste <b>visible</b> parmi les
     * competences observees, avec son etat de maitrise — on ne cache jamais au
     * candidat le resultat de sa propre production.
     */
    @Test
    void unTransfertProuveLibereLetapePourLaCompetenceSuivante() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill reussie = skill("EE1-C1");
        Skill suivante = skill("EE1-C2");
        Instant now = Instant.now();
        LearningPlanObservation preuve = observation(reussie, LearningPlanSkillStatus.SOLID,
                now.minusSeconds(60), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        // Un micro-exercice rate APRES la preuve : sans la regle, il remettait la
        // competence en tete du Plan.
        LearningPlanObservation rechute = observation(reussie, LearningPlanSkillStatus.PRIORITY,
                now, LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        LearningPlanObservation aFaire = observation(suivante,
                LearningPlanSkillStatus.TO_REINFORCE, now.minusSeconds(3600),
                LearningPlanSourceType.DIAGNOSTIC_EE, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(rechute, preuve, aFaire));
        when(observationManager.countSince(any(), any())).thenReturn(3L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C2");
        assertThat(result.nextPriorities()).isEmpty();
        // Visible, jamais masquee : le Plan pose des cadenas, il ne cache rien.
        assertThat(result.observedSkills())
                .extracting(item -> item.skillCode())
                .containsExactlyInAnyOrder("EE1-C1", "EE1-C2");
        // Et l'etape franchie reste DANS le parcours, cochee, au lieu de
        // disparaitre : le candidat garde la trace de ce qu'il a passe.
        assertThat(result.completedSteps()).singleElement()
                .satisfies(step -> assertThat(step.skillCode()).isEqualTo("EE1-C1"));
    }

    // ------------------------------------------------------------------------
    // Les etapes FRANCHIES restent dans le parcours
    // ------------------------------------------------------------------------

    /**
     * Elles portent de quoi rendre la <b>meme carte</b> qu'une priorite : identite
     * de la competence et compteurs d'etape.
     */
    @Test
    void uneEtapeFranchiePorteSonIdentiteEtSesCompteursDetape() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill reussie = skill("EE1-C1");
        LearningPlanObservation preuve = observation(reussie, LearningPlanSkillStatus.SOLID,
                Instant.now(), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(preuve));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        stubExercisesForEverySkill();
        stubProgress(preuve, new SkillProgressCounter.SkillProgress(
                15, 5, 4, 1, etape(5, 5, 4)));

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNull();
        assertThat(result.completedSteps()).singleElement().satisfies(step -> {
            assertThat(step.skillId()).isEqualTo(reussie.getId());
            assertThat(step.skillCode()).isEqualTo("EE1-C1");
            assertThat(step.title()).isEqualTo(reussie.getTitle());
            assertThat(step.section()).isEqualTo(SkillSection.EE);
            assertThat(step.observedAt()).isEqualTo(preuve.getObservedAt());
            assertThat(step.stepPromptCount()).isEqualTo(5);
            assertThat(step.stepAttemptedCount()).isEqualTo(5);
            assertThat(step.stepValidatedCount()).isEqualTo(4);
            assertThat(step.stepPromptIds()).hasSize(5);
        });
        // Aucune requete ajoutee : les compteurs des etapes franchies sortent du
        // MEME appel groupe que ceux des priorites et des competences observees.
        verify(progressCounter).bySkillIds(eq(userId),
                argThat(ids -> ids.contains(reussie.getId())));
        verify(progressCounter, times(1)).bySkillIds(eq(userId), anyCollection());
        verify(observationManager, times(1)).findAllByUserWithSkill(userId);
    }

    /**
     * Elles s'accumulent sans fin : le parcours n'en publie que les plus
     * recentes, et les rend de la plus ancienne a la plus recente — le sens dans
     * lequel un parcours se lit.
     */
    @Test
    void lesEtapesFranchiesSontBorneesEtChronologiques() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Instant now = Instant.now();
        List<LearningPlanObservation> historique = new ArrayList<>();
        for (int rang = 0; rang < LearningPlanService.MAX_COMPLETED_STEPS + 3; rang++) {
            historique.add(observation(skill("EE1-C" + rang), LearningPlanSkillStatus.SOLID,
                    now.minusSeconds(60L * rang), LearningPlanSourceType.PRODUCTION_EE,
                    UUID.randomUUID()));
        }
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(historique);
        when(observationManager.countSince(any(), any())).thenReturn(8L);
        stubExercisesForEverySkill();

        var completedSteps = service.get(userId).completedSteps();

        assertThat(completedSteps).hasSize(LearningPlanService.MAX_COMPLETED_STEPS);
        assertThat(completedSteps).extracting(step -> step.skillCode())
                .containsExactly("EE1-C4", "EE1-C3", "EE1-C2", "EE1-C1", "EE1-C0");
        assertThat(completedSteps.getFirst().observedAt())
                .isBefore(completedSteps.getLast().observedAt());
    }

    @Test
    void sansAucuneEtapeFranchieLaListeEstVideJamaisNulle() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        LearningPlanObservation priority = observation(
                "EE1-C4", LearningPlanSkillStatus.PRIORITY, Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(priority));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();

        assertThat(service.get(userId).completedSteps()).isEmpty();
        // Et avant meme le diagnostic, le champ existe deja vide.
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.empty());
        assertThat(service.get(userId).completedSteps()).isEmpty();
    }

    /**
     * Non-regression : sortir des priorites n'est <b>pas</b> devenir {@code SOLID}
     * au sens du moteur. Le jalon continue de voir exactement les memes
     * competences qu'avant — son declencheur d'epreuve compte les competences
     * {@code SOLID}, et une seule preuve ne suffit pas a l'etre.
     */
    @Test
    void leJalonVoitTouteLhistoireMemeQuandUneCompetenceQuitteLesPriorites() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill reussie = skill("EE1-C1");
        Instant now = Instant.now();
        LearningPlanObservation preuve = observation(reussie, LearningPlanSkillStatus.SOLID,
                now.minusSeconds(60), LearningPlanSourceType.PRODUCTION_EE, UUID.randomUUID());
        LearningPlanObservation rechute = observation(reussie, LearningPlanSkillStatus.PRIORITY,
                now, LearningPlanSourceType.SKILL_TRAINING, UUID.randomUUID());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId))
                .thenReturn(List.of(rechute, preuve));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNull();
        // Une preuve n'est pas une maitrise installee : l'etat agrege ne ment pas.
        assertThat(result.observedSkills()).singleElement()
                .satisfies(item -> assertThat(item.masteryState())
                        .isNotEqualTo(SkillMasteryState.SOLID));
        verify(milestoneSelector).select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any());
    }

    // ------------------------------------------------------------------------
    // Le jalon, a cote des etapes
    // ------------------------------------------------------------------------

    @Test
    void leJalonEstServiACoteDesPrioritesSansLesRemplacer() {
        Skill skill = skill("EE3-C2");
        stubPlanPretAVerifier(skill);
        PlanRecommendedExerciseDto jalon = PlanRecommendedExerciseDto.epreuveMockExam(
                EpreuveType.TCF_EE, 1, 30, false);
        when(milestoneSelector.select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any()))
                .thenReturn(Optional.of(jalon));

        var result = service.get(userId);

        assertThat(result.milestone()).isEqualTo(jalon);
        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().recommendedExercise()).isNotNull();
    }

    @Test
    void sansJalonMeriteLeChampResteNull() {
        stubPlanPretAVerifier(skill("EE3-C2"));

        assertThat(service.get(userId).milestone()).isNull();
    }

    // ------------------------------------------------------------------------
    // Le cycle de palier et les quatre domaines
    // ------------------------------------------------------------------------

    /**
     * Le gate n'est pas servi a cote du jalon : il est <b>passe</b> au meme
     * selecteur, qui reste l'unique designateur d'un examen blanc. Deux surfaces
     * auraient fini par annoncer deux slots differents pour un seul examen.
     */
    @Test
    void leGateDePalierEstPasseAuSelecteurDeJalon() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        // Profil complet, plus aucune priorite : les trois conditions du brief.
        when(profileService.levelProfile(userId)).thenReturn(profil(
                NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(observationManager.countSince(any(), any())).thenReturn(0L);

        var result = service.get(userId);

        assertThat(result.cycle().state()).isEqualTo(PlanCycleState.READY_FOR_GATE_MOCK);
        assertThat(result.cycle().targetLevel()).isEqualTo(TargetLevel.B1);
        verify(milestoneSelector).select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                eq(true), any());
    }

    @Test
    void unePrioriteRestanteFermeLeGateDePalier() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId)).thenReturn(profil(
                NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE2-C5", LearningPlanSkillStatus.TO_REINFORCE, Instant.now())));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.cycle().state()).isEqualTo(PlanCycleState.TRAINING);
        verify(milestoneSelector).select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                eq(false), any());
    }

    /**
     * ARBITRAGE PRODUIT : la verification de progression est premium. Un compte
     * gratuit plafonne a 2 des 5 sujets d'une etape, donc aucune de ses
     * competences n'atteint {@code SOLID}, sa priorite ne sort jamais du Plan et
     * le gate reste ferme. C'est VOULU — ne pas le « reparer » en comptant les
     * sujets ouverts.
     */
    @Test
    void unCompteGratuitNeVoitJamaisLeGateDePalier() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Skill skill = skill("EE2-C5");
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId)).thenReturn(profil(
                NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation(skill, LearningPlanSkillStatus.TO_REINFORCE, Instant.now())));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        // Le plafond du freemium : 2 sujets sur 5, l'etape n'est jamais terminee.
        stubStep(skill, etape(5, 2, 2));
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.currentPriority().readyForReassessment()).isFalse();
        assertThat(result.cycle().state()).isNotEqualTo(PlanCycleState.READY_FOR_GATE_MOCK);
        verify(milestoneSelector).select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                eq(false), any());
    }

    /**
     * Le profil des quatre domaines ne depend pas du diagnostic : un candidat
     * qui a fait une serie de comprehension sans jamais passer le diagnostic
     * doit voir ce qu'il a mesure, et ce qui lui manque (brief §3, §6).
     */
    @Test
    void lesQuatreDomainesSontServisMemeSansDiagnostic() {
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.empty());
        when(profileService.levelProfile(userId))
                .thenReturn(profil(NiveauCecrl.B1, null, null, null));

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.NEEDS_DIAGNOSTIC);
        assertThat(result.domaines()).hasSize(4);
        assertThat(result.cycle().domainsEvaluated()).isEqualTo(1);
        assertThat(result.cycle().state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        // L'objectif suit la demarche (NAT), il n'est pas une constante.
        assertThat(result.cycle().objectiveLevel()).isEqualTo(TargetLevel.B2);
    }

    // ------------------------------------------------------------------------
    // Le diagnostic est PROGRESSIF : « Completer mon profil » (brief §3, §6, §7)
    // ------------------------------------------------------------------------

    /**
     * L'ecran d'onboarding du brief §6 : rien n'est mesure, et le Plan sait
     * pourtant quoi proposer sur les quatre domaines.
     */
    @Test
    void sansAucuneMesureLeProfilEntierResteAEvaluer() {
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.empty());

        var result = service.get(userId);

        assertThat(result.cycle().domainsEvaluated()).isZero();
        assertThat(result.cycle().profileComplete()).isFalse();
        assertThat(result.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        // Aucun diagnostic termine : l'expression passe par lui, la comprehension
        // par un examen blanc DEJA EXISTANT — aucun moteur n'est cree.
        assertThat(result.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::kind)
                .containsExactly(
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.MODULE_MOCK_EXAM,
                        PlanDomainAssessmentKind.DIAGNOSTIC,
                        PlanDomainAssessmentKind.DIAGNOSTIC);
    }

    /**
     * Brief §85-86 : un diagnostic ancien, EE + EO seulement, <b>reste
     * valide</b>. On ne force personne a le refaire — le Plan est ACTIF, et il
     * propose simplement de completer la comprehension.
     */
    @Test
    void unAncienDiagnosticEeEoResteValideEtLeProfilSeCompletePlusTard() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId))
                .thenReturn(profil(null, null, NiveauCecrl.A2, NiveauCecrl.A2));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(observationManager.countSince(any(), any())).thenReturn(0L);

        var result = service.get(userId);

        assertThat(result.state()).isEqualTo(LearningPlanState.ACTIVE);
        assertThat(result.cycle().domainsEvaluated()).isEqualTo(2);
        assertThat(result.domainesAEvaluer())
                .extracting(PlanDomainAssessmentDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE);
        // La session terminee ne se rejoue pas : c'est l'examen blanc de module
        // qui mesure, avec le slot offert.
        assertThat(result.domainesAEvaluer())
                .allSatisfy(item -> assertThat(item.slotNumber()).isEqualTo(1));
    }

    @Test
    void profilCompletDoncPlusRienAMesurer() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId)).thenReturn(profil(
                NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2, NiveauCecrl.A2));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(observationManager.countSince(any(), any())).thenReturn(0L);

        var result = service.get(userId);

        assertThat(result.cycle().profileComplete()).isTrue();
        assertThat(result.domainesAEvaluer()).isEmpty();
    }

    /**
     * 🛑 BRIEF §77. Le cas nomme par le brief : « EE solide, EO solide, CO non
     * evaluee, CE non evaluee ». Le selecteur de jalon, qui ne connait que
     * l'echelle des epreuves, designe l'examen blanc COMPLET ; le Plan le
     * refuse tant que les quatre domaines ne sont pas mesures — on ne confirme
     * pas un palier sur deux domaines sur quatre. Ce qui est mis en avant, c'est
     * « Completer mon profil ».
     */
    @Test
    void unProfilIncompletNePropoAucunExamenDePalier() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId))
                .thenReturn(profil(null, null, NiveauCecrl.B1, NiveauCecrl.B1));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        when(milestoneSelector.select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any()))
                .thenReturn(Optional.of(PlanRecommendedExerciseDto.fullTcfMockExam(1, 95, false)));

        var result = service.get(userId);

        assertThat(result.cycle().profileComplete()).isFalse();
        assertThat(result.cycle().state()).isEqualTo(PlanCycleState.BUILDING_BASELINE);
        assertThat(result.milestone()).isNull();
        assertThat(result.seance().items())
                .noneMatch(item -> item.exercise() != null
                        && item.exercise().kind() == PlanExerciseKind.FULL_TCF_MOCK_EXAM);
        assertThat(result.domainesAEvaluer()).hasSize(2);
    }

    /**
     * Le jalon d'EPREUVE, lui, n'est pas un controle de palier : il mesure une
     * seule epreuve et reste servi sur un profil incomplet.
     */
    @Test
    void leJalonDEpreuveSurvitAUnProfilIncomplet() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        PlanRecommendedExerciseDto jalon = PlanRecommendedExerciseDto.epreuveMockExam(
                EpreuveType.TCF_EE, 1, 30, false);
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(profileService.levelProfile(userId))
                .thenReturn(profil(null, null, NiveauCecrl.B1, NiveauCecrl.B1));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        when(milestoneSelector.select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any()))
                .thenReturn(Optional.of(jalon));

        assertThat(service.get(userId).milestone()).isEqualTo(jalon);
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
        // Etape TERMINEE : les 5 sujets traites. C'est la seconde condition de
        // la bascule, et seul un abonne peut la remplir (cf. le test de choix
        // produit plus haut).
        stubStep(skill, etape(5, 5, 5));
        stubExercisesForEverySkill();
    }

    // ------------------------------------------------------------------------
    // La seance du jour et « ce qui a change »
    // ------------------------------------------------------------------------

    /**
     * La seance est une <b>vue</b> des priorites : les memes competences, dans
     * le meme ordre, avec les exercices deja designes, et un total recalcule.
     */
    @Test
    void laSeanceRepublieLesPrioritesAvecLeurExerciceEtLeurTotal() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Instant now = Instant.now();
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.PRIORITY, now),
                observation("EO1-C2", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(60)),
                observation("EE2-C3", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(120)),
                observation("EO2-C4", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(180))));
        when(observationManager.countSince(any(), any())).thenReturn(4L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        // Trois priorites visibles, donc trois entrainements — pas quatre.
        assertThat(result.seance().items()).hasSize(PlanSeanceBuilder.MAX_ITEMS);
        assertThat(result.seance().items()).extracting("skillCode")
                .containsExactly("EE1-C1", "EO1-C2", "EE2-C3");
        // Chaque item porte l'exercice DEJA designe pour sa priorite.
        assertThat(result.seance().items().getFirst().exercise())
                .isEqualTo(result.currentPriority().recommendedExercise());
        // Total recalcule : 3 min par micro-exercice stube.
        assertThat(result.seance().estimatedMinutes()).isEqualTo(9);
    }

    /**
     * 🛑 La regle « sticky », vue du service : sans nouvelle observation, deux
     * lectures successives rendent <b>exactement</b> la meme seance. Rien ne
     * depend du jour.
     */
    @Test
    void deuxLecturesSuccessivesRendentLaMemeSeance() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        Instant now = Instant.now();
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.PRIORITY, now),
                observation("EO1-C2", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(60))));
        when(observationManager.countSince(any(), any())).thenReturn(2L);
        stubExercisesForEverySkill();

        var premiere = service.get(userId).seance();
        var seconde = service.get(userId).seance();

        assertThat(seconde.items()).extracting("skillCode")
                .isEqualTo(premiere.items().stream().map(item -> item.skillCode()).toList());
        assertThat(seconde.estimatedMinutes()).isEqualTo(premiere.estimatedMinutes());
    }

    /**
     * Le jalon <b>ferme</b> la seance depuis le 2026-08-21 : un examen blanc n'a
     * rien a prouver tant qu'une fragilite bloque, et a trois slots le mettre en
     * tete chassait le vrai travail de la journee.
     */
    @Test
    void leJalonFermeLaSeance() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.PRIORITY, Instant.now())));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        stubExercisesForEverySkill();
        PlanRecommendedExerciseDto jalon = PlanRecommendedExerciseDto.epreuveMockExam(
                EpreuveType.TCF_EE, 1, 30, false);
        when(milestoneSelector.select(eq(userId), anyCollection(), anyMap(), anyCollection(),
                anyBoolean(), any())).thenReturn(Optional.of(jalon));

        var result = service.get(userId);

        assertThat(result.seance().items()).hasSize(2);
        assertThat(result.seance().items().getLast().exercise()).isEqualTo(jalon);
        assertThat(result.seance().items().getLast().skillId()).isNull();
        assertThat(result.seance().items().getFirst().skillCode()).isEqualTo("EE1-C1");
        assertThat(result.seance().estimatedMinutes()).isEqualTo(33);
    }

    /** Sans diagnostic, il n'y a rien a faire aujourd'hui — et rien n'a change. */
    @Test
    void sansDiagnosticLaSeanceEstVideEtRienNaChange() {
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(taskManager.findLatestActiveDiagnosticVersion("INITIAL_TCF"))
                .thenReturn(Optional.of(1));
        when(sessionManager.findByUserAndVersionWithContent(userId, "INITIAL_TCF", 1))
                .thenReturn(Optional.empty());

        var result = service.get(userId);

        assertThat(result.seance()).isNotNull();
        assertThat(result.seance().items()).isEmpty();
        assertThat(result.seance().estimatedMinutes()).isZero();
        assertThat(result.recentChanges()).isNull();
    }

    /**
     * Une seule observation ancienne, jamais rejouee : rien n'a bouge, donc le
     * bloc est <b>absent</b>. C'est le cas normal, pas une erreur.
     */
    @Test
    void quandRienNaBougeLeBlocDesChangementsEstAbsent() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE,
                        Instant.now().minus(60, java.time.temporal.ChronoUnit.DAYS))));
        when(observationManager.countSince(any(), any())).thenReturn(0L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority()).isNotNull();
        assertThat(result.recentChanges()).isNull();
    }

    /**
     * Le bloc et {@code PlanChangeDto} ne peuvent pas designer deux etapes
     * n&deg;1 differentes : les deux lisent la meme autorite.
     */
    @Test
    void laNouvellePrioriteDuBlocEstCelleQuAfficheLePlan() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EO2-C4", LearningPlanSkillStatus.PRIORITY, Instant.now())));
        when(observationManager.countSince(any(), any())).thenReturn(1L);
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.recentChanges()).isNotNull();
        assertThat(result.recentChanges().transitions()).isEmpty();
        assertThat(result.recentChanges().newPriority().skillCode())
                .isEqualTo(result.currentPriority().skillCode());
    }

    /**
     * Une etape de {@code promptCount} sujets. <b>Le perimetre fait le
     * denominateur</b> : depuis que l'etape porte ses identifiants de sujets, il
     * n'existe plus de « 5 » qui ne serait adosse a aucun sujet reel.
     */
    private static LearningPlanStep.Progress etape(
            int promptCount, int attempted, int validated) {
        List<UUID> promptIds = new ArrayList<>();
        for (int rang = 0; rang < promptCount; rang++) {
            promptIds.add(UUID.randomUUID());
        }
        return new LearningPlanStep.Progress(promptIds, attempted, validated);
    }

    /** Compteurs d'etape d'une competence, sans passer par une observation. */
    private void stubStep(Skill skill, LearningPlanStep.Progress step) {
        Map<UUID, SkillProgressCounter.SkillProgress> counts = new LinkedHashMap<>();
        counts.put(skill.getId(), new SkillProgressCounter.SkillProgress(15, 2, 2, 0, step));
        when(progressCounter.bySkillIds(eq(userId), anyCollection())).thenReturn(counts);
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

    // ------------------------------------------------------------------------
    // Ce qu'il reste a APPRENDRE — la troisieme categorie du Plan
    // ------------------------------------------------------------------------

    /**
     * Le cas qui a ouvert le chantier, mesure sur un compte reel : six
     * competences ecrites solides, deux fragiles, l'oral jamais observe. Le Plan
     * ne montrait que <b>deux</b> actions a un candidat A2 visant le B2, a qui il
     * reste un palier entier a acquerir.
     *
     * <p>🛑 Les competences a acquerir arrivent <b>apres</b> les fragilites : on
     * repare ce qui bloque avant d'apprendre ce qui vient.
     */
    @Test
    void lesCompetencesAAcquerirCompletentLesFragilitesSansLesDevancer() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));

        Instant now = Instant.now();
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, now),
                observation("EE2-C3", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(60))));
        Skill aAcquerir = skill("EO1-C9");
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of(aAcquerir));
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.currentPriority().skillCode()).isEqualTo("EE1-C1");
        assertThat(result.nextPriorities()).extracting(LearningPlanPriorityDto::skillCode)
                .containsExactly("EE2-C3", "EO1-C9");
        assertThat(result.nextPriorities()).extracting(LearningPlanPriorityDto::nature)
                .containsExactly(PlanActionNature.A_RENFORCER, PlanActionNature.A_ACQUERIR);
    }

    /**
     * 🛑 Une competence a acquerir n'a <b>rien d'observe</b>, et le serveur
     * n'invente pas de verdict pour remplir un champ : <i>null = inconnu, jamais
     * mauvais</i>. Elle ne se dit <b>jamais</b> « a renforcer » — c'est la nature
     * qui la designe, jamais la nullite d'un champ.
     */
    @Test
    void uneCompetenceAAcquerirNaNiVerdictNiEtatDeMaitrise() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, Instant.now())));
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of(skill("EO1-C9")));
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.nextPriorities()).singleElement().satisfies(carte -> {
            assertThat(carte.nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
            assertThat(carte.status()).isNull();
            assertThat(carte.explanation()).isNull();
            assertThat(carte.evidence()).isNull();
            assertThat(carte.confidence()).isNull();
            assertThat(carte.observedAt()).isNull();
            assertThat(carte.masteryState()).isNull();
            assertThat(carte.readyForReassessment()).isFalse();
            assertThat(carte.recommendedExercise()).isNotNull();
        });
        // La fragilite, elle, garde son verdict : les deux vocabulaires coexistent.
        assertThat(result.currentPriority().nature())
                .isEqualTo(PlanActionNature.A_RENFORCER);
        assertThat(result.currentPriority().status())
                .isEqualTo(LearningPlanSkillStatus.TO_REINFORCE);
    }

    /**
     * 🛑 <b>Le plafond n'est pas un quota</b> : le selecteur ne recoit que les
     * places qui restent, et rien n'est fabrique pour les remplir. Une seule
     * competence vraiment a acquerir en rend une, pas cinq.
     */
    @Test
    void lesPlacesRestantesSontCellesQueLesFragilitesLaissent() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        Instant now = Instant.now();
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, now),
                observation("EE2-C3", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(60)),
                observation("EE3-C2", LearningPlanSkillStatus.TO_REINFORCE,
                        now.minusSeconds(120))));
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of());
        stubExercisesForEverySkill();

        var result = service.get(userId);

        ArgumentCaptor<Integer> limite = ArgumentCaptor.forClass(Integer.class);
        verify(acquisitionSelector).select(any(), anyList(), anySet(), limite.capture());
        assertThat(limite.getValue())
                .as("cinq places au total, trois fragilites : il en reste deux")
                .isEqualTo(LearningPlanPriorityResolver.MAX_PRIORITIES - 3);
        assertThat(result.nextPriorities()).hasSize(2);
    }

    /**
     * Une competence a acquerir dont <b>aucun sujet n'est publie</b> n'a rien a
     * proposer : elle n'entre pas dans le parcours. Jamais une carte sans action.
     */
    @Test
    void uneCompetenceAAcquerirSansExerciceNentrePasDansLePlan() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        LearningPlanObservation fragile =
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, Instant.now());
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(fragile));
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of(skill("EO1-C9")));
        // Seule la fragilite a un sujet publie.
        when(exerciseSelector.selectAll(eq(userId), anyCollection(), any()))
                .thenReturn(Map.of(fragile.getSkill().getId(),
                        PlanRecommendedExerciseDto.microTraining(
                                UUID.randomUUID(), fragile.getSkill().getId(), "EE1-C1",
                                "Petit sujet", SkillSection.EE, 4, false)));

        var result = service.get(userId);

        assertThat(result.nextPriorities()).isEmpty();
        assertThat(result.seance().items()).singleElement()
                .extracting(PlanSeanceItemDto::skillCode).isEqualTo("EE1-C1");
    }

    /**
     * 🛑 Le verrou freemium est <b>reporte, jamais applique a la designation</b> :
     * une competence a acquerir verrouillee est designee quand meme, avec son
     * cadenas. Savoir quoi travailler est ce que le Plan apporte.
     *
     * <p>Ici, elle occupe la 2&deg; place — la premiere revient a la fragilite.
     * C'est la place, pas la nature, qui ouvre.
     */
    @Test
    void uneCompetenceAAcquerirVerrouilleeEstDesigneeAvecSonCadenas() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        LearningPlanObservation fragile =
                observation("EE1-C1", LearningPlanSkillStatus.TO_REINFORCE, Instant.now());
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(fragile));
        Skill aAcquerir = skill("EO1-C9");
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of(aAcquerir));
        // Seule la premiere place est ouverte : c'est la fragilite.
        when(accessService.resolve(eq(userId), any())).thenReturn(
                new SkillAccessService.SkillAccess(
                        false, Set.of(fragile.getSkill().getId()), Set.of()));
        stubExercisesForEverySkill();

        var result = service.get(userId);

        assertThat(result.nextPriorities()).singleElement().satisfies(carte -> {
            assertThat(carte.skillCode()).isEqualTo("EO1-C9");
            assertThat(carte.nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
            assertThat(carte.locked())
                    .as("designee quand meme, mais fermee : le Plan se lit, il ne s'ouvre pas")
                    .isTrue();
        });
    }

    /**
     * 🛑 <b>Le defaut corrige le 2026-08-21.</b> Sans aucune fragilite, la
     * premiere carte du Plan est une competence <b>a acquerir</b> — jamais
     * travaillee, donc absente de l'historique, donc invisible pour l'ancien
     * {@code currentPrioritySkillId}. Elle etait designee, visible… et
     * verrouillee : le Plan promettait une action qu'un compte gratuit ne
     * pouvait pas commencer.
     *
     * <p>Ce que ce test verifie ici, c'est le <b>cablage</b> : le Plan transmet
     * au service d'acces la competence de sa premiere place, quelle que soit sa
     * nature. Que cette competence soit alors ouverte est verifie chez
     * {@code SkillAccessServiceTest}, et de bout en bout par
     * {@code LearningPlanAcquisitionIT}.
     */
    @Test
    void laPremierePlaceEstTransmiseAuVerrouMemeQuandCEstUneAcquisition() {
        DiagnosticSession completed = new DiagnosticSession();
        completed.setId(UUID.randomUUID());
        completed.setCompletedAt(Instant.now());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.of(completed));
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        Skill aAcquerir = skill("EO1-C9");
        when(acquisitionSelector.select(any(), anyList(), anySet(), anyInt()))
                .thenReturn(List.of(aAcquerir));
        when(accessService.resolve(eq(userId), any())).thenReturn(
                new SkillAccessService.SkillAccess(
                        false, Set.of(aAcquerir.getId()), Set.of()));
        stubExercisesForEverySkill();

        var result = service.get(userId);

        verify(accessService).resolve(userId, aAcquerir.getId());
        assertThat(result.currentPriority().skillCode()).isEqualTo("EO1-C9");
        assertThat(result.currentPriority().nature())
                .isEqualTo(PlanActionNature.A_ACQUERIR);
        assertThat(result.currentPriority().locked())
                .as("la premiere place se travaille toujours, quelle que soit sa nature")
                .isFalse();
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
