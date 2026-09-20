package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyBlocKind;
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
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.service.LearningPlanStep;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.RecommendedExerciseSelector;
import com.sejourfr.app.service.SkillAccessService;
import com.sejourfr.app.service.SubscriptionService;
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
    @Mock private ThemeManager themeManager;
    @Mock private SubscriptionService subscriptionService;

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
                new JourneyBlocResolver(), journeyManager, exerciseSelector, themeManager,
                subscriptionService);
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
    @DisplayName("D-12 — les etapes se groupent par epreuve, et le bloc qui porte du travail "
            + "ouvre la liste")
    void lesEtapesSeGroupentParBlocDansLOrdreDuTcf() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 2);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 3);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(
                journey, List.of(entrainement, examenEe, examenCo));

        // 🛑 Quatre blocs, TOUJOURS. ⚠️ Ce test attendait CO, CE, EO, EE :
        // MIS A JOUR par un changement VOULU (2026-09-20). L'ordre d'AFFICHAGE
        // se derive desormais du travail porte — « il a des choses a faire,
        // comme les autres n'ont que examen a faire ». TCF_EE est le seul bloc
        // a porter une etape TRAIN_SKILL ici, il passe donc devant, et les
        // trois autres se suivent dans l'ordre de TcfDomainProfileDto.ORDRE,
        // qui reste l'unique autorite de l'ordre des epreuves (D-9, D-20).
        // 🛑 Le bloc est SERVI depuis 2026-09-19 : on lit son `code`, pas un
        // `EpreuveType` (D-47). Le code d'une epreuve EST son nom d'enum.
        assertThat(vue.blocs()).extracting(bloc -> bloc.bloc().code()).containsExactly(
                EpreuveType.TCF_EE.name(), EpreuveType.TCF_CO.name(),
                EpreuveType.TCF_CE.name(), EpreuveType.TCF_EO.name());
        // L'examen d'un bloc est servi A PART : l'ecran l'imbrique en fin de
        // bloc, il n'est pas une ligne d'etape de plus.
        JourneyBlocDto ee = bloc(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps()).extracting(JourneyStepDto::skillCode)
                .containsExactly(competence.getCode());
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.etapesRestantes()).isEqualTo(1);
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

    // ================================================================= 2026-09-20
    // L'ORDRE D'AFFICHAGE DES BLOCS SE DERIVE DU TRAVAIL PORTE
    //
    // « afficher expression ecrite en premier ici, car il a des choses a faire,
    // comme les autres n'ont que examen a faire. […] si le diagnostic il est
    // fait EE est en tete au premier cycle vu que c'est lui qui contient des
    // choses a travailler » (le proprietaire, verbatim).
    //
    // 🛑 La regle testee est le CRITERE, jamais « EE en dur » : un bloc qui
    // porte au moins une etape TRAIN_SKILL passe devant ceux qui n'en portent
    // aucune, et TcfDomainProfileDto.ORDRE est conserve DANS chaque groupe.
    // =====================================================================

    /**
     * <b>Diagnostic rapide passe</b> : il n'a cree de lot que sur EE, donc EE
     * est le seul bloc a porter du travail. Il ouvre la liste, et les trois
     * autres — qui n'ont qu'un examen a passer — se suivent <b>dans leur ordre
     * d'origine</b>.
     */
    @Test
    @DisplayName("Ordre — le bloc qui porte du travail passe devant, les autres gardent ORDRE")
    void leBlocQuiPorteDuTravailOuvreLaListe() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(competence, 1),
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3),
                examStep(EpreuveType.TCF_CE, 4),
                examStep(EpreuveType.TCF_EO, 5)));

        assertThat(vue.blocs()).extracting(bloc -> bloc.bloc().code())
                .as("EE porte les priorites du diagnostic ; CO, CE, EO n'ont qu'un examen")
                .containsExactly(
                        EpreuveType.TCF_EE.name(), EpreuveType.TCF_CO.name(),
                        EpreuveType.TCF_CE.name(), EpreuveType.TCF_EO.name());
    }

    /**
     * 🛑 <b>« Si pas de diagnostic fait, alors on fait cet ordre actuel » sort
     * TOUT SEUL</b>, sans un seul {@code if (diagnosticFait)} : aucun lot, donc
     * aucune etape {@code TRAIN_SKILL}, donc tous les blocs sont dans le second
     * groupe, donc {@code TcfDomainProfileDto.ORDRE} revient intact.
     *
     * <p>C'est exactement la forme d'un <b>cycle de mesure</b> — quatre examens
     * et rien d'autre.
     */
    @Test
    @DisplayName("Ordre — aucun travail nulle part : l'ordre servi est exactement CO, CE, EO, EE")
    void sansLaMoindreEtapeDeTravailLOrdreResteCeluiDeORDRE() {
        abonne();
        List<JourneyStep> examens = new java.util.ArrayList<>();
        long position = 1;
        for (EpreuveType epreuve : com.sejourfr.app.dto.TcfDomainProfileDto.ORDRE) {
            examens.add(examStep(epreuve, position++));
        }

        JourneyDto vue = service.lire(journey, examens);

        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.blocs()).extracting(bloc -> bloc.bloc().code()).containsExactly(
                EpreuveType.TCF_CO.name(), EpreuveType.TCF_CE.name(),
                EpreuveType.TCF_EO.name(), EpreuveType.TCF_EE.name());
    }

    /**
     * 🛑 <b>LA STABILITE, et c'est le test a ne pas oublier.</b>
     *
     * <p>Le critere est « ce bloc <b>porte</b> une etape {@code TRAIN_SKILL} »,
     * <b>ouverte ou cloturee</b> — jamais « il lui reste du travail ». Une
     * cloture ne se reouvre jamais et n'efface pas l'etape (D-7), donc le bloc
     * <b>garde son rang</b> au moment ou le candidat finit ses competences.
     *
     * <p>Si le critere avait ete {@code etapesRestantes > 0}, EE serait reparti
     * en 4<sup>e</sup> position <b>sous les yeux du candidat</b>, pendant le
     * cycle — exactement ce que la position monotone de V066 interdit.
     */
    @Test
    @DisplayName("Ordre — STABILITE : competences toutes cloturees, le bloc garde son rang")
    void unBlocGardeSonRangQuandSonTravailEstTermine() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);
        abonneAvecSujets(competence);

        List<String> pendant = codes(service.lire(journey, List.of(
                entrainement,
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3))));

        // Le candidat termine sa derniere competence : l'etape se clot, elle
        // reste en base, et rien d'autre ne change.
        entrainement.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());

        List<String> apres = codes(service.lire(journey, List.of(
                entrainement,
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3))));

        assertThat(apres)
                .as("l'ecran ne bouge pas sous les yeux du candidat pendant son cycle")
                .isEqualTo(pendant);
        assertThat(apres.getFirst()).isEqualTo(EpreuveType.TCF_EE.name());
        // Et le bloc ne porte bien plus aucun travail DU : c'est le rang qui
        // est stable, pas le reste de l'etat.
        assertThat(bloc(service.lire(journey, List.of(entrainement)), EpreuveType.TCF_EE)
                .etapesRestantes()).isZero();
    }

    /**
     * Deux blocs porteurs de travail restent <b>entre eux</b> dans l'ordre de
     * {@code ORDRE} : la regle est une <b>partition stable</b>, pas un tri.
     * {@code TCF_EO} precede {@code TCF_EE} dans {@code ORDRE}, il le precede
     * donc ici aussi.
     */
    @Test
    @DisplayName("Ordre — deux blocs porteurs : ils restent entre eux dans l'ordre de ORDRE")
    void deuxBlocsPorteursGardentLOrdreDeORDREEntreEux() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(ee, 1),
                trainStepDe(eo, EpreuveType.TCF_EO, 2),
                examStep(EpreuveType.TCF_CO, 3)));

        assertThat(vue.blocs()).extracting(bloc -> bloc.bloc().code()).containsExactly(
                // EO avant EE : c'est l'ordre de TcfDomainProfileDto.ORDRE,
                // conserve tel quel a l'interieur du groupe. La file, elle, a
                // mis l'etape EE en premier — l'ordre d'affichage des blocs ne
                // derive pas de l'ordre de la file.
                EpreuveType.TCF_EO.name(), EpreuveType.TCF_EE.name(),
                EpreuveType.TCF_CO.name(), EpreuveType.TCF_CE.name());
    }

    // ================================================================= 2026-09-20
    // LE BADGE « EN COURS » SUIT LE TRAVAIL, PLUS LA MAIN
    //
    // « Ici c'est EE qui doit etre en cours, car on commence par lui, commence
    // par ce que le diagnostic a identifie et ensuite on fais l'examen sur les
    // autres epreuves » (le proprietaire, verbatim).
    //
    // 🛑 REVOCATION PARTIELLE D'A37 : l'ordre de derivation ne commence plus par
    // « le bloc porte CURRENT » mais par « ce bloc est le PREMIER, dans l'ordre
    // servi, a porter une etape TRAIN_SKILL ouverte ». Le motif d'A37 — « le
    // bloc qui porte l'action gagne l'affichage, sinon deux blocs se
    // disputeraient EN COURS » — reste tenu : un seul bloc peut etre le
    // premier.
    //
    // 🛑 D-1 N'EST PAS TOUCHE : c'est le badge du bloc qui cesse de dependre de
    // CURRENT, pas l'inverse. D-18 non plus : rien ne s'ouvre.
    // =====================================================================

    /**
     * <b>Le defaut constate a l'ecran par le proprietaire</b>, reproduit tel
     * quel : un compte <b>gratuit</b> qui sort du diagnostic rapide.
     *
     * <p>D-18 rend toute etape {@code TRAIN_SKILL} inexecutable, donc
     * {@code CURRENT} — « la premiere etape non cloturee <b>et executable</b> »
     * (D-1) — tombe sur le premier examen ouvert : celui de la CO, dont le bloc
     * n'a aucune competence a finir avant lui (D-15). L'ecran disait donc
     * « commence par l'expression ecrite » <b>et</b> « la comprehension orale
     * est en cours » — deux phrases qui se contredisent.
     *
     * <p>⚠️ <b>Le 2026-09-20, la seconde moitie de D-57 a ferme l'autre cote</b> :
     * la main ne part plus vers la CO, elle n'existe simplement plus
     * ({@code current == null}, {@code state == LOCKED}). Ce test garde son
     * montage et son role — <b>le badge ne bouge pas</b> — et le detail de
     * l'election vit dans
     * {@link #surUnCompteGratuitLeBlocMeneurNOffreRienEtCurrentEstNull()}.
     */
    @Test
    @DisplayName("Compte GRATUIT — EN_COURS va au bloc qui porte le travail, et le travail "
            + "reste ferme")
    void surUnCompteGratuitLeBadgeSuitLeTravailPasLaMain() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                competence.getId(), progres(List.of(UUID.randomUUID()))));
        // 🛑 Compte GRATUIT : plus rien n'est executable depuis D-18.
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.AUCUN);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(competence, 1),
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3),
                examStep(EpreuveType.TCF_CE, 4),
                examStep(EpreuveType.TCF_EO, 5)));

        // 🛑 MIS A JOUR LE 2026-09-20 PAR LA SECONDE MOITIE DE D-57. Ce test
        // figeait « la main reste sur l'examen de CO » : c'etait le fait mesure
        // de la PREMIERE moitie, et c'est precisement ce que la seconde ferme.
        // `elire` ne cherche plus que dans le bloc meneur (l'EE), qui n'offre
        // rien d'executable a un compte gratuit — donc `current` est nul, et
        // D-1 le dit mot pour mot : « si aucune etape n'est executable :
        // current = null, state = LOCKED ». Le cas d'usage retire est remonte
        // dans le rapport : un compte gratuit ne lance plus l'examen de CO
        // depuis « À faire maintenant » — il le lance depuis le bloc CO, dont
        // l'examen reste ouvert (assertion plus bas).
        assertThat(vue.current()).isNull();
        assertThat(vue.state()).isEqualTo(JourneyState.LOCKED);
        assertThat(bloc(vue, EpreuveType.TCF_CO).exam()).isNotNull();
        assertThat(bloc(vue, EpreuveType.TCF_CO).exam().locked()).isFalse();
        // ✅ Et le badge est sur l'expression ecrite : c'est elle qui
        // porte les priorites du diagnostic, et l'ecran dit desormais une seule
        // chose.
        assertThat(bloc(vue, EpreuveType.TCF_EE).status())
                .isEqualTo(JourneyBlocStatus.EN_COURS);
        assertThat(bloc(vue, EpreuveType.TCF_CO).status())
                .as("la CO n'a aucune competence a travailler : elle n'est pas « en cours »")
                .isNotEqualTo(JourneyBlocStatus.EN_COURS);
        // 🛑 D-18 EST INTACT : le travail reste ferme, seul le mot change.
        assertThat(bloc(vue, EpreuveType.TCF_EE).steps()).allSatisfy(step ->
                assertThat(step.locked()).isTrue());
    }

    /**
     * <b>Un seul bloc {@code EN_COURS}</b>, c'est le motif d'A37 et il reste
     * tenu : deux blocs portent du travail ouvert, un seul est le
     * <b>premier</b> dans l'ordre servi.
     *
     * <p>⚠️ Conséquence assumee : le bloc du badge et le bloc de {@code CURRENT}
     * peuvent differer, ici pour un <b>abonne</b>. L'ordre servi range EO avant
     * EE ({@code TcfDomainProfileDto.ORDRE}, conserve dans le groupe des
     * porteurs de travail), pendant que la <b>file</b> — dont {@code CURRENT}
     * sort — a mis l'etape EE en premier. Le badge suit l'<b>ecran</b>, la carte
     * « À faire maintenant » suit la <b>file</b>.
     */
    @Test
    @DisplayName("Un SEUL bloc EN_COURS : le premier de l'ordre servi a porter du travail ouvert")
    void unSeulBlocEstEnCoursQuandDeuxEnPortent() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(ee, 1),
                trainStepDe(eo, EpreuveType.TCF_EO, 2),
                examStep(EpreuveType.TCF_CO, 3)));

        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_EO.name());
        // 🛑 MIS A JOUR LE 2026-09-20 PAR LA SECONDE MOITIE DE D-57. Ce test
        // figeait l'ecart d'A113 — « le badge suit l'ecran, la carte suit la
        // file » —, que le proprietaire a tranche en sens inverse : « une
        // epreuve en cours, c'est forcement une de ses etapes a faire
        // maintenant ». L'ecart est desormais ferme PAR CONSTRUCTION, les deux
        // designant le bloc meneur.
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().bloc().code()).isEqualTo(EpreuveType.TCF_EO.name());
        invariantDuBadge(vue);
    }

    /**
     * <b>Un abonne : rien ne change pour lui.</b> Sa premiere etape non
     * cloturee est executable, donc {@code CURRENT} est deja dans le bloc qui
     * porte le travail — l'ancienne regle et la nouvelle designent le meme.
     */
    @Test
    @DisplayName("Abonne — EE porte le travail ET la main : le badge ne bouge pas")
    void pourUnAbonneLeBadgeNeBougePas() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        abonneAvecSujets(competence);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(competence, 1),
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3)));

        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().skillCode()).isEqualTo(competence.getCode());
        assertThat(bloc(vue, EpreuveType.TCF_EE).status())
                .isEqualTo(JourneyBlocStatus.EN_COURS);
        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .hasSize(1);
    }

    /**
     * 🛑 <b>Le cycle de mesure garde son comportement</b> (A80, A33) : aucune
     * etape {@code TRAIN_SKILL} nulle part, donc aucun bloc ne porte de travail
     * ouvert — et « le bloc qui porte la main » redevient la bonne reponse, la
     * seule disponible. Ce repli n'est pas une precaution de style : sans lui,
     * un cycle de mesure entier n'aurait plus aucun bloc {@code EN_COURS}.
     */
    @Test
    @DisplayName("Cycle de mesure — aucun travail nulle part : EN_COURS retombe sur le bloc "
            + "qui porte CURRENT")
    void sansAucunTravailLeBadgeRetombeSurLeBlocDeCurrent() {
        abonne();
        List<JourneyStep> examens = new java.util.ArrayList<>();
        long position = 1;
        for (EpreuveType epreuve : com.sejourfr.app.dto.TcfDomainProfileDto.ORDRE) {
            examens.add(examStep(epreuve, position++));
        }

        JourneyDto vue = service.lire(journey, examens);

        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().bloc().code()).isEqualTo(EpreuveType.TCF_CO.name());
        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_CO.name());
    }

    /**
     * <b>La stabilite du badge — a ne pas confondre avec celle du RANG</b>
     * (A102).
     *
     * <p>Le rang d'un bloc se lit sur l'<b>existence</b> d'une etape
     * {@code TRAIN_SKILL}, ouverte ou cloturee : il ne bouge pas de tout le
     * cycle. Le <b>statut</b>, lui, se lit sur le travail <b>ouvert</b> : il
     * avance de bloc en bloc a mesure que le candidat finit, et c'est
     * exactement ce qu'on attend d'un badge « EN COURS ».
     *
     * <p>Ici EO a deja fini son travail, EE non : EO reste <b>premier</b>
     * (A102) et <b>TERMINE</b>, EE est <b>second</b> et <b>EN_COURS</b>. Puis
     * EE finit a son tour : plus aucun travail ouvert, le repli s'applique.
     */
    @Test
    @DisplayName("Stabilite — le RANG ne bouge pas, le STATUT avance au bloc suivant qui porte "
            + "du travail")
    void leBadgeAvanceAuBlocSuivantQuandLePremierAFini() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        JourneyStep travailEo = trainStepDe(eo, EpreuveType.TCF_EO, 1);
        travailEo.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        JourneyStep travailEe = trainStep(ee, 2);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 3);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 4);
        List<JourneyStep> file = List.of(travailEo, travailEe, examenCo, examenEe);

        JourneyDto avant = service.lire(journey, file);

        // Le rang : EO d'abord, parce qu'il a PORTE du travail (A102).
        assertThat(codes(avant).getFirst()).isEqualTo(EpreuveType.TCF_EO.name());
        assertThat(bloc(avant, EpreuveType.TCF_EO).status())
                .isEqualTo(JourneyBlocStatus.TERMINE);
        // Le statut : EE, premier bloc a porter du travail ENCORE OUVERT.
        assertThat(bloc(avant, EpreuveType.TCF_EE).status())
                .isEqualTo(JourneyBlocStatus.EN_COURS);

        travailEe.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        JourneyDto apres = service.lire(journey, file);

        // 🛑 Le rang n'a pas bouge — c'est A102, et elle n'est pas touchee.
        assertThat(codes(apres)).isEqualTo(codes(avant));
        // Plus aucun travail ouvert : le repli rend la main au porteur de
        // CURRENT, ici l'examen de CO (position 3, le premier ouvert).
        assertThat(apres.current()).isNotNull();
        assertThat(apres.current().bloc().code()).isEqualTo(EpreuveType.TCF_CO.name());
        assertThat(apres.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_CO.name());
    }


    // ================================================================= 2026-09-20
    // D-57, SECONDE MOITIE — LA CARTE SUIT LE BADGE
    //
    // « Pour moi, l'epreuve en cours doit toujours avoir sa tache suivante a
    // faire dans "a faire maintenant" [...] Une fois cette epreuve finie,
    // validee, on passe a la suivante qui devient en cours avec sa tache 1 non
    // faite deja a faire maintenant » (le proprietaire, verbatim).
    //
    // 🛑 LE SENS DE LA DEPENDANCE EST NORMATIF : ce n'est pas le badge qui suit
    // la carte, c'est la carte qui suit le badge. `elire` cherche donc CURRENT
    // parmi les etapes du BLOC MENEUR, et d'elles seules.
    //
    // 🛑 ET SANS AUCUN REPLI SUR LA FILE quand le meneur n'offre rien
    // d'executable : ce repli rouvrirait exactement le defaut qu'on ferme (voir
    // `surUnCompteGratuitLeBlocMeneurNOffreRienEtCurrentEstNull`).
    // =====================================================================

    /**
     * <b>L'invariant central</b> : le bloc meneur porte du travail, donc
     * {@code CURRENT} est <b>une de ses etapes</b>, et le bloc de
     * {@code CURRENT} <b>est</b> le bloc {@code EN_COURS}.
     *
     * <p>Le montage est celui d'A113, le seul ou les deux ordres divergeaient :
     * l'ordre <b>servi</b> range les porteurs selon {@code ORDRE} (EO avant EE),
     * la <b>file</b> a mis l'etape EE en premier (R10 bis, ecart au niveau cible
     * decroissant). Avant D-57, le badge disait EO et la carte disait EE.
     */
    @Test
    @DisplayName("D-57 — abonne : CURRENT est une etape DU bloc meneur, et c'est le bloc EN_COURS")
    void currentSEliteDansLeBlocMeneur() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(ee, 1),
                trainStepDe(eo, EpreuveType.TCF_EO, 2),
                examStep(EpreuveType.TCF_CO, 3)));

        // Le meneur : EO, premier porteur de travail dans l'ordre servi (D-56).
        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_EO.name());
        // 🛑 Et la carte nomme desormais SA tache, plus celle de la file.
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().bloc().code()).isEqualTo(EpreuveType.TCF_EO.name());
        assertThat(vue.current().skillCode()).isEqualTo(eo.getCode());
        // L'etape promue est bien servie DANS le bloc, a sa place.
        assertThat(bloc(vue, EpreuveType.TCF_EO).steps())
                .anySatisfy(step -> assertThat(step.status())
                        .isEqualTo(JourneyStepStatus.CURRENT));
        invariantDuBadge(vue);
    }

    /**
     * 🛑 <b>LE POINT LE PLUS IMPORTANT DE D-57, et il est contre-intuitif.</b>
     *
     * <p>Sur un compte <b>gratuit</b>, le bloc meneur est celui des competences,
     * et D-18 les rend <b>toutes</b> inexecutables : le meneur n'offre donc
     * <b>rien</b>. Retomber alors sur la file entiere ferait repartir
     * {@code CURRENT} vers l'examen d'un <b>autre</b> bloc — ici la CO, ouverte
     * d'emblee parce que son bloc n'a aucune competence a finir avant elle
     * (D-15) — et le badge dirait de nouveau autre chose que la carte. C'est
     * exactement le defaut que D-57 ferme.
     *
     * <p>{@code CURRENT} vaut donc {@code null}, et c'est <b>mot pour mot</b> ce
     * que D-1 prevoit : « si aucune etape n'est executable : {@code current =
     * null}, {@code state = LOCKED}, et la carte montre la premiere etape
     * verrouillee + paywall ».
     *
     * <p>🛑 <b>D-18 est intact, et rien ne se ferme</b> : l'examen de CO reste
     * <b>ouvert</b> et servi dans son bloc. Ce qui change est ce que la carte
     * <b>nomme</b>, jamais ce que l'ecran <b>ouvre</b>.
     */
    @Test
    @DisplayName("D-57 — compte GRATUIT : le bloc meneur n'offre rien ⇒ current null, LOCKED, "
            + "et AUCUN repli sur la file")
    void surUnCompteGratuitLeBlocMeneurNOffreRienEtCurrentEstNull() {
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                competence.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.AUCUN);

        JourneyDto vue = service.lire(journey, List.of(
                trainStep(competence, 1),
                examStep(EpreuveType.TCF_EE, 2),
                examStep(EpreuveType.TCF_CO, 3),
                examStep(EpreuveType.TCF_CE, 4),
                examStep(EpreuveType.TCF_EO, 5)));

        assertThat(vue.current())
                .as("aucune etape du bloc meneur n'est executable : pas de repli (D-57)")
                .isNull();
        assertThat(vue.state()).isEqualTo(JourneyState.LOCKED);
        // ✅ Le badge, lui, NE BOUGE PAS : il reste sur le bloc meneur.
        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_EE.name());
        // 🛑 Rien ne s'est ferme : l'examen de CO reste ouvert dans son bloc, il
        // ne prend simplement plus la main.
        assertThat(bloc(vue, EpreuveType.TCF_CO).exam()).isNotNull();
        assertThat(bloc(vue, EpreuveType.TCF_CO).exam().locked()).isFalse();
        invariantDuBadge(vue);
    }

    /**
     * <b>Le cycle de mesure garde son comportement d'avant</b> : aucun bloc ne
     * porte de travail, il n'y a donc pas de meneur par le travail, et
     * {@code elire} parcourt <b>toute la file</b> — le badge suit alors le
     * porteur de {@code CURRENT}.
     *
     * <p>Le montage le rend <b>verifiable</b> : l'examen de CO est deja clos,
     * donc la main va a la CE, qui n'est <b>pas</b> le premier bloc servi. Un
     * badge pose sur le premier bloc passerait ce test par accident.
     */
    @Test
    @DisplayName("D-57 — cycle de mesure : CURRENT s'elit sur TOUTE la file, le badge le suit")
    void sansTravailNullePartCurrentSEliteSurToutLaFile() {
        abonne();
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 1);
        examenCo.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                UUID.randomUUID(), Instant.now());

        JourneyDto vue = service.lire(journey, List.of(
                examenCo,
                examStep(EpreuveType.TCF_CE, 2),
                examStep(EpreuveType.TCF_EO, 3),
                examStep(EpreuveType.TCF_EE, 4)));

        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().bloc().code()).isEqualTo(EpreuveType.TCF_CE.name());
        assertThat(vue.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_CE.name());
        invariantDuBadge(vue);
    }

    /**
     * <b>La phrase du proprietaire, jouee</b> : « une fois cette epreuve finie,
     * validee, on passe au suivant qui devient en cours avec sa tache 1 non
     * faite deja a faire maintenant ».
     *
     * <p>Le meneur <b>et</b> {@code CURRENT} passent <b>ensemble</b> au bloc
     * suivant qui porte du travail — c'est la meme designation qui les gouverne
     * tous les deux, donc ils ne peuvent pas se separer.
     */
    @Test
    @DisplayName("D-57 — epreuve finie : le badge ET la carte passent ENSEMBLE au bloc suivant")
    void leMeneurEtCurrentPassentEnsembleAuBlocSuivant() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        JourneyStep travailEo = trainStepDe(eo, EpreuveType.TCF_EO, 1);
        JourneyStep travailEe = trainStep(ee, 2);
        JourneyStep examenEo = examStep(EpreuveType.TCF_EO, 3);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 4);
        List<JourneyStep> file = List.of(travailEo, travailEe, examenEo, examenEe);

        JourneyDto avant = service.lire(journey, file);

        assertThat(avant.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_EO.name());
        assertThat(avant.current()).isNotNull();
        assertThat(avant.current().skillCode()).isEqualTo(eo.getCode());
        invariantDuBadge(avant);

        // L'epreuve EO est finie ET validee : sa competence, puis son examen.
        travailEo.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        examenEo.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                UUID.randomUUID(), Instant.now());

        JourneyDto apres = service.lire(journey, file);

        assertThat(bloc(apres, EpreuveType.TCF_EO).status())
                .isEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(apres.blocs()).filteredOn(b -> b.status() == JourneyBlocStatus.EN_COURS)
                .extracting(b -> b.bloc().code())
                .containsExactly(EpreuveType.TCF_EE.name());
        // ✅ « ... avec sa tache 1 non faite deja a faire maintenant ».
        assertThat(apres.current()).isNotNull();
        assertThat(apres.current().skillCode()).isEqualTo(ee.getCode());
        assertThat(apres.current().bloc().code()).isEqualTo(EpreuveType.TCF_EE.name());
        invariantDuBadge(apres);
    }

    /**
     * <b>L'invariant general, sur cinq montages</b> — celui qui protege de la
     * prochaine divergence : {@code CURRENT != null} ⇒ son bloc est celui
     * marque {@code EN_COURS}.
     *
     * <p>⚠️ Une etape {@code DIAGNOSTIC} n'appartient a <b>aucun</b> bloc (R11,
     * A45) : elle est la seule exception, et {@link #invariantDuBadge} la laisse
     * passer explicitement.
     */
    @Test
    @DisplayName("D-57 — INVARIANT : CURRENT != null ⇒ son bloc est celui marque EN_COURS")
    void leBlocDeCurrentEstToujoursCeluiQuiPorteLeBadge() {
        Skill ee = skill("EE1-C1", SkillTaskCode.EE1);
        Skill eo = skill("EO1-C1", SkillTaskCode.EO1);
        eo.setSection(SkillSection.EO);
        when(progressCounter.bySkillIds(eq(user.getId()), anyCollection())).thenReturn(Map.of(
                ee.getId(), progres(List.of(UUID.randomUUID())),
                eo.getId(), progres(List.of(UUID.randomUUID()))));

        JourneyStep travailEe = trainStep(ee, 1);
        JourneyStep travailEo = trainStepDe(eo, EpreuveType.TCF_EO, 2);
        JourneyStep examenCo = examStep(EpreuveType.TCF_CO, 3);
        JourneyStep examenCe = examStep(EpreuveType.TCF_CE, 4);
        JourneyStep examenEe = examStep(EpreuveType.TCF_EE, 5);

        // 1. Un seul porteur de travail, abonne.
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        invariantDuBadge(service.lire(journey, List.of(travailEe, examenCo, examenEe)));
        // 2. Deux porteurs, abonne : les deux ordres divergent (A113).
        invariantDuBadge(service.lire(journey,
                List.of(travailEe, travailEo, examenCo, examenCe)));
        // 3. Un cycle de mesure, abonne.
        invariantDuBadge(service.lire(journey, List.of(examenCo, examenCe, examenEe)));
        // 4. Le meme parcours, compte gratuit : rien d'executable.
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.AUCUN);
        invariantDuBadge(service.lire(journey,
                List.of(travailEe, travailEo, examenCo, examenCe)));
        // 5. Tout le travail cloture, compte gratuit.
        travailEe.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        travailEo.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        invariantDuBadge(service.lire(journey,
                List.of(travailEe, travailEo, examenCo, examenCe)));
    }

    /**
     * 🛑 <b>L'invariant de D-57, ecrit une fois</b> : l'etape servie dans
     * {@code current} appartient au bloc que le cycle marque {@code EN_COURS}.
     *
     * <p>Deux echappatoires, toutes deux nommees : {@code current == null} (le
     * bloc meneur n'offre rien d'executable — D-18), et une etape
     * {@code DIAGNOSTIC}, qui n'appartient a aucun bloc.
     */
    private static void invariantDuBadge(JourneyDto vue) {
        JourneyStepDto current = vue.current();
        if (current == null || current.bloc() == null) return;
        assertThat(vue.blocs())
                .filteredOn(bloc -> bloc.bloc().code().equals(current.bloc().code()))
                .as("le bloc de CURRENT porte le badge EN_COURS")
                .extracting(JourneyBlocDto::status)
                .containsExactly(JourneyBlocStatus.EN_COURS);
    }

    private static List<String> codes(JourneyDto vue) {
        return vue.blocs().stream().map(bloc -> bloc.bloc().code()).toList();
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
        assertThat(co.etapesRestantes()).isZero();
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
    @DisplayName("D-15 — l'examen d'une THEMATIQUE est verrouille tant qu'une unite y reste "
            + "ouverte, exactement comme une epreuve")
    void lExamenDUneThematiqueEstVerrouilleParSesUnites() {
        journey.setModule(Module.CIVIQUE);
        journey.poserObjectif(TargetProcedure.NAT);
        Theme principes = theme("CIV_PRINCIPES", "Principes et valeurs de la Republique");
        Theme droits = theme("CIV_DROITS", "Droits et devoirs");
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(principes, droits));

        JourneyStep unite = etapeCivique(JourneyStepType.TRAIN_SKILL, droits, 1);
        JourneyStep examenDroits = etapeCivique(JourneyStepType.SECTION_EXAM, droits, 2);
        JourneyStep examenPrincipes = etapeCivique(JourneyStepType.SECTION_EXAM, principes, 3);

        JourneyDto vue = service.lire(
                journey, List.of(unite, examenDroits, examenPrincipes));

        // 🛑 LA REGLE, PAS LE MECANISME. D-15 dit : « l'examen d'un bloc est
        // verrouille tant qu'une unite du meme bloc reste ouverte ». Elle est
        // ecrite UNE fois et vaut pour les deux modules parce que la cle du
        // verrou est le CODE DE BLOC (D-47), jamais l'epreuve.
        assertThat(vue.blocs().get(1).exam().locked()).isTrue();
        // Le bloc voisin n'a aucune unite due : son examen reste ouvert. Un
        // verrou global aurait ferme les cinq.
        assertThat(vue.blocs().getFirst().exam().locked()).isFalse();
    }

    @Test
    @DisplayName("D-33 — sans acces civique, TOUTES les unites du cycle sont verrouillees, "
            + "et l'examen de thematique garde son verrou PEDAGOGIQUE")
    void sansAccesCiviqueLesUnitesSontVerrouillees() {
        journey.setModule(Module.CIVIQUE);
        journey.poserObjectif(TargetProcedure.NAT);
        Theme droits = theme("CIV_DROITS", "Droits et devoirs");
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(droits));
        when(subscriptionService.hasCivique(user.getId())).thenReturn(false);

        JourneyStep unite = etapeCivique(JourneyStepType.TRAIN_SKILL, droits, 1);
        JourneyStep autreUnite = etapeCivique(JourneyStepType.TRAIN_SKILL, droits, 2);
        JourneyStep examen = etapeCivique(JourneyStepType.SECTION_EXAM, droits, 3);

        JourneyDto vue = service.lire(journey, List.of(unite, autreUnite, examen));

        // 🛑 Le verrou EXISTAIT deja cote serveur (403 de
        // `demarrerSerieSurUnite`, D-33) : il est desormais SERVI, donc l'ecran
        // cesse de promettre un geste que le serveur refuse. 4e occurrence de
        // DETTE-P1, fermee en servant le fait plutot qu'en le recopiant.
        assertThat(vue.blocs().getFirst().steps())
                .isNotEmpty()
                .allSatisfy(step -> assertThat(step.locked()).isTrue());
        // ⚠️ Et le Plan reste LISIBLE : on floute l'ACTION, jamais le RESULTAT
        // mesure (D-18). Les etapes sont toutes servies, avec leur nom.
        assertThat(vue.blocs().getFirst().steps()).hasSize(2);
        // D-1 : plus rien d'executable ⇒ pas de main, et l'etat le dit.
        assertThat(vue.current()).isNull();
        assertThat(vue.state()).isEqualTo(JourneyState.LOCKED);
    }

    @Test
    @DisplayName("D-33 — avec l'acces civique, aucune unite n'est verrouillee")
    void avecAccesCiviqueLesUnitesSontOuvertes() {
        journey.setModule(Module.CIVIQUE);
        journey.poserObjectif(TargetProcedure.NAT);
        Theme droits = theme("CIV_DROITS", "Droits et devoirs");
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(droits));
        when(subscriptionService.hasCivique(user.getId())).thenReturn(true);

        JourneyStep unite = etapeCivique(JourneyStepType.TRAIN_SKILL, droits, 1);

        JourneyDto vue = service.lire(journey, List.of(unite));

        assertThat(vue.blocs().getFirst().steps())
                .allSatisfy(step -> assertThat(step.locked()).isFalse());
        assertThat(vue.current()).isNotNull();
    }

    @Test
    @DisplayName("🛑 Le verrou civique ne DEBORDE PAS sur le TCF : un abonnement civique absent "
            + "ne ferme aucune etape d'un parcours TCF")
    void leVerrouCiviqueNeDebordePasSurLeTcf() {
        // Le candidat n'a pas d'acces civique -- ce qui ne dit RIEN de son
        // parcours TCF, dont l'acces est porte par `SkillAccessService`.
        when(subscriptionService.hasCivique(user.getId())).thenReturn(false);
        when(accessService.resolve(user.getId()))
                .thenReturn(SkillAccessService.SkillAccess.UNLIMITED);
        Skill competence = skill("EE1-C1", SkillTaskCode.EE1);
        JourneyStep entrainement = trainStep(competence, 1);

        JourneyDto vue = service.lire(journey, List.of(entrainement));

        assertThat(bloc(vue, EpreuveType.TCF_EE).steps())
                .allSatisfy(step -> assertThat(step.locked()).isFalse());
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
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }

    // ------------------------------------------------------------- fabriques

    private static SkillProgressCounter.SkillProgress progres(List<UUID> sujets) {
        return new SkillProgressCounter.SkillProgress(
                sujets.size(), 0, 0, 0,
                new LearningPlanStep.Progress(sujets, 0, 0));
    }

    // =====================================================================
    // D-50 / P8.4 point 3 — L'AXE DES BLOCS N'EST PLUS UN ENUM
    // =====================================================================

    @Test
    @DisplayName("Cycle CIVIQUE : l'axe est les cinq thematiques, dans l'ordre d'affichage")
    void lAxeCiviqueEstCeluiDesThematiques() {
        journey.setModule(Module.CIVIQUE);
        journey.poserObjectif(TargetProcedure.NAT);
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(
                        theme("CIV_PRINCIPES", "Principes et valeurs de la Republique"),
                        theme("CIV_INSTITUTIONS", "Systeme institutionnel et politique"),
                        theme("CIV_DROITS", "Droits et devoirs"),
                        theme("CIV_HISTOIRE", "Histoire et geographie"),
                        theme("CIV_SOCIETE", "Societe francaise")));

        JourneyDto vue = service.lire(journey, List.of());

        // 🛑 CINQ blocs, pas quatre, et dans l'ordre SERVI : l'ordre des
        // thematiques est une DONNEE (`themes.display_order`), pas un enum.
        assertThat(vue.blocs()).hasSize(5);
        assertThat(vue.blocs().stream().map(b -> b.bloc().code()))
                .containsExactly("CIV_PRINCIPES", "CIV_INSTITUTIONS", "CIV_DROITS",
                        "CIV_HISTOIRE", "CIV_SOCIETE");
        // Le bloc est SERVI : sa nature et son libelle arrivent du serveur.
        assertThat(vue.blocs().getFirst().bloc().kind())
                .isEqualTo(JourneyBlocKind.THEMATIQUE);
        assertThat(vue.blocs().getFirst().bloc().label())
                .isEqualTo("Principes et valeurs de la Republique");
        // ⚠️ ETAT DE TRANSITION : rien n'ecrit encore d'observation civique
        // (P8.4 point 5), donc aucune thematique n'a ete mesuree. `A_EVALUER`
        // est litteralement vrai ; `TERMINE` aurait ete un verdict invente.
        assertThat(vue.blocs()).allSatisfy(bloc ->
                assertThat(bloc.status()).isEqualTo(JourneyBlocStatus.A_EVALUER));
        // 🛑 Et `TcfDomainProfileDto.ORDRE` n'a pas bouge : aucun bloc TCF ici.
        assertThat(vue.blocs().stream().map(b -> b.bloc().code()))
                .noneMatch(code -> code.startsWith("TCF_"));
    }

    @Test
    @DisplayName("Cycle CIVIQUE : une etape tombe dans le bloc de SA thematique")
    void uneEtapeCiviqueTombeDansSonBloc() {
        journey.setModule(Module.CIVIQUE);
        journey.poserObjectif(TargetProcedure.NAT);
        Theme principes = theme("CIV_PRINCIPES", "Principes et valeurs de la Republique");
        Theme droits = theme("CIV_DROITS", "Droits et devoirs");
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(principes, droits));

        JourneyStep examen = new JourneyStep();
        examen.setId(UUID.randomUUID());
        examen.setJourney(journey);
        examen.setType(JourneyStepType.SECTION_EXAM);
        examen.setPurpose(JourneyStepPurpose.REASSESS);
        examen.poserBloc(droits);
        examen.setPosition(1L);
        examen.setCreatedAt(Instant.now().minusSeconds(3_600));

        JourneyDto vue = service.lire(journey, List.of(examen));

        assertThat(vue.blocs().getFirst().exam()).isNull();
        assertThat(vue.blocs().get(1).exam()).isNotNull();
        assertThat(vue.blocs().get(1).bloc().code()).isEqualTo("CIV_DROITS");
    }

    /**
     * Une etape civique : son bloc est une <b>thematique</b>, et elle ne porte
     * <b>aucun</b> {@code EpreuveType} — c'est precisement ce qui faisait lever
     * le verrou de bloc avant A63.
     */
    private JourneyStep etapeCivique(JourneyStepType type, Theme thematique, long position) {
        JourneyStep step = new JourneyStep();
        step.setId(UUID.randomUUID());
        step.setJourney(journey);
        step.setType(type);
        if (type == JourneyStepType.SECTION_EXAM) {
            step.setPurpose(JourneyStepPurpose.REASSESS);
        }
        step.poserBloc(thematique);
        step.setPosition(position);
        step.setCreatedAt(Instant.now().minusSeconds(3_600));
        return step;
    }

    private static Theme theme(String code, String nom) {
        Theme theme = new Theme();
        theme.setId(UUID.randomUUID());
        theme.setModule(Module.CIVIQUE);
        theme.setCode(code);
        theme.setName(nom);
        return theme;
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

    /** Une etape d'entrainement sur une AUTRE epreuve que `TCF_EE`. */
    private JourneyStep trainStepDe(Skill skill, EpreuveType epreuve, long position) {
        JourneyStep step = trainStep(skill, position);
        step.setExamType(epreuve);
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
