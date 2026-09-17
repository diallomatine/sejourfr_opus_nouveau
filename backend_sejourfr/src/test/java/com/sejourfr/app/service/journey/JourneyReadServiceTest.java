package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.service.LearningPlanStep;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.SkillAccessService;
import com.sejourfr.app.service.SkillProgressCounter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Ce que la LECTURE du parcours derive</b> — la ou {@code JourneyServiceIT}
 * verifie ce que les evaluations <b>ecrivent</b>.
 *
 * <p>Deux regles se testent ici et nulle part ailleurs, parce qu'elles portent
 * sur des cas que le referentiel seede ne sait pas produire a la demande :
 * <ul>
 *   <li>l'<b>exemption freemium</b> tombe sur l'etape qui prendra reellement la
 *       main, donc saute les etapes sans contenu comme le fait l'election de
 *       {@code CURRENT} ;</li>
 *   <li>une etape d'examen porte <b>sa</b> mesure, relayee du meme resolveur
 *       que partout ailleurs.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class JourneyReadServiceTest {

    @Mock private SkillAccessService accessService;
    @Mock private SkillProgressCounter progressCounter;
    @Mock private ProductionAccessService productionAccessService;
    @Mock private LearningPlanObservationManager observationManager;
    @Mock private NiveauActuelEpreuveResolver mesureResolver;

    private JourneyReadService service;
    private User user;
    private Journey journey;

    @BeforeEach
    void setUp() {
        TcfJourneyConfig config = new TcfJourneyConfig(
                1, 3, JourneyLotSelectionStrategy.TOP_SEVERITY, 2,
                new TcfJourneyConfig.Display(3, 5));
        service = new JourneyReadService(
                config, accessService, progressCounter, productionAccessService,
                observationManager, mesureResolver, new PlanDomainAssessmentResolver());
        user = new User();
        user.setId(UUID.randomUUID());
        journey = new Journey();
        journey.setId(UUID.randomUUID());
        journey.setUser(user);
        journey.setTargetLevel(TargetLevel.B2);
    }

    @Test
    @DisplayName("L'exemption freemium saute l'etape SANS CONTENU, comme l'election de CURRENT")
    void lExemptionTombeSurLEtapeQuiPrendLaMain() {
        Skill sansSujet = skill("EE1-C1", SkillTaskCode.EE1);
        Skill avecSujets = skill("EE2-C1", SkillTaskCode.EE2);
        UUID sujet = UUID.randomUUID();
        JourneyStep premiere = trainStep(sansSujet, 1);
        JourneyStep seconde = trainStep(avecSujets, 2);

        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                sansSujet.getId(), progres(List.of()),
                avecSujets.getId(), progres(List.of(sujet))));
        // Compte GRATUIT : seule la competence exemptee est ouverte.
        when(accessService.resolve(eq(user.getId()), any())).thenAnswer(invocation -> {
            UUID focus = invocation.getArgument(1);
            return new SkillAccessService.SkillAccess(
                    false,
                    focus == null ? Set.of() : Set.of(focus),
                    focus == null ? Set.of() : Set.of(sujet));
        });

        JourneyDto vue = service.lire(journey, List.of(premiere, seconde), true);

        ArgumentCaptor<UUID> focus = ArgumentCaptor.forClass(UUID.class);
        verify(accessService).resolve(eq(user.getId()), focus.capture());
        // 🛑 Sans ce saut, l'exemption tombait sur une competence qui n'a AUCUN
        // sujet publie — donc rien a ouvrir —, la main passait quand meme a
        // l'etape suivante, et le compte gratuit lisait une etape a laquelle il
        // n'avait pas acces.
        assertThat(focus.getValue()).isEqualTo(avecSujets.getId());
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().skillCode()).isEqualTo(avecSujets.getCode());
        // L'etape sans contenu reste AFFICHEE, a sa place : une etape ne se
        // cache pas (contradiction #1, tranchee le 2026-08-21).
        JourneyStepDto premiereVue = vue.steps().stream()
                .filter(step -> sansSujet.getCode().equals(step.skillCode()))
                .findFirst().orElseThrow();
        assertThat(premiereVue.status()).isNotEqualTo(JourneyStepStatus.CURRENT);
    }

    @Test
    @DisplayName("Une etape d'examen porte SA mesure, une etape d'entrainement n'en porte aucune")
    void seulesLesEtapesDExamenPortentUneMesure() {
        Skill competence = skill("CE1-C1", null);
        competence.setSection(SkillSection.CE);
        JourneyStep entrainement = trainStep(competence, 1);
        JourneyStep checkpoint = examStep(EpreuveType.TCF_CE, 2);

        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of());
        when(observationManager.findByUserAndSkillsSince(eq(user.getId()), any(), any()))
                .thenReturn(List.of());
        when(accessService.resolve(eq(user.getId()), any()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, List.of(entrainement, checkpoint), true);

        JourneyStepDto examen = vue.steps().stream()
                .filter(step -> step.type() == JourneyStepType.SECTION_EXAM)
                .findFirst().orElseThrow();
        assertThat(examen.assessment()).isNotNull();
        assertThat(examen.assessment().kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(examen.assessment().epreuve()).isEqualTo(EpreuveType.TCF_CE);
        assertThat(vue.steps().stream()
                .filter(step -> step.type() == JourneyStepType.TRAIN_SKILL)
                .findFirst().orElseThrow()
                .assessment()).isNull();
    }

    // ------------------------------------------------------------- fabriques

    private static SkillProgressCounter.SkillProgress progres(List<UUID> sujets) {
        return new SkillProgressCounter.SkillProgress(
                sujets.size(), 0, 0, 0,
                new LearningPlanStep.Progress(sujets, 0, 0));
    }

    private JourneyStep trainStep(Skill skill, long position) {
        JourneyStep step = new JourneyStep();
        step.setId(UUID.randomUUID());
        step.setJourney(journey);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(EpreuveType.TCF_EE);
        step.setSkill(skill);
        step.setPosition(position);
        step.setCreatedAt(Instant.now().minusSeconds(3_600));
        return step;
    }

    private JourneyStep examStep(EpreuveType epreuve, long position) {
        JourneyStep step = new JourneyStep();
        step.setId(UUID.randomUUID());
        step.setJourney(journey);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(JourneyStepPurpose.REASSESS);
        step.setExamType(epreuve);
        step.setPosition(position);
        step.setCreatedAt(Instant.now().minusSeconds(3_600));
        return step;
    }

    private static Skill skill(String code, SkillTaskCode taskCode) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(taskCode);
        skill.setTargetLevel("B2");
        skill.setDisplayOrder((short) 1);
        skill.setActive(true);
        return skill;
    }
}
