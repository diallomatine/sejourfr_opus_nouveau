package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyCycleArchiveDto;
import com.sejourfr.app.dto.JourneyHistoryCycleDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>La consultation d'un cycle clos</b> — ce que sert
 * {@code GET /api/me/plan/journey/history/{journeyId}} a la page « Mes cycles »
 * (2026-09-27).
 *
 * <p>Ce qui est verrouille : un cycle clos est servi avec <b>ses</b> etapes,
 * comme le Plan, <b>sans aucun verrou ni aucune action</b> ; ses etats sont
 * ceux de ses clotures <b>persistees</b> (une etape restee ouverte est
 * {@code NON_FAITE}, jamais « a venir ») ; ce qu'ont donne ses examens est relu
 * chez leurs autorites ; et un candidat ne lit jamais le cycle — ni l'examen —
 * d'un autre.
 */
class JourneyCycleArchiveIT extends AbstractIntegrationTest {

    @Autowired private JourneyHistoryService historyService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private ThemeManager themeManager;
    @Autowired private TestData data;

    @Test
    @DisplayName("Un cycle clos est servi avec ses blocs et ses etapes, SANS verrou ni action")
    void unCycleClosEstServiSansVerrouNiAction() {
        User user = candidat();
        Journey cycle = cycleHistorise(user, jours(20), jours(2), JourneyFinDeCycle.ACTUALISATION);
        List<Skill> ee = expression(SkillTaskCode.EE1, 2);
        JourneyLot lot = lot(cycle, EpreuveType.TCF_EE);
        entrainement(cycle, lot, ee.get(0), true);
        entrainement(cycle, lot, ee.get(1), false);
        Attempt examenEe = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        examen(cycle, EpreuveType.TCF_EE, examenEe.getId());
        Attempt examenCo = data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.B2);
        examen(cycle, EpreuveType.TCF_CO, examenCo.getId());

        JourneyCycleArchiveDto vue = historyService.lireCycle(user.getId(), cycle.getId());

        assertThat(vue.journeyId()).isEqualTo(cycle.getId());
        assertThat(vue.numero()).isEqualTo(1);
        assertThat(vue.debut()).isEqualTo(cycle.getCreatedAt());
        assertThat(vue.fin()).isEqualTo(cycle.getHistoriseAt());
        // 🛑 Le geste qui l'a clos est LU (V077), jamais deduit.
        assertThat(vue.finDeCycle()).isEqualTo(JourneyFinDeCycle.ACTUALISATION);
        assertThat(vue.objectif().label()).isEqualTo("B2");

        // 🛑 Un bloc sans etape n'est pas servi, et l'ordre reste ORDRE (CO, CE,
        // EO, EE) : un cycle archive n'a plus rien « a faire ».
        assertThat(vue.blocs()).extracting(bloc -> bloc.bloc().code())
                .containsExactly(EpreuveType.TCF_CO.name(), EpreuveType.TCF_EE.name());

        JourneyBlocDto blocEe = vue.blocs().getLast();
        // 🛑 Une competence obligatoire restee ouverte : le bloc est INACHEVE,
        // jamais « en cours » ni « a venir ».
        assertThat(blocEe.status()).isEqualTo(JourneyBlocStatus.INACHEVE);
        assertThat(blocEe.meta()).isEqualTo("1/2 compétences travaillées · examen blanc passé");
        assertThat(blocEe.steps()).extracting(JourneyStepDto::status)
                .containsExactly(JourneyStepStatus.COMPLETED, JourneyStepStatus.NON_FAITE);
        assertThat(blocEe.steps().getFirst().closedAt()).isNotNull();
        assertThat(blocEe.steps().getLast().closedAt()).isNull();
        // Le niveau de l'examen est RELU chez l'autorite de l'epreuve.
        assertThat(blocEe.exam()).isNotNull();
        assertThat(blocEe.exam().resultat()).isNotNull();
        assertThat(blocEe.exam().resultat().niveau()).isEqualTo(NiveauCecrl.B1);

        JourneyBlocDto blocCo = vue.blocs().getFirst();
        assertThat(blocCo.status()).isEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(blocCo.meta()).isEqualTo("Examen blanc passé");
        assertThat(blocCo.exam().resultat().niveau()).isEqualTo(NiveauCecrl.B2);

        // 🛑 CONSULTATION : aucune etape ne porte de verrou, d'action ou de
        // progression — un cycle clos ne se rejoue pas.
        assertThat(toutesLesEtapes(vue)).isNotEmpty().allSatisfy(etape -> {
            assertThat(etape.locked()).isFalse();
            assertThat(etape.lockReason()).isNull();
            assertThat(etape.assessment()).isNull();
            assertThat(etape.exercise()).isNull();
            assertThat(etape.progress()).isNull();
            assertThat(etape.status())
                    .isNotIn(JourneyStepStatus.CURRENT, JourneyStepStatus.UPCOMING);
        });

        // L'avancement suit la MEME regle que le Plan.
        assertThat(vue.cycle().numero()).isEqualTo(1);
        assertThat(vue.cycle().etapesTerminees()).isEqualTo(3);
        assertThat(vue.cycle().etapesTotal()).isEqualTo(4);
        assertThat(vue.cycle().complete()).isFalse();
    }

    @Test
    @DisplayName("🛑 Isolation : le cycle d'un autre candidat, un cycle en cours ou en attente "
            + "rendent 404")
    void unCandidatNeLitQueSesCyclesClos() {
        User proprietaire = candidat();
        User intrus = candidat();
        Journey cycle = cycleHistorise(proprietaire, jours(20), jours(2), null);
        Journey enCours = data.journey(proprietaire, Module.TCF, JourneyStatus.EN_COURS);
        Journey attente = data.journey(proprietaire, Module.TCF, JourneyStatus.EN_ATTENTE);

        assertThatThrownBy(() -> historyService.lireCycle(intrus.getId(), cycle.getId()))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> historyService.lireCycle(proprietaire.getId(), enCours.getId()))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> historyService.lireCycle(proprietaire.getId(), attente.getId()))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> historyService.lireCycle(proprietaire.getId(), UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    @DisplayName("🛑 Isolation : l'examen d'un AUTRE candidat ne donne jamais de resultat")
    void lExamenDUnTiersNeSeLitJamais() {
        User user = candidat();
        User tiers = candidat();
        Journey cycle = cycleHistorise(user, jours(20), jours(2), null);
        Attempt examenDuTiers = data.examenQcmTcfPasse(tiers, EpreuveType.TCF_CO, NiveauCecrl.B2);
        examen(cycle, EpreuveType.TCF_CO, examenDuTiers.getId());

        JourneyCycleArchiveDto vue = historyService.lireCycle(user.getId(), cycle.getId());

        // L'etape reste close (c'est un fait persiste), mais son resultat est
        // inconnu : null, jamais le niveau d'un autre.
        assertThat(vue.blocs().getFirst().exam().status()).isEqualTo(JourneyStepStatus.COMPLETED);
        assertThat(vue.blocs().getFirst().exam().resultat()).isNull();
        // Et un cycle clos avant V077 garde une fin INCONNUE.
        assertThat(vue.finDeCycle()).isNull();
    }

    @Test
    @DisplayName("Le rang de la page est celui de la liste « Mes cycles »")
    void leRangEstCeluiDeLaListe() {
        User user = candidat();
        cycleHistorise(user, jours(40), jours(30), JourneyFinDeCycle.EXAMEN_COMPLET);
        Journey second = cycleHistorise(user, jours(29), jours(10), JourneyFinDeCycle.ACTUALISATION);
        examen(second, EpreuveType.TCF_CE, null);

        JourneyCycleArchiveDto vue = historyService.lireCycle(user.getId(), second.getId());
        JourneyHistoryCycleDto ligne = historyService.lire(user.getId(), Module.TCF).cycles()
                .stream().filter(c -> c.journeyId().equals(second.getId())).findFirst().orElseThrow();

        assertThat(vue.numero()).isEqualTo(2).isEqualTo(ligne.numero());
        assertThat(vue.cycle().numero()).isEqualTo(2);
        // Un examen jamais passe reste servi, NON_FAITE, sans resultat.
        assertThat(vue.blocs().getFirst().exam().status()).isEqualTo(JourneyStepStatus.NON_FAITE);
        assertThat(vue.blocs().getFirst().meta()).isEqualTo("Examen blanc non passé");
    }

    @Test
    @DisplayName("Civique : l'examen de theme donne son SCORE, jamais un palier")
    void lExamenDeThemeCiviqueDonneSonScore() {
        User user = candidat();
        Journey cycle = new Journey();
        cycle.setUser(user);
        cycle.setModule(Module.CIVIQUE);
        cycle.poserObjectif(TargetProcedure.NAT);
        cycle.setStatus(JourneyStatus.HISTORISE);
        cycle.setCreatedAt(jours(20));
        cycle.setUpdatedAt(jours(20));
        cycle.setHistoriseAt(jours(2));
        cycle.setFinDeCycle(JourneyFinDeCycle.ACTUALISATION);
        cycle = journeys.saveAndFlush(cycle);
        Theme theme = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).getFirst();

        Attempt examenTheme = data.attempt(user);
        examenTheme.setType(AttemptType.MOCK_EXAM);
        examenTheme.setMode(AttemptMode.EXAMEN);
        examenTheme.setStatus(AttemptStatus.TERMINE);
        examenTheme.setLotThemeId(theme.getId());
        examenTheme.setScore(17);
        examenTheme.setMaxScore(20);
        examenTheme.setFinishedAt(Instant.now());
        data.saveAttempt(examenTheme);

        JourneyStep step = new JourneyStep();
        step.setJourney(cycle);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(JourneyStepPurpose.REASSESS);
        step.poserBloc(theme);
        step.setPosition(cycle.consommerPosition());
        step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, examenTheme.getId(), Instant.now());
        journeys.saveAndFlush(cycle);
        steps.saveAndFlush(step);

        JourneyCycleArchiveDto vue = historyService.lireCycle(user.getId(), cycle.getId());

        assertThat(vue.blocs()).hasSize(1);
        JourneyBlocDto bloc = vue.blocs().getFirst();
        assertThat(bloc.bloc().code()).isEqualTo(theme.getCode());
        assertThat(bloc.meta()).isEqualTo("Examen passé");
        assertThat(bloc.exam().resultat().score()).isEqualTo(17);
        assertThat(bloc.exam().resultat().maxScore()).isEqualTo(20);
        assertThat(bloc.exam().resultat().niveau()).isNull();
        assertThat(vue.objectif().label()).isNotBlank();
    }

    // ------------------------------------------------------------- fabriques

    private static Stream<JourneyStepDto> etapesDe(JourneyBlocDto bloc) {
        return Stream.concat(bloc.steps().stream(),
                bloc.exam() == null ? Stream.empty() : Stream.of(bloc.exam()));
    }

    private static List<JourneyStepDto> toutesLesEtapes(JourneyCycleArchiveDto vue) {
        return vue.blocs().stream().flatMap(JourneyCycleArchiveIT::etapesDe).toList();
    }

    private User candidat() {
        User user = data.user();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private Journey cycleHistorise(
            User user, Instant creation, Instant historisation, JourneyFinDeCycle fin) {
        Journey journey = new Journey();
        journey.setUser(user);
        journey.setModule(Module.TCF);
        journey.setStatus(JourneyStatus.HISTORISE);
        journey.setTargetLevel(TargetLevel.B2);
        journey.setCreatedAt(creation);
        journey.setUpdatedAt(creation);
        journey.setHistoriseAt(historisation);
        journey.setFinDeCycle(fin);
        return journeys.saveAndFlush(journey);
    }

    private JourneyLot lot(Journey journey, EpreuveType epreuve) {
        JourneyLot lot = new JourneyLot();
        lot.setJourney(journey);
        lot.setExamType(epreuve);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        return lots.saveAndFlush(lot);
    }

    private void entrainement(Journey journey, JourneyLot lot, Skill competence, boolean close) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(lot.getExamType());
        step.setSkill(competence);
        step.setPosition(journey.consommerPosition());
        if (close) step.clore(JourneyStepResolution.QUOTA_REACHED, null, jours(5));
        journeys.saveAndFlush(journey);
        steps.saveAndFlush(step);
    }

    /** Un examen de bloc, clos par {@code parEvaluation} — ou ouvert si {@code null}. */
    private void examen(Journey journey, EpreuveType epreuve, UUID parEvaluation) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(JourneyStepPurpose.REASSESS);
        step.setExamType(epreuve);
        step.setPosition(journey.consommerPosition());
        if (parEvaluation != null) {
            step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, parEvaluation, jours(3));
        }
        journeys.saveAndFlush(journey);
        steps.saveAndFlush(step);
    }

    private List<Skill> expression(SkillTaskCode taskCode, int combien) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(taskCode);
        assertThat(seedees).as("referentiel seede pour " + taskCode).hasSizeGreaterThanOrEqualTo(combien);
        return seedees.subList(0, combien);
    }

    private static Instant jours(int combien) {
        return Instant.now().minus(combien, ChronoUnit.DAYS);
    }
}
