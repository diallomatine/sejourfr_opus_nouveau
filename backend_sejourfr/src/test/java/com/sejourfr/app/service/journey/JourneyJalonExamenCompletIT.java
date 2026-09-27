package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyExamenCompletDto;
import com.sejourfr.app.dto.JourneyHistoryCycleDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyJalonRaison;
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
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyAssessmentEventRepository;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.LearningPlanService;
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
 * <b>La fin de cycle, le budget du cycle suivant et le jalon d'examen complet</b>
 * (2026-09-27, decisions du proprietaire D-66 / D-67 / D-68).
 *
 * <ul>
 *   <li><b>D-66</b> — la fin de cycle ne propose QUE « Actualiser mon plan » ;</li>
 *   <li><b>D-67</b> — le cycle suivant retient au plus trois priorites par
 *       epreuve, le moteur calculant toujours tout ; le nombre retenu est
 *       servi ({@code cycle.prioritesCycleSuivant}) ;</li>
 *   <li><b>D-68</b> — l'examen blanc complet devient un jalon propose (3 cycles
 *       de travail depuis le dernier examen complet, ou objectif atteint partout
 *       par examen) ; au clic, le cycle est mis de cote ({@code INTERROMPU}) et
 *       un cycle d'examens devient courant.</li>
 * </ul>
 *
 * <p>Non transactionnel, comme {@link JourneyCycleServiceIT} : le parcours ecrit
 * en {@code REQUIRES_NEW}. 🛑 Les cycles historises sont <b>montes a la main</b>
 * — ce qui est teste est la regle du jalon, pas la construction d'un cycle.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyJalonExamenCompletIT extends AbstractIntegrationTest {

    @Autowired private JourneyCycleService cycleService;
    @Autowired private JourneyService journeyService;
    @Autowired private JourneyHistoryService historyService;
    @Autowired private LearningPlanService learningPlanService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;
    @Autowired private JourneyAssessmentEventRepository events;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;
    @Autowired private AccountDeletionService accountDeletionService;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    // =====================================================================
    // D-66 — la fin de cycle : l'actualisation, et elle seule
    // =====================================================================

    @Test
    @DisplayName("D-66 — un cycle de travail termine n'offre QUE l'actualisation, sans jalon")
    void laFinDeCycleNOffreQueLActualisation() {
        User user = abonne();
        cycleDeTravail(user, JourneyStatus.EN_COURS, true, null);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(vue.nextStep()).isNotNull();
        assertThat(vue.nextStep().actualisationPossible()).isTrue();
        // Un seul cycle de travail : le jalon n'est pas propose, et le geste
        // est refuse par la meme autorite.
        assertThat(vue.examenComplet()).isNull();
        assertThatThrownBy(() -> cycleService.creerCycleDeMesure(user.getId(), Module.TCF))
                .isInstanceOf(IllegalStateException.class);
    }

    // =====================================================================
    // D-67 — le budget du cycle suivant, et le nombre servi
    // =====================================================================

    @Test
    @DisplayName("D-67 — cinq priorites EE detectees : le moteur les calcule toutes, le cycle "
            + "suivant en retient trois, et c'est ce nombre qui est servi")
    void leCycleSuivantRetientTroisPrioritesParEpreuve() {
        User user = abonne();
        // Un diagnostic rapide clos : le Plan existe (prep.planDisponible).
        data.diagnosticSession(user, com.sejourfr.app.enums.DiagnosticSessionStatus.COMPLETED);
        Journey enCours = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        // Un cycle AMORCE (il porte un examen) : les priorites d'une evaluation
        // partent dans le cycle en attente.
        examen(enCours, EpreuveType.TCF_CO, JourneyStepPurpose.REASSESS, false);

        UUID examen = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1).getId();
        List<Skill> cinq = new ArrayList<>();
        for (int rang = 0; rang < 5; rang++) {
            Skill competence = skill(SkillTaskCode.EE1, rang);
            cinq.add(competence);
            data.learningPlanObservation(user, competence,
                    LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                    ObservationConfidence.HIGH, null, Instant.now(), examen);
        }
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen, JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE, Instant.now()));

        // 🛑 Le moteur calcule TOUT : le Plan voit les cinq fragilites de l'EE.
        PlanDomainDto ee = learningPlanService.get(user.getId()).domaines().stream()
                .filter(domaine -> domaine.epreuve() == EpreuveType.TCF_EE)
                .findFirst().orElseThrow();
        assertThat(ee.fragileSkillCount()).isEqualTo(cinq.size());

        // 🛑 Le cycle suivant en RETIENT trois, les plus urgentes.
        Journey attente = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE).orElseThrow();
        List<JourneyStep> retenues = steps.findAllByJourney(attente.getId()).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(JourneyStep::estOuverte)
                .toList();
        assertThat(retenues).hasSize(3)
                .allSatisfy(step -> assertThat(step.getExamType()).isEqualTo(EpreuveType.TCF_EE));

        // Et c'est CE nombre qui est servi sous « Actualiser mon plan ».
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        assertThat(vue.cycle().prioritesCycleSuivant()).isEqualTo(3);
    }

    @Test
    @DisplayName("D-67 — le nombre annonce est exactement ce que l'actualisation promeut")
    void leNombreAnnonceEstCeQueLActualisationPromeut() {
        User user = abonne();
        cycleDeTravail(user, JourneyStatus.EN_COURS, true, null);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        // Un lot par epreuve (uq_journey_lot_open_par_epreuve) : trois EE, une EO.
        lotOuvert(attente, EpreuveType.TCF_EE, skill(SkillTaskCode.EE1, 1),
                skill(SkillTaskCode.EE1, 2), skill(SkillTaskCode.EE1, 3));
        lotOuvert(attente, EpreuveType.TCF_EO, skill(SkillTaskCode.EO1, 0));

        int annonce = journeyService.lire(user.getId(), Module.TCF).cycle().prioritesCycleSuivant();
        JourneyDto suivant = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(annonce).isEqualTo(4);
        long promues = suivant.blocs().stream().mapToLong(bloc -> bloc.steps().size()).sum();
        assertThat(promues).isEqualTo(annonce);
        // Plus rien en attente : le cycle suivant du nouveau cycle est vide.
        assertThat(suivant.cycle().prioritesCycleSuivant()).isZero();
    }

    // =====================================================================
    // D-68 — le jalon : 3 cycles de travail depuis le dernier examen complet
    // =====================================================================

    @Test
    @DisplayName("D-68 — deux cycles de travail : pas de jalon ; le troisieme termine le propose")
    void leJalonArriveAuTroisiemeCycleDeTravailTermine() {
        User user = abonne();
        cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        Journey courant = cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet())
                .as("deux cycles termines, le troisieme en cours")
                .isNull();

        cloreToutesLesEtapes(courant);
        JourneyExamenCompletDto jalon = journeyService.lire(user.getId(), Module.TCF).examenComplet();

        assertThat(jalon).isNotNull();
        assertThat(jalon.raison()).isEqualTo(JourneyJalonRaison.CYCLES_DE_TRAVAIL);
        assertThat(jalon.cyclesDeTravail()).isEqualTo(3);
    }

    @Test
    @DisplayName("D-68 — au clic, le cycle en cours est ARCHIVE « interrompu » et un cycle "
            + "d'examens est cree ; le cycle en attente est intact et l'historique le raconte")
    void leClicInterromptLeCycleEtOuvreUnCycleDExamens() {
        User user = abonne();
        for (int i = 0; i < 3; i++) {
            cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        }
        Journey courant = cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        entrainement(attente, skill(SkillTaskCode.EE1, 4), EpreuveType.TCF_EE, false);

        JourneyDto avant = journeyService.lire(user.getId(), Module.TCF);
        assertThat(avant.examenComplet()).isNotNull();
        assertThat(avant.nextStep()).as("le cycle en cours n'est pas termine").isNull();

        JourneyDto examens = cycleService.creerCycleDeMesure(user.getId(), Module.TCF);

        Journey interrompu = journeys.findById(courant.getId()).orElseThrow();
        assertThat(interrompu.getStatus()).isEqualTo(JourneyStatus.HISTORISE);
        assertThat(interrompu.getFinDeCycle()).isEqualTo(JourneyFinDeCycle.INTERROMPU);
        // 🛑 Les etapes non terminees sont historisees TELLES QUELLES : rien
        // n'est reporte a la main, les examens recalculeront.
        assertThat(steps.findAllByJourney(courant.getId()))
                .anySatisfy(step -> assertThat(step.estOuverte()).isTrue());
        assertThat(journeys.findById(attente.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.EN_ATTENTE);

        // Le cycle d'examens : un bloc par epreuve, chacun son seul examen,
        // tous ouverts (abonne), et le jalon n'y est plus propose.
        assertThat(examens.cycle().cycleDeMesure()).isTrue();
        assertThat(examens.cycle().etapesTotal()).isEqualTo(TcfDomainProfileDto.ORDRE.size());
        assertThat(examens.blocs()).allSatisfy(bloc -> {
            assertThat(bloc.exam()).isNotNull();
            assertThat(bloc.exam().locked()).isFalse();
        });
        assertThat(examens.current()).isNotNull();
        assertThat(examens.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(examens.examenComplet()).isNull();
        assertThat(examens.cycle().prioritesCycleSuivant())
                .as("le cycle en attente, laisse tel quel, porte toujours sa priorite")
                .isEqualTo(1);

        // « Mes cycles » raconte l'interruption, sur la liste comme en consultation.
        JourneyHistoryCycleDto ligne = historyService.lire(user.getId(), Module.TCF).cycles().stream()
                .filter(cycle -> cycle.journeyId().equals(courant.getId()))
                .findFirst().orElseThrow();
        assertThat(ligne.finDeCycle()).isEqualTo(JourneyFinDeCycle.INTERROMPU);
        assertThat(historyService.lireCycle(user.getId(), courant.getId()).finDeCycle())
                .isEqualTo(JourneyFinDeCycle.INTERROMPU);
    }

    @Test
    @DisplayName("D-68 — un cycle deja TERMINE clos par le jalon garde « examen complet », "
            + "pas « interrompu »")
    void unCycleTermineCloseParLeJalonNEstPasInterrompu() {
        User user = abonne();
        for (int i = 0; i < 2; i++) {
            cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        }
        Journey courant = cycleDeTravail(user, JourneyStatus.EN_COURS, true, null);

        cycleService.creerCycleDeMesure(user.getId(), Module.TCF);

        assertThat(journeys.findById(courant.getId()).orElseThrow().getFinDeCycle())
                .isEqualTo(JourneyFinDeCycle.EXAMEN_COMPLET);
    }

    @Test
    @DisplayName("D-68 — le compteur repart de zero apres un examen complet, et le jalon "
            + "revient tous les trois cycles de travail")
    void leCompteurRepartDeZeroApresUnExamenComplet() {
        User user = abonne();
        for (int i = 0; i < 2; i++) {
            cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        }
        // Le troisieme a ete mis de cote par le jalon, puis le cycle d'examens a
        // ete actualise : il ne porte aucun entrainement.
        cycleDeTravail(user, JourneyStatus.HISTORISE, false, JourneyFinDeCycle.INTERROMPU);
        cycleDExamensClos(user);
        cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        Journey courant = cycleDeTravail(user, JourneyStatus.EN_COURS, true, null);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        assertThat(vue.examenComplet())
                .as("deux cycles de travail depuis l'examen complet")
                .isNull();

        // Un cycle de travail de plus : le jalon revient.
        cycleService.actualiser(user.getId(), Module.TCF);
        assertThat(journeys.findById(courant.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.HISTORISE);
        Journey suivant = journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
        entrainement(suivant, skill(SkillTaskCode.EE1, 5), EpreuveType.TCF_EE, true);
        cloreToutesLesEtapes(suivant);

        JourneyExamenCompletDto jalon = journeyService.lire(user.getId(), Module.TCF).examenComplet();
        assertThat(jalon).isNotNull();
        assertThat(jalon.cyclesDeTravail()).isEqualTo(3);
    }

    @Test
    @DisplayName("D-68 — le cycle d'AFFINAGE ne compte pas comme cycle de travail")
    void leCycleDAffinageNeComptePas() {
        User user = abonne();
        Journey affinage = cycleDeTravail(
                user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        amorceParLeDiagnosticRapide(affinage);
        cycleDeTravail(user, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        cycleDeTravail(user, JourneyStatus.EN_COURS, true, null);

        // Trois cycles « avec entrainement », dont l'affinage : deux de travail.
        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet()).isNull();
    }

    @Test
    @DisplayName("D-68 — isolation : les cycles d'un autre candidat ne comptent jamais")
    void lesCyclesDUnAutreCandidatNeComptentPas() {
        User autre = abonne();
        for (int i = 0; i < 3; i++) {
            cycleDeTravail(autre, JourneyStatus.HISTORISE, true, JourneyFinDeCycle.ACTUALISATION);
        }
        cycleDeTravail(autre, JourneyStatus.EN_COURS, false, null);
        User user = abonne();
        cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        assertThat(journeyService.lire(autre.getId(), Module.TCF).examenComplet()).isNotNull();
        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet()).isNull();
        assertThatThrownBy(() -> cycleService.creerCycleDeMesure(user.getId(), Module.TCF))
                .isInstanceOf(IllegalStateException.class);
        // Le cycle de l'autre candidat n'a pas bouge.
        assertThat(journeys.findByUserIdAndModuleAndStatus(
                autre.getId(), Module.TCF, JourneyStatus.EN_COURS)).isPresent();
    }

    // ------------------------------------------------------------- fabriques

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
     * Un cycle de TRAVAIL : une competence et l'examen EE de son bloc.
     *
     * @param termine toutes ses etapes closes, ou la competence encore ouverte.
     * @param fin     le geste qui l'a clos, s'il est historise.
     */
    private Journey cycleDeTravail(
            User user, JourneyStatus status, boolean termine, JourneyFinDeCycle fin) {
        Journey journey = data.journey(user, Module.TCF, status);
        entrainement(journey, skill(SkillTaskCode.EE1, 0), EpreuveType.TCF_EE, termine);
        examen(journey, EpreuveType.TCF_EE, JourneyStepPurpose.REASSESS, termine);
        if (fin != null) {
            journey = journeys.findById(journey.getId()).orElseThrow();
            journey.setFinDeCycle(fin);
            journey = journeys.saveAndFlush(journey);
        }
        return journey;
    }

    /** Le cycle d'examens qui suit une interruption, clos par l'actualisation. */
    private void cycleDExamensClos(User user) {
        Journey journey = data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            examen(journey, epreuve, JourneyStepPurpose.REASSESS, true);
        }
        journey = journeys.findById(journey.getId()).orElseThrow();
        journey.setFinDeCycle(JourneyFinDeCycle.ACTUALISATION);
        journeys.saveAndFlush(journey);
    }

    /** Pose sur ce cycle la marque d'une amorce par le diagnostic rapide (D-64). */
    private void amorceParLeDiagnosticRapide(Journey journey) {
        UUID diagnostic = UUID.randomUUID();
        JourneyLot lot = lots.findAll().stream()
                .filter(l -> l.getJourney().getId().equals(journey.getId()))
                .findFirst().orElseThrow();
        lot.setSourceAssessmentId(diagnostic);
        lots.saveAndFlush(lot);
        JourneyAssessmentEvent event = new JourneyAssessmentEvent();
        event.setJourney(journey);
        event.setSourceAssessmentId(diagnostic);
        event.setAssessmentKind(JourneyAssessmentKind.QUICK_DIAGNOSTIC);
        event.setCompletedAt(Instant.now().minusSeconds(600));
        events.saveAndFlush(event);
    }

    private JourneyStep examen(
            Journey journey, EpreuveType epreuve, JourneyStepPurpose purpose, boolean close) {
        Journey frais = journeys.findById(journey.getId()).orElseThrow();
        JourneyStep step = new JourneyStep();
        step.setJourney(frais);
        step.setType(JourneyStepType.SECTION_EXAM);
        step.setPurpose(purpose);
        step.setExamType(epreuve);
        step.setPosition(frais.consommerPosition());
        if (close) {
            step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT, UUID.randomUUID(),
                    Instant.now());
        }
        journeys.saveAndFlush(frais);
        return steps.saveAndFlush(step);
    }

    private void entrainement(Journey journey, Skill competence, EpreuveType epreuve, boolean close) {
        Journey frais = journeys.findById(journey.getId()).orElseThrow();
        JourneyLot lot = new JourneyLot();
        lot.setJourney(frais);
        lot.setExamType(epreuve);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        if (close) lot.clore(JourneyLotStatus.CLOSED, UUID.randomUUID(), Instant.now());
        lot = lots.saveAndFlush(lot);

        JourneyStep step = new JourneyStep();
        step.setJourney(frais);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(epreuve);
        step.setSkill(competence);
        step.setPosition(frais.consommerPosition());
        if (close) step.clore(JourneyStepResolution.QUOTA_REACHED, null, Instant.now());
        journeys.saveAndFlush(frais);
        steps.saveAndFlush(step);
    }

    /** Un lot ouvert de ce cycle, portant ces competences dans l'ordre. */
    private void lotOuvert(Journey journey, EpreuveType epreuve, Skill... competences) {
        Journey frais = journeys.findById(journey.getId()).orElseThrow();
        JourneyLot lot = new JourneyLot();
        lot.setJourney(frais);
        lot.setExamType(epreuve);
        lot.setStatus(JourneyLotStatus.OPEN);
        lot.setSourceAssessmentId(UUID.randomUUID());
        lot = lots.saveAndFlush(lot);
        for (Skill competence : competences) {
            JourneyStep step = new JourneyStep();
            step.setJourney(frais);
            step.setLot(lot);
            step.setType(JourneyStepType.TRAIN_SKILL);
            step.setExamType(epreuve);
            step.setSkill(competence);
            step.setPosition(frais.consommerPosition());
            journeys.saveAndFlush(frais);
            steps.saveAndFlush(step);
        }
    }

    private void cloreToutesLesEtapes(Journey journey) {
        for (JourneyStep step : steps.findAllByJourney(journey.getId())) {
            boolean entrainement = step.getType() == JourneyStepType.TRAIN_SKILL;
            if (step.clore(entrainement
                            ? JourneyStepResolution.QUOTA_REACHED
                            : JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    entrainement ? null : UUID.randomUUID(), Instant.now())) {
                steps.saveAndFlush(step);
            }
        }
    }

    /** Une competence du referentiel SEEDE, jamais creee (tests non transactionnels). */
    private Skill skill(SkillTaskCode taskCode, int rang) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(taskCode);
        assertThat(seedees).as("referentiel seede pour " + taskCode).hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }
}
