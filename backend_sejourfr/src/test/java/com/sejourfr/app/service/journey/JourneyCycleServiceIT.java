package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyAssessmentEventRepository;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>Les deux transitions de fin de cycle</b> (spec §6, arbitrages D-12 / D-13).
 *
 * <p>Ce qui est verrouille ici : ce qu'un cycle termine <b>devient</b>, et ce
 * qu'un cycle inachieve <b>refuse</b>. Les deux gestes historisent le cycle en
 * cours — les autoriser trop tot jetterait le plan que le candidat a sous les
 * yeux.
 *
 * <p>Non transactionnel, pour la meme raison que {@link JourneyServiceIT} : le
 * parcours ecrit en {@link Propagation#REQUIRES_NEW}, et une transaction de test
 * l'empecherait de voir ce que le test vient d'ecrire.
 *
 * <p>🛑 <b>Les cycles sont montes a la main</b>, etape par etape, plutot que
 * joues par une suite d'evaluations : ce qui est teste est la <b>transition</b>,
 * pas la construction — celle-la est verrouillee par {@link JourneyServiceIT}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyCycleServiceIT extends AbstractIntegrationTest {

    @Autowired private JourneyCycleService cycleService;
    @Autowired private JourneyService journeyService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyAssessmentEventRepository events;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;
    @Autowired private AccountDeletionService accountDeletionService;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    // =====================================================================
    // Actualiser mon plan
    // =====================================================================

    @Test
    @DisplayName("refresh — le cycle est historise avec son niveau de sortie, le cycle en "
            + "attente est promu, et le numero avance")
    void actualiserHistoriseEtPromeutLeCycleEnAttente() {
        User user = candidat();
        // Une epreuve reellement passee : c'est elle qui donne un niveau global,
        // donc un niveau de sortie.
        data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        Journey termine = cycleTermine(user);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        Skill competence = skill(SkillTaskCode.EE1, 1);
        entrainement(attente, competence);
        assertThat(journeyService.lire(user.getId()).cycle().numero()).isEqualTo(1);

        JourneyDto apres = cycleService.actualiser(user.getId());

        Journey historise = journeys.findById(termine.getId()).orElseThrow();
        assertThat(historise.getStatus()).isEqualTo(JourneyStatus.HISTORISE);
        // 🛑 Un FAIT DATE (D-12) : « voila ou en etait le candidat quand ce cycle
        // s'est ferme ». Il ne sera jamais recalcule.
        assertThat(historise.getHistoriseAt()).isNotNull();
        assertThat(historise.getExitLevel()).isEqualTo(TargetLevel.B1);

        Journey promu = journeys.findById(attente.getId()).orElseThrow();
        assertThat(promu.getStatus()).isEqualTo(JourneyStatus.EN_COURS);
        // Le niveau d'entree du suivant EST le niveau de sortie du precedent :
        // c'est ce qui rend l'historique lisible d'un cycle a l'autre.
        assertThat(promu.getEntryLevel()).isEqualTo(TargetLevel.B1);
        // Le cycle promu est celui que le candidat lit maintenant, et son rang a
        // avance.
        assertThat(apres.cycle().numero()).isEqualTo(2);
        assertThat(apres.state()).isEqualTo(JourneyState.IN_PROGRESS);
        assertThat(competencesServies(apres)).contains(competence.getCode());
        // 🛑 Le prochain cycle en attente reste PARESSEUX : aucune ligne vide
        // d'avance.
        assertThat(journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE)).isEmpty();
    }

    @Test
    @DisplayName("refresh — sans aucune mesure, le niveau de sortie reste NULL (jamais 0, jamais A1)")
    void leNiveauDeSortieResteInconnuSansMesure() {
        User user = candidat();
        Journey termine = cycleTermine(user);

        cycleService.actualiser(user.getId());

        // 🛑 null = INCONNU, jamais mauvais. Un cycle ferme sans qu'aucune
        // epreuve n'ait ete mesuree n'a pas de niveau de sortie — et surtout pas
        // « le palier le plus bas » : c'est la confusion exacte qui a produit
        // les faux A1_NON_ATTEINT (V040/V041/V042).
        Journey historise = journeys.findById(termine.getId()).orElseThrow();
        assertThat(historise.getExitLevel()).isNull();
        assertThat(historise.getHistoriseAt()).isNotNull();
    }

    @Test
    @DisplayName("refresh — refuse (409) tant que le cycle n'est pas termine")
    void actualiserEstRefuseSurUnCycleInacheve() {
        User user = candidat();
        Journey enCours = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        examen(enCours, EpreuveType.TCF_CO, JourneyStepPurpose.INITIAL_ASSESSMENT, false);

        // IllegalStateException ⇒ 409 CONFLICT (convention du
        // GlobalExceptionHandler) : ce geste historise, il ne doit jamais jeter
        // un plan en cours.
        assertThatThrownBy(() -> cycleService.actualiser(user.getId()))
                .isInstanceOf(IllegalStateException.class);
        assertThat(journeys.findById(enCours.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.EN_COURS);
    }

    // =====================================================================
    // Passer l'examen blanc complet — le cycle de mesure
    // =====================================================================

    @Test
    @DisplayName("measurement-cycle — quatre examens, TOUS debloques, et le cycle precedent "
            + "est historise")
    void leCycleDeMesurePorteQuatreExamensTousDebloques() {
        User user = abonne();
        Journey precedent = cycleTermine(user);
        // Le cycle en attente est laisse TEL QUEL : c'est tout l'objet de cette
        // issue.
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        entrainement(attente, skill(SkillTaskCode.EE1, 1));

        JourneyDto mesure = cycleService.creerCycleDeMesure(user.getId());

        assertThat(journeys.findById(precedent.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.HISTORISE);
        assertThat(journeys.findById(attente.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.EN_ATTENTE);
        // 🛑 Un cycle de mesure est DERIVE : aucune etape d'entrainement.
        assertThat(mesure.cycle().cycleDeMesure()).isTrue();
        assertThat(mesure.cycle().etapesTotal()).isEqualTo(TcfDomainProfileDto.ORDRE.size());
        assertThat(mesure.blocs()).allSatisfy(bloc -> {
            assertThat(bloc.exam()).as("examen du bloc " + bloc.examType()).isNotNull();
            // Tous debloques : le verrou du bloc (D-15) ne se pose que sur une
            // competence restante, et il n'y en a aucune.
            assertThat(bloc.exam().locked()).isFalse();
            assertThat(bloc.competencesRestantes()).isZero();
        });
        assertThat(mesure.blocs()).extracting(bloc -> bloc.examType())
                .containsExactlyElementsOf(TcfDomainProfileDto.ORDRE);
    }

    @Test
    @DisplayName("measurement-cycle — un cycle de mesure termine n'offre QUE l'actualisation")
    void unCycleDeMesureTermineNOffreQueLActualisation() {
        User user = abonne();
        cycleTermine(user);
        cycleService.creerCycleDeMesure(user.getId());
        Journey mesure = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
        cloreToutesLesEtapes(mesure);

        JourneyDto vue = journeyService.lire(user.getId());

        assertThat(vue.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(vue.cycle().complete()).isTrue();
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.blocs()).allSatisfy(bloc ->
                assertThat(bloc.status()).isEqualTo(JourneyBlocStatus.TERMINE));
        // 🛑 Enchainer un second examen complet sans travail entre les deux ne
        // mesure rien de nouveau : la seule issue est d'actualiser.
        assertThat(vue.nextStep()).isNotNull();
        assertThat(vue.nextStep().actualisationPossible()).isTrue();
        assertThat(vue.nextStep().examenCompletPossible()).isFalse();
        // Et le serveur le refuse, il ne se contente pas de ne pas le proposer.
        assertThatThrownBy(() -> cycleService.creerCycleDeMesure(user.getId()))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("R14 / D-13 — une evaluation deja traitee ne se rejoue pas apres une actualisation")
    void uneEvaluationDejaTraiteeNeSeRejouePasApresUneActualisation() {
        User user = abonne();
        Journey precedent = cycleTermine(user);
        UUID evaluation = UUID.randomUUID();
        evenementTraite(precedent, evaluation, EpreuveType.TCF_EE);
        cycleService.actualiser(user.getId());

        // Le rejeu arrive APRES la promotion : le cycle courant n'est plus celui
        // qui avait journalise cette evaluation.
        Skill competence = skill(SkillTaskCode.EE1, 2);
        data.learningPlanObservation(user, competence,
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, Instant.now(), evaluation);
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                evaluation, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE,
                Instant.now()));

        // 🛑 La question « l'a-t-on deja traitee ? » est posee au CANDIDAT, pas
        // au cycle : la cle d'unicite porte le journey_id, mais une lecture
        // bornee au cycle courant aurait refabrique un lot deja honore.
        assertThat(competencesServies(journeyService.lire(user.getId())))
                .doesNotContain(competence.getCode());
    }

    // ------------------------------------------------------------- fabriques

    /**
     * Les competences servies, tous blocs confondus. Depuis P6,
     * {@code JourneyDto.steps} a disparu : la lecture du cycle est
     * {@code blocs}.
     */
    private static List<String> competencesServies(JourneyDto vue) {
        return vue.blocs().stream()
                .flatMap(bloc -> bloc.steps().stream())
                .map(step -> step.skillCode())
                .toList();
    }

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    private User abonne() {
        User user = candidat();
        data.userSubscription(user, data.plan());
        return user;
    }

    /**
     * Un cycle en cours <b>de travail</b>, dont toutes les etapes sont
     * cloturees : une competence faite et son examen passe.
     *
     * <p>⚠️ La competence compte : un cycle qui ne porterait que des examens
     * serait un <b>cycle de mesure</b> (derivation de la spec §6), et
     * l'actualisation en serait la seule issue.
     */
    private Journey cycleTermine(User user) {
        Journey journey = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        entrainement(journey, skill(SkillTaskCode.EE1, 0), true);
        examen(journey, EpreuveType.TCF_EE, JourneyStepPurpose.REASSESS, true);
        return journey;
    }

    private JourneyStep examen(
            Journey journey, EpreuveType epreuve, JourneyStepPurpose purpose, boolean close) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(purpose);
        step.setExamType(epreuve);
        step.setPosition(journey.consommerPosition());
        if (close) {
            step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                    Instant.now());
        }
        journeys.saveAndFlush(journey);
        return steps.saveAndFlush(step);
    }

    /**
     * Une etape d'entrainement <b>et son lot</b> :
     * {@code chk_journey_step_train_skill} exige les deux ensemble, et c'est
     * voulu — une competence sans lot serait une priorite qu'aucune evaluation
     * n'a designee.
     */
    private void entrainement(Journey journey, Skill competence) {
        entrainement(journey, competence, false);
    }

    private void entrainement(Journey journey, Skill competence, boolean close) {
        JourneyLot lot = new JourneyLot();
        lot.setJourney(journey);
        lot.setExamType(EpreuveType.TCF_EE);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        lot = lots.saveAndFlush(lot);

        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(EpreuveType.TCF_EE);
        step.setSkill(competence);
        step.setPosition(journey.consommerPosition());
        if (close) {
            step.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        }
        journeys.saveAndFlush(journey);
        steps.saveAndFlush(step);
    }

    /** Une evaluation que ce cycle a deja traitee — le journal de R14. */
    private void evenementTraite(Journey journey, UUID sourceAssessmentId, EpreuveType epreuve) {
        JourneyAssessmentEvent event = new JourneyAssessmentEvent();
        event.setJourney(journey);
        event.setSourceAssessmentId(sourceAssessmentId);
        event.setAssessmentKind(JourneyAssessmentKind.SECTION_EXAM);
        event.setExamType(epreuve);
        event.setCompletedAt(Instant.now().minusSeconds(600));
        events.saveAndFlush(event);
    }

    private void cloreToutesLesEtapes(Journey journey) {
        for (JourneyStep step : steps.findAllByJourney(journey.getId())) {
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                    Instant.now())) {
                steps.saveAndFlush(step);
            }
        }
    }

    /**
     * Une competence du <b>referentiel seede</b>, jamais une competence creee :
     * ces tests ne sont pas transactionnels, et une competence creee survivrait
     * a la classe.
     */
    private Skill skill(SkillTaskCode taskCode, int rang) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(taskCode);
        assertThat(seedees).as("referentiel seede pour " + taskCode).hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }

    private Skill skill(SkillTaskCode taskCode) {
        return skill(taskCode, 0);
    }
}
