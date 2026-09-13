package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.PlanPinnedPriority;
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
import com.sejourfr.app.manager.PlanPinnedPriorityManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.progression.service.ProgressionPlanBridge;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.Mockito.mock;
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
    @Mock private PlanPinnedPriorityManager pinManager;

    private PlanFocusResolver resolver;

    /**
     * L'epingle de la premiere place, EN MEMOIRE : une map, pas un mock muet.
     * La stickiness se joue entre <b>deux</b> appels — c'est tout son objet — et
     * un {@code find()} qui rendrait toujours vide la rendrait intestable.
     */
    private final Map<UUID, PlanPinnedPriority> epingles = new HashMap<>();

    private final UUID userId = UUID.randomUUID();
    private User user;

    @BeforeEach
    void setUp() {
        resolver = new PlanFocusResolver(observationManager, priorityResolver,
                sessionManager, userManager, cycleResolver, acquisitionSelector,
                contentAvailability,
                new PlanDomainTargetLevelResolver(mock(ProgressionPlanBridge.class)),
                pinManager);
        user = new User();
        user.setId(userId);
        epingles.clear();
        when(pinManager.find(any())).thenAnswer(call ->
                Optional.ofNullable(epingles.get(call.<UUID>getArgument(0))));
        when(pinManager.save(any())).thenAnswer(call -> {
            PlanPinnedPriority pin = call.getArgument(0);
            epingles.put(pin.getUser().getId(), pin);
            return pin;
        });
        when(pinManager.release(any())).thenAnswer(call ->
                epingles.remove(call.<UUID>getArgument(0)) == null ? 0 : 1);
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());
        when(priorityResolver.actionable(anyList())).thenReturn(List.of());
        when(priorityResolver.lastActivityBySkill(anyList())).thenReturn(java.util.Map.of());
        when(sessionManager.findLatestCompleted(userId)).thenReturn(Optional.empty());
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        when(cycleResolver.resolve(any(), anyList(), anyList())).thenReturn(resolution());
        when(acquisitionSelector.select(anyList(), anySet(), anyMap(), any()))
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
        verify(acquisitionSelector, never()).select(anyList(), anySet(), anyMap(), any());
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
        verify(acquisitionSelector, never()).select(anyList(), anySet(), anyMap(), any());
    }

    @Test
    @DisplayName("Sans fragilite, la premiere acquisition du palier est designee")
    void sansFragiliteLAcquisitionEstDesignee() {
        Skill aAcquerir = skill("EE2-C4");
        when(sessionManager.findLatestCompleted(userId))
                .thenReturn(Optional.of(new DiagnosticSession()));
        when(acquisitionSelector.select(anyList(), anySet(), anyMap(), any()))
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
    // L'EPINGLE — une nouvelle observation ne deplace pas l'etape en cours
    // ------------------------------------------------------------------------

    /**
     * 🛑 Le cas reel qui a motive la regle (2026-09-13) : EE3 « Developper un
     * argument » etait la premiere place, a <b>0/5</b> ; une production EO1 l'a
     * remplacee sur-le-champ, parce que le classement se termine par la
     * <b>recence</b>. L'etape epinglee reste premiere.
     */
    @Test
    @DisplayName("Une nouvelle faiblesse ne remplace pas l'etape en cours")
    void uneNouvelleFaiblesseNeRemplacePasLetapeEnCours() {
        Skill ee3 = skill("EE3-C1");
        Skill eo1 = skill("EO1-C1");

        assertThat(resolver.epingler(user, List.of(ee3))).contains(ee3);

        // La production EO1 arrive et passe DEVANT au classement : plus recente.
        assertThat(resolver.epingler(user, List.of(eo1, ee3))).contains(ee3);
    }

    /**
     * La nouvelle faiblesse n'est pas perdue pour autant : elle reste dans le
     * pool que {@code PlanActionRanker} ordonne, donc dans la file d'attente.
     * Rien n'est persiste de cette file — ce test verrouille qu'on ne l'a pas
     * fabriquee ici.
     */
    @Test
    @DisplayName("La file d'attente reste derivee : rien d'autre que l'epingle n'est ecrit")
    void seuleLaPremierePlaceEstEcrite() {
        Skill ee3 = skill("EE3-C1");
        Skill eo1 = skill("EO1-C1");

        resolver.epingler(user, List.of(ee3));
        resolver.epingler(user, List.of(eo1, ee3));

        assertThat(epingles).hasSize(1);
        assertThat(epingles.get(userId).getSkill()).isEqualTo(ee3);
    }

    /**
     * Deux lectures sans action du candidat ne doivent rien reecrire :
     * {@code pinned_at} date la <b>prise</b> de la premiere place, pas la
     * derniere consultation du Plan. Sans cette regle, chaque {@code GET}
     * deviendrait un {@code UPDATE}.
     */
    @Test
    @DisplayName("Une epingle inchangee n'est pas reecrite")
    void uneEpingleInchangeeNestPasReecrite() {
        Skill ee3 = skill("EE3-C1");

        resolver.epingler(user, List.of(ee3));
        Instant premiere = epingles.get(userId).getPinnedAt();
        resolver.epingler(user, List.of(ee3));

        assertThat(epingles.get(userId).getPinnedAt()).isEqualTo(premiere);
        verify(pinManager, org.mockito.Mockito.times(1)).save(any());
    }

    /**
     * <b>La sortie de cycle n'est pas reecrite ici</b> : elle est deja portee
     * par {@code LearningPlanPriorityResolver.actionable}, qui ecarte une
     * competence dont la verification a ete rendue ou dont le transfert est
     * prouve. Sortie du pool, l'epingle est liberee et la meilleure en attente
     * est promue — <b>meme si la competence n'est pas SOLID</b>.
     */
    @Test
    @DisplayName("Sortie du pool, l'epingle est liberee et la suivante promue")
    void laSortieDuPoolLibereLepingle() {
        Skill ee3 = skill("EE3-C1");
        Skill eo1 = skill("EO1-C1");

        resolver.epingler(user, List.of(ee3, eo1));
        // EE3 a rendu sa verification : `actionable` ne la rend plus.
        assertThat(resolver.epingler(user, List.of(eo1))).contains(eo1);
        assertThat(epingles.get(userId).getSkill()).isEqualTo(eo1);
    }

    @Test
    @DisplayName("Plus aucune action : l'epingle est effacee, pas conservee")
    void plusAucuneActionEffaceLepingle() {
        Skill ee3 = skill("EE3-C1");

        resolver.epingler(user, List.of(ee3));
        assertThat(resolver.epingler(user, List.of())).isEmpty();
        assertThat(epingles).isEmpty();
    }

    /**
     * Le verrou commercial lit la <b>meme</b> premiere place que le Plan. S'il
     * lisait la tete du classement, un compte gratuit verrait son etape en cours
     * cadenassee des la production suivante — exactement ce que l'ouverture de
     * la priorite n&deg;1 existe pour eviter.
     */
    @Test
    @DisplayName("Le verrou commercial ouvre l'etape EPINGLEE, pas la plus recente")
    void leVerrouCommercialSuitLepingle() {
        Skill ee3 = skill("EE3-C1");
        Skill eo1 = skill("EO1-C1");
        resolver.epingler(user, List.of(ee3));
        when(priorityResolver.actionable(anyList()))
                .thenReturn(List.of(observation(eo1), observation(ee3)));

        assertThat(resolver.currentFocusSkillId(userId)).contains(ee3.getId());
    }

    /** Lecture seule : citer la premiere place ne la designe pas. */
    @Test
    @DisplayName("Le verrou commercial n'ecrit jamais d'epingle")
    void leVerrouCommercialNecritJamais() {
        Skill eo1 = skill("EO1-C1");
        when(priorityResolver.actionable(anyList())).thenReturn(List.of(observation(eo1)));

        assertThat(resolver.currentFocusSkillId(userId)).contains(eo1.getId());
        assertThat(epingles).isEmpty();
        verify(pinManager, never()).save(any());
    }

    /**
     * « Ce qui a change » et le retour de production nomment la priorite
     * n&deg;1 en toutes lettres : ils doivent nommer l'etape epinglee, pas la
     * tete du tri, sinon le texte annonce une carte que l'ecran ne montre pas.
     */
    @Test
    @DisplayName("La premiere place citee est l'etape epinglee, pas la plus recente")
    void lapremierePlaceCiteeEstLepingle() {
        Skill ee3 = skill("EE3-C1");
        Skill eo1 = skill("EO1-C1");
        resolver.epingler(user, List.of(ee3));
        LearningPlanObservation recente = observation(eo1);
        LearningPlanObservation ancienne = observation(ee3);

        assertThat(resolver.premierePlace(userId, List.of(recente, ancienne)))
                .isEqualTo(ancienne);
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
