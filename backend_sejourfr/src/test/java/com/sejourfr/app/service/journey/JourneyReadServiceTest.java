package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import com.sejourfr.app.enums.JourneyProgressUnit;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.PlanDomainAssessmentKind;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.service.LearningPlanStep;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.RecommendedExerciseSelector;
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
 * <p>Trois regles se testent ici et nulle part ailleurs, parce qu'elles portent
 * sur des cas que le referentiel seede ne sait pas produire a la demande :
 * <ul>
 *   <li><b>D-18</b> — un compte gratuit n'a <b>aucune</b> etape executable, donc
 *       {@code current == null} et {@link JourneyState#LOCKED} est permanent,
 *       <b>sans qu'aucune donnee ne disparaisse</b> ;</li>
 *   <li>une etape d'examen porte <b>sa</b> mesure, relayee du meme resolveur
 *       que partout ailleurs ;</li>
 *   <li><b>D-16</b> — le quota d'une etape de comprehension : 2 series
 *       <b>reussies</b>, ou 4 <b>terminees</b>, et ce que le {@code progress}
 *       servi en dit.</li>
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
    @Mock private JourneyManager journeyManager;
    @Mock private RecommendedExerciseSelector exerciseSelector;

    private JourneyReadService service;
    private User user;
    private Journey journey;

    @BeforeEach
    void setUp() {
        TcfJourneyConfig config = new TcfJourneyConfig(
                1, 3, JourneyLotSelectionStrategy.TOP_SEVERITY, 2, 4,
                new TcfJourneyConfig.Display(3, 5));
        service = new JourneyReadService(
                config, accessService, progressCounter, productionAccessService,
                observationManager, mesureResolver, new PlanDomainAssessmentResolver(),
                new JourneyBlocResolver(), journeyManager, exerciseSelector);
        // 🛑 Les blocs interrogent « cette epreuve a-t-elle deja ete mesuree ? »
        // chez son unique autorite. Par defaut : aucune mesure.
        when(mesureResolver.mesure(any(), any()))
                .thenReturn(NiveauActuelEpreuveResolver.Mesure.AUCUNE);
        user = new User();
        user.setId(UUID.randomUUID());
        journey = new Journey();
        journey.setId(UUID.randomUUID());
        journey.setUser(user);
        journey.setTargetLevel(TargetLevel.B2);
        journey.setModule(Module.TCF);
    }

    /**
     * 🛑 <b>D-18 — l'exemption freemium est REVOQUEE.</b> Ce test verifiait que
     * l'ouverture d'office de la premiere etape tombait sur l'etape qui prendrait
     * reellement la main (donc sautait les etapes sans contenu). Il n'y a plus
     * d'ouverture d'office : la surcharge {@code resolve(userId, focus)} est
     * supprimee, et {@code JourneyReadService} lit l'acces <b>tel quel</b>.
     *
     * <p>Consequence <b>voulue</b> : {@code current == null},
     * {@code state = LOCKED} en permanence, la carte « À faire maintenant »
     * nomme la premiere etape verrouillee et ouvre le paywall.
     *
     * <p>🛑 <b>Et la contradiction #1 n'est pas rouverte</b> : les etapes restent
     * <b>toutes servies</b>, a leur place, avec leur avancement. On ferme
     * l'execution, jamais l'affichage.
     */
    @Test
    @DisplayName("D-18 — compte gratuit : rien d'executable, tout reste servi")
    void unCompteGratuitEstLockedEtGardeTousSesRepsereD18() {
        Skill premiere = skill("EE1-C1", SkillTaskCode.EE1);
        Skill seconde = skill("EE2-C1", SkillTaskCode.EE2);
        UUID sujet = UUID.randomUUID();
        JourneyStep une = trainStep(premiere, 1);
        JourneyStep deux = trainStep(seconde, 2);

        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                premiere.getId(), progres(List.of(sujet)),
                seconde.getId(), progres(List.of(UUID.randomUUID()))));
        // Compte GRATUIT : plus rien n'est ouvert (D-18).
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.AUCUN);

        JourneyDto vue = service.lire(journey, List.of(une, deux));

        // 🛑 Plus AUCUNE premiere place n'est soufflee au verrou.
        verify(accessService).resolve(user.getId());
        assertThat(vue.current()).isNull();
        assertThat(vue.state()).isEqualTo(JourneyState.LOCKED);
        // Les DONNEES restent servies : deux etapes, verrouillees, a leur place
        // — dans le bloc de leur epreuve, qui est la lecture du cycle (P6).
        JourneyBlocDto ee = bloc(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps()).hasSize(2);
        assertThat(ee.steps()).allSatisfy(step -> assertThat(step.locked()).isTrue());
        assertThat(ee.steps()).extracting(JourneyStepDto::skillCode)
                .containsExactly(premiere.getCode(), seconde.getCode());
        // Et le cycle aussi : son avancement n'est pas masque.
        assertThat(vue.cycle()).isNotNull();
        assertThat(vue.cycle().etapesTotal()).isEqualTo(2);
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
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, List.of(entrainement, checkpoint));

        // L'examen d'un bloc est servi A PART de ses etapes d'entrainement : la
        // mesure se lit sur `exam`, jamais dans la liste des lignes d'etape.
        JourneyStepDto examen = bloc(vue, EpreuveType.TCF_CE).exam();
        assertThat(examen).isNotNull();
        assertThat(examen.type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(examen.assessment()).isNotNull();
        assertThat(examen.assessment().kind())
                .isEqualTo(PlanDomainAssessmentKind.MODULE_MOCK_EXAM);
        assertThat(examen.assessment().epreuve()).isEqualTo(EpreuveType.TCF_CE);
        assertThat(bloc(vue, EpreuveType.TCF_EE).steps().getFirst().assessment()).isNull();
    }

    // ===================================================================== A26
    // L'exercice d'une etape de competence est SERVI
    // =====================================================================

    /**
     * 🛑 <b>Le cul-de-sac que ce champ ferme.</b> Les fronts cherchaient
     * l'exercice d'une etape {@code TRAIN_SKILL} dans les <b>priorites</b> du
     * Plan — une vue bornee a {@code display.prioritiesMaxActions} (5). Un cycle
     * de six competences ou plus avait donc des etapes dont l'action ne se
     * resolvait nulle part, et le garde-fou « une ligne ne lance jamais autre
     * chose que l'etape qu'elle annonce » les rendait <b>sans bouton</b>.
     *
     * <p>Ce test verifie les trois faits du contrat d'un coup : l'exercice est
     * servi sur une etape d'entrainement, il est {@code null} quand la competence
     * n'a aucun sujet publie (le selecteur l'omet de sa map), et il est
     * {@code null} sur une etape d'examen — qui porte {@code assessment}.
     */
    @Test
    @DisplayName("A26 — l'exercice d'une etape de competence est SERVI, et lui seul")
    void lExerciceDUneEtapeDeCompetenceEstServi() {
        Skill avecSujet = skill("EE1-C1", SkillTaskCode.EE1);
        Skill sansSujet = skill("EE2-C1", SkillTaskCode.EE2);
        JourneyStep une = trainStep(avecSujet, 1);
        JourneyStep deux = trainStep(sansSujet, 2);
        JourneyStep examen = examStep(EpreuveType.TCF_EE, 3);

        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                avecSujet.getId(), progres(List.of(UUID.randomUUID())),
                sansSujet.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        // Le selecteur OMET une competence sans sujet actif : c'est sa regle,
        // documentee sur `selectAll`, et c'est ce que le garde-fou attend.
        PlanRecommendedExerciseDto exercice = PlanRecommendedExerciseDto.microTraining(
                UUID.randomUUID(), avecSujet.getId(), avecSujet.getCode(),
                "Raconter une experience", SkillSection.EE, 12, false);
        when(exerciseSelector.selectAll(eq(user.getId()), anyCollection(), any()))
                .thenReturn(Map.of(avecSujet.getId(), exercice));

        JourneyDto vue = service.lire(journey, List.of(une, deux, examen));

        JourneyBlocDto ee = bloc(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps().getFirst().exercise()).isSameAs(exercice);
        assertThat(ee.steps().get(1).exercise())
                .as("competence sans sujet publie : rien a lancer, et on ne l'invente pas")
                .isNull();
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.exam().exercise())
                .as("un examen porte `assessment`, jamais un micro-exercice")
                .isNull();
        // 🛑 L'etape courante porte le meme exercice que sa ligne de bloc : la
        // carte « À faire maintenant » et le cycle ne divergent jamais.
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().exercise()).isSameAs(exercice);
    }

    /**
     * 🛑 <b>UN SEUL LOT, quel que soit le nombre d'etapes.</b> Le selecteur
     * expose une signature en lot precisement pour ca ; un appel par etape
     * aurait rendu le prix du Plan proportionnel a la taille du cycle. Le
     * <b>compte</b> de requetes est verrouille par {@code JourneyStepExerciseIT},
     * contre la vraie base ; ici on verrouille la <b>forme</b> de l'appel.
     */
    @Test
    @DisplayName("A26 — toutes les competences du cycle en UN seul lot, jamais un appel par etape")
    void lesExercicesSeLisentEnUnSeulLot() {
        Skill premiere = skill("EE1-C1", SkillTaskCode.EE1);
        Skill seconde = skill("EE2-C1", SkillTaskCode.EE2);
        Skill troisieme = skill("EE3-C1", SkillTaskCode.EE3);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                premiere.getId(), progres(List.of(UUID.randomUUID())),
                seconde.getId(), progres(List.of(UUID.randomUUID())),
                troisieme.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        service.lire(journey, List.of(
                trainStep(premiere, 1), trainStep(seconde, 2), trainStep(troisieme, 3),
                examStep(EpreuveType.TCF_EE, 4)));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<java.util.Collection<Skill>> lot =
                ArgumentCaptor.forClass(java.util.Collection.class);
        verify(exerciseSelector).selectAll(eq(user.getId()), lot.capture(), any());
        assertThat(lot.getValue())
                .containsExactlyInAnyOrder(premiere, seconde, troisieme);
    }

    // ================================================================= D-12 / D-15
    // Le cycle borne, lu par bloc
    // =====================================================================

    @Test
    @DisplayName("D-12 — les etapes se groupent par epreuve, dans l'ordre CO, CE, EO, EE")
    void lesEtapesSeGroupentParBlocDansLOrdreDuTcf() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 2);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 3);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(
                journey, List.of(entrainement, examenEe, examenCo));

        // 🛑 Quatre blocs, TOUJOURS, et dans l'ordre de TcfDomainProfileDto.ORDRE
        // (D-9, D-20). L'ordre des maquettes est illustratif.
        assertThat(vue.blocs()).extracting(JourneyBlocDto::examType).containsExactly(
                EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        // L'examen d'un bloc est servi A PART : l'ecran l'imbrique en fin de
        // bloc, il n'est pas une ligne d'etape de plus.
        JourneyBlocDto ee = bloc(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps()).extracting(JourneyStepDto::skillCode)
                .containsExactly(competence.getCode());
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.competencesRestantes()).isEqualTo(1);
        // Un bloc sans etape est servi quand meme : le cycle couvre les quatre
        // epreuves, pas seulement celles que la file a peuplees.
        assertThat(bloc(vue, EpreuveType.TCF_CE).steps()).isEmpty();
        assertThat(bloc(vue, EpreuveType.TCF_CE).exam()).isNull();
        // L'avancement porte sur TOUTES les etapes du cycle, diagnostic compris.
        assertThat(vue.cycle().numero()).isEqualTo(1);
        assertThat(vue.cycle().etapesTotal()).isEqualTo(3);
        assertThat(vue.cycle().etapesTerminees()).isZero();
        assertThat(vue.cycle().complete()).isFalse();
        // Une etape d'entrainement existe : ce n'est pas un cycle de mesure.
        assertThat(vue.cycle().cycleDeMesure()).isFalse();
        assertThat(vue.nextStep()).isNull();
    }

    @Test
    @DisplayName("D-15 — un bloc SANS competence est A_EVALUER, et son examen est OUVERT")
    void unBlocSansCompetenceAEvaluerASonExamenOuvert() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 2);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(journey, List.of(entrainement, examenCo));

        JourneyBlocDto co = bloc(vue, EpreuveType.TCF_CO);
        // Aucune competence dans ce bloc et epreuve jamais mesuree : il n'y a
        // rien a travailler tant que la mesure n'a pas dit quoi.
        assertThat(co.status()).isEqualTo(JourneyBlocStatus.A_EVALUER);
        assertThat(co.competencesRestantes()).isZero();
        // 🛑 Son examen est ouvert IMMEDIATEMENT (D-15) : le verrou du bloc ne
        // se pose que sur une competence restante, et il n'y en a aucune.
        assertThat(co.exam()).isNotNull();
        assertThat(co.exam().locked()).isFalse();
        // La main est sur l'entrainement, donc le bloc EE est EN_COURS.
        assertThat(bloc(vue, EpreuveType.TCF_EE).status())
                .isEqualTo(JourneyBlocStatus.EN_COURS);
    }

    @Test
    @DisplayName("D-15 — l'examen d'un bloc est VERROUILLE tant qu'une competence y reste ouverte")
    void lExamenDUnBlocEstVerrouilleParSesCompetences() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 2);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 3);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(
                journey, List.of(entrainement, examenEe, examenCo));

        // 🛑 Le verrou est PEDAGOGIQUE et il est PAR BLOC : « finis ce que tu as
        // prevu avant de te remesurer ». Le compte est abonne — aucun verrou
        // commercial n'intervient ici.
        assertThat(bloc(vue, EpreuveType.TCF_EE).exam().locked()).isTrue();
        // Le bloc voisin, lui, n'a aucune competence due : son examen reste
        // ouvert. Un verrou global aurait ferme les quatre.
        assertThat(bloc(vue, EpreuveType.TCF_CO).exam().locked()).isFalse();
        // Et un examen verrouille ne prend jamais la main (D-1).
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().skillCode()).isEqualTo(competence.getCode());
    }

    @Test
    @DisplayName("Cycle termine : CYCLE_COMPLETED, et nextStep offre les deux issues")
    void unCycleTermineOuvreLEcranProchaineEtape() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        entrainement.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 2);
        examenEe.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                Instant.now());
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(journey, List.of(entrainement, examenEe));

        assertThat(vue.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(vue.current()).isNull();
        assertThat(vue.cycle().complete()).isTrue();
        assertThat(vue.cycle().etapesTerminees()).isEqualTo(2);
        assertThat(bloc(vue, EpreuveType.TCF_EE).status()).isEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(vue.nextStep()).isNotNull();
        assertThat(vue.nextStep().actualisationPossible()).isTrue();
        assertThat(vue.nextStep().examenCompletPossible()).isTrue();
    }

    @Test
    @DisplayName("Cycle de mesure termine : la SEULE issue offerte est l'actualisation")
    void unCycleDeMesureTermineNOffreQueLActualisation() {
        List<JourneyStep> examens = new java.util.ArrayList<>();
        long position = 1;
        for (EpreuveType epreuve : com.sejourfr.app.dto.TcfDomainProfileDto.ORDRE) {
            JourneyStep examen = examStep(epreuve, position++);
            examen.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                    Instant.now());
            examens.add(examen);
        }
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of());
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, examens);

        // Aucune etape d'entrainement : c'est un cycle de mesure, DERIVE et non
        // persiste.
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        // 🛑 Enchainer un second examen complet ne mesurerait rien de nouveau.
        assertThat(vue.nextStep().examenCompletPossible()).isFalse();
        assertThat(vue.nextStep().actualisationPossible()).isTrue();
    }

    // ================================================================== D-16
    // Le quota d'une etape de comprehension : 2 series REUSSIES, ou 4 TERMINEES
    // =====================================================================

    /**
     * 🛑 <b>D-16 revoque la doctrine de D-5</b> (« le quota mesure le travail
     * fourni, pas la reussite ») : deux series <b>reussies</b> closent l'etape.
     *
     * <p>« Reussie » est <b>lu</b> chez l'autorite qui rend deja ce verdict —
     * {@code learning_plan_observations.status = SOLID}, pose par
     * {@code ComprehensionObservationService} depuis
     * {@code learning-plan.comprehension.solid-ratio} (0.80). 🛑 Aucune
     * 8<sup>e</sup> declaration de ce seuil ici.
     */
    @Test
    @DisplayName("D-16 — 2 series REUSSIES closent l'etape de comprehension")
    void deuxSeriesReussiesClosentLEtape() {
        Skill palier = comprehension("CO-B1");
        JourneyStep etape = comprehensionStep(palier, 1);
        observations(palier,
                serie(palier, LearningPlanSkillStatus.SOLID),
                serie(palier, LearningPlanSkillStatus.SOLID));
        abonne();

        assertThat(service.etapesAuQuota(user.getId(), List.of(etape)))
                .containsExactly(etape.getId());
    }

    /**
     * Une reussie et une ratee : le quota de <b>reussite</b> n'est pas atteint,
     * et l'echappatoire (4 terminees) non plus. L'etape reste ouverte — c'est
     * exactement ce que l'ancienne regle (2 terminees) closait a tort.
     */
    @Test
    @DisplayName("D-16 — 1 reussie + 1 ratee ne closent RIEN")
    void uneReussieEtUneRateeNeClosentRien() {
        Skill palier = comprehension("CO-B1");
        JourneyStep etape = comprehensionStep(palier, 1);
        observations(palier,
                serie(palier, LearningPlanSkillStatus.SOLID),
                serie(palier, LearningPlanSkillStatus.PRIORITY));
        abonne();

        assertThat(service.etapesAuQuota(user.getId(), List.of(etape))).isEmpty();
    }

    /**
     * 🛑 <b>L'echappatoire existe pour une raison nommee : un candidat faible ne
     * doit JAMAIS rester bloque sur une etape.</b> Quatre series terminees, pas
     * une reussie, et l'etape se clot quand meme.
     *
     * <p>Un {@code NOT_OBSERVED} y compte comme <b>terminee</b> — la serie a bien
     * ete jouee — mais jamais comme <b>reussie</b> : « non observe » reste
     * inconnu, jamais mauvais.
     */
    @Test
    @DisplayName("D-16 — 4 series TERMINEES toutes ratees closent quand meme l'etape")
    void quatreSeriesTermineesClosentLEtapeMemeSansAucuneReussite() {
        Skill palier = comprehension("CE-A2");
        JourneyStep etape = comprehensionStep(palier, 1);
        observations(palier,
                serie(palier, LearningPlanSkillStatus.PRIORITY),
                serie(palier, LearningPlanSkillStatus.TO_REINFORCE),
                serie(palier, LearningPlanSkillStatus.NOT_OBSERVED),
                serie(palier, LearningPlanSkillStatus.PRIORITY));
        abonne();

        assertThat(service.etapesAuQuota(user.getId(), List.of(etape)))
                .containsExactly(etape.getId());
    }

    @Test
    @DisplayName("D-16 — 3 series terminees sans reussite ne closent PAS encore")
    void troisSeriesTermineesNeClosentPasEncore() {
        Skill palier = comprehension("CE-A2");
        JourneyStep etape = comprehensionStep(palier, 1);
        observations(palier,
                serie(palier, LearningPlanSkillStatus.PRIORITY),
                serie(palier, LearningPlanSkillStatus.PRIORITY),
                serie(palier, LearningPlanSkillStatus.TO_REINFORCE));
        abonne();

        assertThat(service.etapesAuQuota(user.getId(), List.of(etape))).isEmpty();
    }

    /**
     * Le {@code progress} servi compte les series <b>REUSSIES</b>, sur le quota
     * des reussies — <b>l'echappatoire ne s'affiche pas</b>.
     *
     * <p>Motif : afficher « 2 series ratees sur 4 » inviterait a <b>echouer
     * vite</b> pour se debarrasser d'une etape, exactement le contraire de son
     * but ; et un filet annonce n'en est plus un. Un seul champ
     * {@code done}/{@code quota} ne peut porter qu'une echelle, et servir la plus
     * exigeante ne <b>survend jamais</b> l'avancement.
     */
    @Test
    @DisplayName("D-16 — le progress servi compte les REUSSIES, l'echappatoire reste invisible")
    void leProgressServiCompteLesReussies() {
        Skill palier = comprehension("CO-A2");
        JourneyStep etape = comprehensionStep(palier, 1);
        observations(palier,
                serie(palier, LearningPlanSkillStatus.SOLID),
                serie(palier, LearningPlanSkillStatus.PRIORITY),
                serie(palier, LearningPlanSkillStatus.PRIORITY));
        abonne();

        JourneyStepDto servie = bloc(service.lire(journey, List.of(etape)),
                EpreuveType.TCF_CO).steps().getFirst();

        assertThat(servie.progress().unit()).isEqualTo(JourneyProgressUnit.SERIES);
        assertThat(servie.progress().done())
                .as("une seule serie reussie sur les trois jouees")
                .isEqualTo(1);
        assertThat(servie.progress().quota()).isEqualTo(2);
    }

    /**
     * Une serie jouee <b>avant</b> la creation de l'etape ne compte pas : le
     * quota part de la creation de l'etape (R8).
     */
    @Test
    @DisplayName("D-16 — une serie anterieure a l'etape ne compte dans aucun des deux compteurs")
    void uneSerieAnterieureALEtapeNeCompteJamais() {
        Skill palier = comprehension("CO-B2");
        JourneyStep etape = comprehensionStep(palier, 1);
        LearningPlanObservation avant = serie(palier, LearningPlanSkillStatus.SOLID);
        avant.setObservedAt(etape.getCreatedAt().minusSeconds(60));
        observations(palier, avant, serie(palier, LearningPlanSkillStatus.SOLID));
        abonne();

        assertThat(service.etapesAuQuota(user.getId(), List.of(etape))).isEmpty();
        JourneyStepDto servie = bloc(service.lire(journey, List.of(etape)),
                EpreuveType.TCF_CO).steps().getFirst();
        assertThat(servie.progress().done()).isEqualTo(1);
    }

    /** Un abonne, sans aucun sujet d'expression a compter. */
    private void abonne() {
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of());
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
    }

    private void observations(Skill palier, LearningPlanObservation... series) {
        when(observationManager.findByUserAndSkillsSince(eq(user.getId()), any(), any()))
                .thenReturn(List.of(series));
    }

    /**
     * Une serie ciblee terminee, telle que {@code ComprehensionObservationService}
     * l'ecrit : une observation par (competence, session), {@code sourceId} =
     * l'attempt, et le <b>verdict deja pose</b> dans {@code status}.
     */
    private LearningPlanObservation serie(Skill palier, LearningPlanSkillStatus statut) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setId(UUID.randomUUID());
        observation.setUser(user);
        observation.setSkill(palier);
        observation.setSourceType(palier.getSection() == SkillSection.CO
                ? LearningPlanSourceType.TCF_CO : LearningPlanSourceType.TCF_CE);
        UUID session = UUID.randomUUID();
        observation.setSourceId(session);
        observation.setSubjectId(session);
        observation.setStatus(statut);
        observation.setObserved(statut != LearningPlanSkillStatus.NOT_OBSERVED);
        observation.setObservedAt(Instant.now());
        return observation;
    }

    private JourneyStep comprehensionStep(Skill palier, long position) {
        JourneyStep step = trainStep(palier, position);
        step.setExamType(palier.getSection() == SkillSection.CO
                ? EpreuveType.TCF_CO : EpreuveType.TCF_CE);
        return step;
    }

    /** Une competence de comprehension : ni tache, ni petit sujet (V039/V318). */
    private static Skill comprehension(String code) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(code.startsWith("CO") ? SkillSection.CO : SkillSection.CE);
        skill.setTaskCode(null);
        skill.setTargetLevel(code.substring(3));
        skill.setDisplayOrder((short) 1);
        skill.setActive(true);
        return skill;
    }

    /** Un abonne dont la competence a un sujet publie : etape finissable. */
    private void abonneAvecSujets(Skill competence) {
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                competence.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
    }

    private static JourneyBlocDto bloc(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> bloc.examType() == epreuve)
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
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
