package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * <b>« X compétences maîtrisées »</b> — le compteur de la carte « Votre
 * progression », servi tel quel au web et au mobile.
 *
 * <p>🛑 <b>Le défaut du 2026-09-16.</b> Cet écran filtrait encore sur
 * {@code state() == SOLID} pendant que le Plan de la même app rangeait la
 * compétence dans {@code completedSteps} / {@code ACQUIS} sur
 * {@code transferProven()}. Le parcours <b>normal</b> — cinq petits sujets puis
 * une vérification réussie — plafonne autour de {@code 0,68} et n'atteint donc
 * jamais {@code SOLID} : le candidat lisait « 0 compétence maîtrisée » en face
 * d'un Plan qui en cochait plusieurs.
 *
 * <p>Une règle, une autorité : c'est {@link SkillMasteryEngine.SkillMastery#transferProven()}
 * qui dit « acquis », ici comme ailleurs.
 */
class ProgressServiceTest {

    private UserManager userManager;
    private LearningPlanObservationManager observationManager;
    private SkillMasteryResolver masteryResolver;
    private SubscriptionService subscriptionService;
    private ProgressService service;

    private final UUID userId = UUID.randomUUID();
    private User user;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        observationManager = mock(LearningPlanObservationManager.class);
        masteryResolver = mock(SkillMasteryResolver.class);
        subscriptionService = mock(SubscriptionService.class);

        service = new ProgressService(
                userManager,
                mock(AttemptManager.class),
                mock(TcfDiagnosticSessionManager.class),
                mock(TcfDiagnosticReadService.class),
                mock(TcfDiagnosticService.class),
                mock(TcfProfileService.class),
                mock(CivicDiagnosticSessionManager.class),
                mock(CivicDiagnosticViewService.class),
                mock(CivicPlanService.class),
                observationManager,
                masteryResolver,
                subscriptionService,
                mock(ActiviteResolver.class));

        user = new User();
        user.setId(userId);
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        // Abonne : le DETAIL est servi, donc le test voit aussi QUELLES
        // competences sont tenues, pas seulement combien.
        when(subscriptionService.hasTcf(userId)).thenReturn(true);
    }

    /**
     * 🛑 Le cas du parcours normal : le transfert est prouvé, l'état agrégé ne
     * dit que {@code CONSOLIDATING}. La compétence est maîtrisée.
     */
    @Test
    @DisplayName("Transfert prouve sans SOLID : la competence compte comme maitrisee")
    void leTransfertProuveCompteMemeSansSolid() {
        Skill tenue = competence("EE1_ARGUMENTER", "Argumenter", SkillSection.EE);
        Skill fragile = competence("EO2_RACONTER", "Raconter", SkillSection.EO);
        Instant preuve = Instant.now().minus(2, ChronoUnit.DAYS);

        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation(tenue, LearningPlanSkillStatus.SOLID, preuve),
                observation(fragile, LearningPlanSkillStatus.PRIORITY, preuve)));
        when(masteryResolver.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of(
                tenue.getId(), moteur(SkillMasteryState.CONSOLIDATING, true),
                fragile.getId(), moteur(SkillMasteryState.TO_REINFORCE, false)));

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isEqualTo(2);
        assertThat(competences.maitrisees()).isEqualTo(1);
        assertThat(competences.dernieres())
                .extracting(ProgressDto.CompetenceAcquise::code)
                .containsExactly("EE1_ARGUMENTER");
        // La date servie reste celle de la derniere observation SOLID : c'est
        // la preuve, et elle existe forcement — `transferProven` par la seconde
        // voie exige justement une reussite contextualisee.
        assertThat(competences.dernieres().getFirst().preuveA()).isEqualTo(preuve);
    }

    /** {@code SOLID} implique {@code transferProven} : rien ne se perd. */
    @Test
    @DisplayName("SOLID compte toujours, et une competence sans preuve ne compte pas")
    void solidCompteToujoursEtLeResteNon() {
        Skill solide = competence("CE1_LIRE", "Lire", SkillSection.CE);
        Skill jamaisTenue = competence("CO1_ECOUTER", "Ecouter", SkillSection.CO);

        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of(
                observation(solide, LearningPlanSkillStatus.SOLID, Instant.now()),
                observation(jamaisTenue, LearningPlanSkillStatus.TO_REINFORCE, Instant.now())));
        when(masteryResolver.bySkillIds(eq(userId), anyCollection())).thenReturn(Map.of(
                solide.getId(), moteur(SkillMasteryState.SOLID, true),
                jamaisTenue.getId(), SkillMasteryEngine.SkillMastery.NONE));

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isEqualTo(2);
        assertThat(competences.maitrisees()).isEqualTo(1);
    }

    /** Sans aucune observation, on ne conclut rien — et on n'invente aucun compteur. */
    @Test
    @DisplayName("Aucune observation : deux zeros, pas une estimation")
    void aucuneObservation() {
        when(observationManager.findAllByUserWithSkill(userId)).thenReturn(List.of());

        ProgressDto.Competences competences = service.progres(userId).tcf().competences();

        assertThat(competences.travaillees()).isZero();
        assertThat(competences.maitrisees()).isZero();
        assertThat(competences.dernieres()).isEmpty();
    }

    // ------------------------------------------------------------------------

    private static Skill competence(String code, String titre, SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle(titre);
        skill.setSection(section);
        return skill;
    }

    private static LearningPlanObservation observation(
            Skill skill, LearningPlanSkillStatus status, Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setObservedAt(quand);
        return observation;
    }

    private static SkillMasteryEngine.SkillMastery moteur(
            SkillMasteryState state, boolean transferProven) {
        return new SkillMasteryEngine.SkillMastery(
                state, 0, 0, 0, 0, 0, false, false, transferProven, false, null);
    }
}
