package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Quelle competence occupe la premiere place du Plan</b> — la seule autorite,
 * et celle dont {@code SkillAccessService} tire ce qu'il ouvre a un compte
 * gratuit.
 *
 * <p>Deux choses se verifient ici et nulle part ailleurs : la <b>regle</b> (une
 * fragilite passe devant une acquisition, mais une acquisition prend la place
 * quand il n'y a aucune fragilite) et le <b>cout</b> (le cycle de palier ne
 * tourne que dans ce second cas — sinon tous les ecrans de competences le
 * paieraient).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PlanFocusResolverTest {

    @Mock private LearningPlanObservationManager observationManager;
    @Mock private LearningPlanPriorityResolver priorityResolver;
    @Mock private DiagnosticSessionManager sessionManager;
    @Mock private UserManager userManager;
    @Mock private PlanCycleResolver cycleResolver;
    @Mock private PlanAcquisitionSelector acquisitionSelector;
    @Mock private PlanContentAvailability contentAvailability;

    private PlanFocusResolver resolver;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        resolver = new PlanFocusResolver(observationManager, priorityResolver,
                sessionManager, userManager, cycleResolver, acquisitionSelector,
                contentAvailability);
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(priorityResolver.actionable(anyList())).thenReturn(List.of());
        when(priorityResolver.lastActivityBySkill(anyList())).thenReturn(java.util.Map.of());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(userManager.findById(userId)).thenReturn(Optional.of(new User()));
        when(cycleResolver.resolve(any(), anyList(), anyList())).thenReturn(resolution());
        when(acquisitionSelector.select(any(), anyList(), anySet(), any(), any()))
                .thenReturn(List.of());
    }

    // ------------------------------------------------------------------------
    // La regle, sur des listes deja calculees (ce qu'utilise le Plan)
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une fragilite passe devant une acquisition")
    void uneFragilitePasseDevantUneAcquisition() {
        Skill fragile = skill("EE1-C1");
        Skill aAcquerir = skill("EE2-C4");

        assertThat(PlanFocusResolver.focus(
                List.of(observation(fragile)), List.of(aAcquerir)))
                .contains(fragile.getId());
    }

    /**
     * 🛑 Le cas que ce chantier corrige : sans fragilite, la premiere carte est
     * une competence <b>a acquerir</b> — et c'est elle que le freemium doit
     * ouvrir. Le proprietaire : « un candidat non abonne pourra travailler sa
     * priorite 1, vu qu'elle est visible ».
     */
    @Test
    @DisplayName("Sans fragilite, la premiere place revient a la premiere acquisition")
    void sansFragiliteLaPremiereAcquisitionPrendLaPlace() {
        Skill aAcquerir = skill("EE2-C4");

        assertThat(PlanFocusResolver.focus(List.of(), List.of(aAcquerir)))
                .contains(aAcquerir.getId());
    }

    @Test
    @DisplayName("Ni fragilite ni acquisition : aucune premiere place")
    void sansRienIlNyAAucunePremierePlace() {
        assertThat(PlanFocusResolver.focus(List.of(), List.of())).isEmpty();
    }

    // ------------------------------------------------------------------------
    // La meme regle en autonomie, et son cout
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le retour anticipe qui garde {@code SkillAccessService} au meme cout
     * qu'avant : une acquisition ne peut jamais passer devant une fragilite,
     * donc quand il y en a une, il n'y a rien a chercher plus loin.
     */
    @Test
    @DisplayName("Avec une fragilite, ni cycle de palier ni referentiel ne sont lus")
    void avecUneFragiliteLeCycleNeTournePas() {
        Skill fragile = skill("EE1-C1");
        when(priorityResolver.actionable(anyList()))
                .thenReturn(List.of(observation(fragile)));

        assertThat(resolver.currentFocusSkillId(userId)).contains(fragile.getId());

        verify(sessionManager, never()).findLatestCompleted(any());
        verify(cycleResolver, never()).resolve(any(), anyList(), anyList());
        verify(acquisitionSelector, never()).select(any(), anyList(), anySet(), any(), any());
    }

    /**
     * Le Plan ne designe aucune acquisition sans diagnostic termine : la
     * chercher quand meme ferait tourner le cycle sur tous les comptes neufs,
     * qui sont precisement ceux qui n'ont aucune fragilite.
     */
    @Test
    @DisplayName("Sans diagnostic termine, aucune acquisition n'est cherchee")
    void sansDiagnosticTermineAucuneAcquisitionNestCherchee() {
        assertThat(resolver.currentFocusSkillId(userId)).isEmpty();

        verify(cycleResolver, never()).resolve(any(), anyList(), anyList());
        verify(acquisitionSelector, never()).select(any(), anyList(), anySet(), any(), any());
    }

    @Test
    @DisplayName("Sans fragilite, la premiere acquisition du palier est designee")
    void sansFragiliteLAcquisitionEstDesignee() {
        Skill aAcquerir = skill("EE2-C4");
        when(sessionManager.findLatestCompleted(userId))
                .thenReturn(Optional.of(new DiagnosticSession()));
        when(acquisitionSelector.select(any(), anyList(), anySet(), any(), any()))
                .thenReturn(List.of(aAcquerir));

        assertThat(resolver.currentFocusSkillId(userId)).contains(aAcquerir.getId());
    }

    /** Rien a acquerir non plus : etat legitime, pas une anomalie. */
    @Test
    @DisplayName("Rien a reparer, rien a apprendre : aucune premiere place")
    void rienAReparerNiAApprendreNeDesigneRien() {
        when(sessionManager.findLatestCompleted(userId))
                .thenReturn(Optional.of(new DiagnosticSession()));

        assertThat(resolver.currentFocusSkillId(userId)).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    private static PlanCycleResolver.Resolution resolution() {
        return new PlanCycleResolver.Resolution(
                new PlanCycleDto(null, TargetLevel.B1, TargetLevel.B2,
                        PlanCycleState.TRAINING, 4, 4, true, List.of()),
                List.of(), List.of());
    }

    private static Skill skill(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setTargetLevel("B1");
        skill.setDisplayOrder((short) 1);
        skill.setActive(true);
        return skill;
    }

    private static LearningPlanObservation observation(Skill skill) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setSkill(skill);
        observation.setObserved(true);
        observation.setStatus(LearningPlanSkillStatus.TO_REINFORCE);
        observation.setSourceType(LearningPlanSourceType.PRODUCTION_EE);
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setEvidence("Preuve exacte");
        observation.setExplanation("Explication serveur");
        observation.setObservedAt(Instant.now().minus(1, ChronoUnit.DAYS));
        return observation;
    }
}
