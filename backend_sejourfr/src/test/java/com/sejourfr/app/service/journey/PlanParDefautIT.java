package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.PreparationDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyLockReason;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PreparationEtape;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.LearningPlanService;
import com.sejourfr.app.service.PreparationService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le Plan PAR DEFAUT</b> (decision du proprietaire, 2026-09-28, D-69) : tout
 * compte a un Plan, diagnostic fait ou non.
 *
 * <ul>
 *   <li>sans aucune evaluation : un <b>cycle d'examens</b> — un bloc par
 *       epreuve (TCF) ou par thematique (civique), chacun son examen ;</li>
 *   <li>cree <b>paresseusement</b> a la premiere lecture, <b>une seule fois</b>
 *       meme sous lectures concurrentes ;</li>
 *   <li>l'ancienne attente du diagnostic est convertie a la lecture ;</li>
 *   <li>le diagnostic rapide, arrive sur ce cycle intact, en fait le cycle
 *       d'AFFINAGE (D-64 tenu) ;</li>
 *   <li>des examens deja passes : le premier cycle est directement un cycle
 *       de travail sur leurs priorites (amorce R19) ;</li>
 *   <li>les examens passes, « Actualiser mon plan » ouvre un cycle de travail,
 *       et le cycle d'examens ne compte pas pour le jalon D-68.</li>
 * </ul>
 *
 * <p>🛑 <b>Non transactionnel</b>, comme tous les tests du parcours :
 * {@code JourneyService} ecrit en {@code REQUIRES_NEW}.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class PlanParDefautIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyCycleService cycleService;
    @Autowired private PreparationService preparationService;
    @Autowired private LearningPlanService planService;
    @Autowired private CivicPlanService civicPlanService;
    @Autowired private AttemptService attemptService;
    @Autowired private AttemptQuestionManager attemptQuestionManager;
    @Autowired private PlatformTransactionManager txManager;
    @Autowired private SkillManager skillManager;
    @Autowired private ThemeManager themeManager;
    @Autowired private TestData data;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository journeySteps;
    @Autowired private org.springframework.jdbc.core.JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    @Test
    @DisplayName("Compte neuf sans diagnostic : le Plan TCF est un cycle d'examens de 4 blocs, "
            + "le Plan est ACTIF et disponible")
    void compteNeufPlanTcfEstUnCycleDExamens() {
        User user = candidat();

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.cycle().numero()).isEqualTo(1);
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.cycle().cycleDAffinage()).isFalse();
        assertThat(vue.blocs()).hasSize(4).allSatisfy(bloc -> {
            assertThat(bloc.steps()).isEmpty();
            assertThat(bloc.exam()).isNotNull();
            // Freemium inchange : gratuites d'examen non consommees, rien de ferme.
            assertThat(bloc.exam().lockReason()).isNull();
        });
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(vue.state()).isEqualTo(JourneyState.IN_PROGRESS);
        assertThat(vue.examenComplet()).isNull();
        assertThat(etapes(user)).extracting(JourneyStep::getType)
                .containsOnly(JourneyStepType.SECTION_EXAM);

        PreparationDto prep = preparationService.lire(user.getId());
        assertThat(prep.tcf().planDisponible()).isTrue();
        // Le diagnostic reste PROPOSE (secondaire), l'etape servie le dit.
        assertThat(prep.tcf().etape()).isEqualTo(PreparationEtape.DIAGNOSTIC_A_FAIRE);
        assertThat(planService.get(user.getId()).state()).isEqualTo(LearningPlanState.ACTIVE);
    }

    @Test
    @DisplayName("Compte neuf sans diagnostic civique : un bloc par thematique, chacun son examen ; "
            + "le Plan civique est disponible sans plan derive")
    void compteNeufPlanCiviqueEstUnCycleDExamens() {
        User user = candidat();
        int thematiques = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).size();
        assertThat(thematiques).as("referentiel civique seede").isPositive();

        JourneyDto vue = journeyService.lire(user.getId(), Module.CIVIQUE);

        assertThat(vue.blocs()).hasSize(thematiques).allSatisfy(bloc -> {
            assertThat(bloc.steps()).isEmpty();
            assertThat(bloc.exam()).isNotNull();
        });
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(journeySteps.findAllByJourney(cycleEnCours(user, Module.CIVIQUE).getId()))
                .allSatisfy(step -> {
                    assertThat(step.getType()).isEqualTo(JourneyStepType.SECTION_EXAM);
                    assertThat(step.getPurpose()).isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
                });
        // Le plan DERIVE attend son diagnostic ; le Plan, lui, existe.
        assertThat(civicPlanService.plan(user.getId()).disponible()).isFalse();
        assertThat(preparationService.lire(user.getId()).civique().planDisponible()).isTrue();
    }

    /**
     * 🛑 <b>L'etape d'examen d'un theme SERT son action</b> (2026-09-28) : elle
     * arrivait sans rien a lancer, et les deux fronts la rendaient sans bouton
     * « Commencer » — un cul-de-sac sur le premier cycle d'examens. Le theme
     * servi est celui du bloc, le creneau est l'offert (jamais le paywall), et
     * il demarre bien l'examen de theme pour un compte GRATUIT. Le TCF garde
     * son {@code assessment}, sans examen de theme.
     */
    @Test
    @DisplayName("Cycle d'examens civique : chaque etape d'examen sert son examen de theme, "
            + "lancable par un compte gratuit ; le TCF n'en sert aucun")
    void lEtapeDExamenCiviqueServeSonExamenDeTheme() {
        User user = candidat();

        JourneyDto civique = journeyService.lire(user.getId(), Module.CIVIQUE);

        assertThat(civique.blocs()).isNotEmpty().allSatisfy(bloc -> {
            var cible = bloc.exam().examenTheme();
            assertThat(cible).as("examen de theme servi pour %s", bloc.bloc().code()).isNotNull();
            assertThat(cible.slotNumber())
                    .isEqualTo(com.sejourfr.app.service.examenblanc.ExamenBlancAccessService.CRENEAU_OFFERT);
            assertThat(themeManager.findById(cible.themeId()))
                    .get().extracting(com.sejourfr.app.entity.Theme::getCode)
                    .isEqualTo(bloc.bloc().code());
            assertThat(bloc.exam().assessment()).isNull();
            assertThat(bloc.exam().locked()).isFalse();
        });
        assertThat(civique.current().examenTheme()).isNotNull();

        var cible = civique.blocs().getFirst().exam().examenTheme();
        var lance = attemptService.start(user.getId(), new com.sejourfr.app.dto.StartAttemptRequest(
                com.sejourfr.app.enums.AttemptType.MOCK_EXAM, Module.CIVIQUE, null, cible.themeId(),
                null, null, null, null, null, cible.slotNumber(), null));
        assertThat(lance.themeId()).isEqualTo(cible.themeId());

        JourneyDto tcf = journeyService.lire(user.getId(), Module.TCF);
        assertThat(tcf.blocs()).allSatisfy(bloc -> {
            assertThat(bloc.exam().examenTheme()).isNull();
            assertThat(bloc.exam().assessment()).isNotNull();
        });
    }

    @Test
    @DisplayName("Compte existant sans parcours : cree a la premiere lecture, UNE fois, meme sous "
            + "quatre lectures concurrentes — et les lectures suivantes ne recreent rien")
    void creationParesseuseIdempotenteSousConcurrence() throws Exception {
        User user = candidat();
        CountDownLatch depart = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            List<Future<JourneyDto>> lectures = new ArrayList<>();
            for (int i = 0; i < 4; i++) {
                Callable<JourneyDto> lecture = () -> {
                    depart.await();
                    return journeyService.lire(user.getId(), Module.TCF);
                };
                lectures.add(pool.submit(lecture));
            }
            depart.countDown();
            for (Future<JourneyDto> lecture : lectures) {
                // Aucune lecture n'echoue sur `uq_journey_en_cours`.
                assertThat(lecture.get(30, TimeUnit.SECONDS).cycle().cycleDeMesure()).isTrue();
            }
        } finally {
            pool.shutdownNow();
        }

        assertThat(journeys.findAll()).filteredOn(j -> j.getUser().getId().equals(user.getId()))
                .singleElement()
                .satisfies(j -> assertThat(j.getStatus()).isEqualTo(JourneyStatus.EN_COURS));
        assertThat(etapes(user)).hasSize(4);

        journeyService.lire(user.getId(), Module.TCF);
        assertThat(etapes(user)).hasSize(4);
    }

    @Test
    @DisplayName("Compte AVEC diagnostic : le diagnostic arrive sur le cycle d'examens intact et en "
            + "fait le cycle d'AFFINAGE (D-64), sans second examen EE")
    void diagnosticSurLeCycleParDefautDonneLAffinage() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);

        examens().diagnosticRapide(user);
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.cycle().cycleDAffinage()).isTrue();
        assertThat(vue.cycle().cycleDeMesure()).isFalse();
        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        assertThat(ee.steps()).hasSize(3);
        assertThat(ee.exam().lockReason()).isNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        // R3 satisfaite par l'examen deja pose : un seul examen EE ouvert.
        assertThat(etapes(user)).filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.getExamType() == EpreuveType.TCF_EE && step.estOuverte())
                .hasSize(1);
        // Les priorites du diagnostic sont dans CE cycle, pas en attente.
        assertThat(journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE)).isEmpty();
    }

    @Test
    @DisplayName("Diagnostic APRES un examen du cycle d'examens : le cycle a commence, ses "
            + "priorites vont au cycle suivant (D-13), le cycle reste un cycle d'examens")
    void diagnosticApresUnExamenVaAuCycleSuivant() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);
        examens().examenQcmPasse(user, QuestionType.CO);

        examens().diagnosticRapide(user);
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.cycle().cycleDAffinage()).isFalse();
        assertThat(etapes(user)).noneMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
        assertThat(blocDe(vue, EpreuveType.TCF_CO).exam().status().name())
                .isIn("COMPLETED", "SKIPPED");
        assertThat(competencesEnAttente(user)).hasSize(3);
    }

    @Test
    @DisplayName("Bug prod 2026-09-28 — compte SANS parcours, 4 epreuves deja mesurees (aucune "
            + "priorite) : le premier cycle est le cycle d'examens de 4 blocs, jamais un cycle vide")
    void quatreEpreuvesDejaMesureesDonnentLeCycleDExamens() {
        User user = abonne();
        // Sans demarche, aucun parcours ne se cree pendant que l'historique se
        // pose (D-3) : les examens QCM passent par le VRAI `finish` (banque
        // seedee), qui previent le parcours apres son commit.
        user.setTargetProcedure(null);
        user.setTargetLevel(null);
        user = data.saveUser(user);
        Attempt ee = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EO, NiveauCecrl.B1);
        examens().examenQcmPasse(user, QuestionType.CO);
        examens().examenQcmPasse(user, QuestionType.CE);
        assertThat(journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS)).isEmpty();
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        user = data.saveUser(user);
        // Une evaluation SOLIDE : elle amorcait l'ancien bootstrap, sans aucun lot.
        data.learningPlanObservation(user, examens().competenceEE(0),
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.SOLID,
                ObservationConfidence.HIGH, null, Instant.now().minusSeconds(600), ee.getId());

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.state()).isNotEqualTo(JourneyState.UP_TO_DATE);
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(vue.blocs()).hasSize(4).allSatisfy(bloc -> {
            assertThat(bloc.steps()).isEmpty();
            assertThat(bloc.exam()).isNotNull();
            assertThat(bloc.exam().lockReason()).isNull();
            assertThat(bloc.exam().status().name()).isIn("CURRENT", "UPCOMING");
        });
        // 🛑 Un examen ANTERIEUR au cycle ne ferme rien (D-69 ter) : quatre
        // etapes ouvertes, une seule nature — meme apres une seconde lecture,
        // qui passe les filets.
        journeyService.lire(user.getId(), Module.TCF);
        assertThat(etapes(user)).hasSize(4).allSatisfy(step -> {
            assertThat(step.getPurpose()).isEqualTo(JourneyStepPurpose.INITIAL_ASSESSMENT);
            assertThat(step.estOuverte()).isTrue();
        });
    }

    @Test
    @DisplayName("Lancement D-69 ter : tout cycle EN COURS marque est historise INTERROMPU et "
            + "remplace par un cycle d'examens neuf, UNE fois ; archives intactes, attente videe")
    void lancementReinitialiseUneSeuleFois() {
        User user = abonne();
        Journey archive = data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        Instant archivageAvant = journeys.findById(archive.getId()).orElseThrow().getHistoriseAt();
        // Un cycle de TRAVAIL vivant au deploiement : un lot EE, amorce par un examen.
        Journey travail = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        examens().examenEePasse(user, examens().competenceEE(0));
        assertThat(etapes(user)).anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
        // Et un cycle EN ATTENTE, porteur d'une priorite d'avant le lancement.
        examens().examenEePasse(user, examens().competenceEE(1));
        assertThat(competencesEnAttente(user)).isNotEmpty();
        Journey civique = journeyService.getOrCreate(user.getId(), Module.CIVIQUE).orElseThrow();
        // V082 : le marqueur pose par Flyway sur les cycles vivants.
        jdbc.update("UPDATE journey SET reinitialiser_au_lancement = true "
                + "WHERE user_id = ? AND status IN ('EN_COURS', 'EN_ATTENTE')", user.getId());

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        Journey ancien = journeys.findById(travail.getId()).orElseThrow();
        assertThat(ancien.getStatus()).isEqualTo(JourneyStatus.HISTORISE);
        assertThat(ancien.getFinDeCycle()).isEqualTo(JourneyFinDeCycle.INTERROMPU);
        Journey neuf = cycleEnCours(user, Module.TCF);
        assertThat(neuf.getId()).isNotEqualTo(travail.getId());
        assertThat(neuf.isReinitialiserAuLancement()).isFalse();
        assertThat(vue.cycle().cycleDeMesure()).isTrue();
        assertThat(etapes(user)).hasSize(4).allSatisfy(step -> {
            assertThat(step.getType()).isEqualTo(JourneyStepType.SECTION_EXAM);
            assertThat(step.estOuverte()).isTrue();
        });
        // L'attente d'avant le lancement est videe : les examens la recalculeront.
        assertThat(competencesEnAttente(user)).isEmpty();
        assertThat(journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE).orElseThrow()
                .isReinitialiserAuLancement()).isFalse();
        // Les cycles ARCHIVES ne bougent pas.
        Journey archiveRelue = journeys.findById(archive.getId()).orElseThrow();
        assertThat(archiveRelue.getHistoriseAt()).isEqualTo(archivageAvant);
        assertThat(archiveRelue.getFinDeCycle()).isNull();

        // Une seule fois : la lecture suivante ne touche plus rien.
        journeyService.lire(user.getId(), Module.TCF);
        assertThat(cycleEnCours(user, Module.TCF).getId()).isEqualTo(neuf.getId());
        assertThat(etapes(user)).hasSize(4);

        // Civique : meme regle, un examen par thematique.
        int thematiques = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).size();
        JourneyDto vueCivique = journeyService.lire(user.getId(), Module.CIVIQUE);
        assertThat(journeys.findById(civique.getId()).orElseThrow().getFinDeCycle())
                .isEqualTo(JourneyFinDeCycle.INTERROMPU);
        assertThat(vueCivique.blocs()).hasSize(thematiques)
                .allSatisfy(bloc -> assertThat(bloc.exam()).isNotNull());
    }

    @Test
    @DisplayName("V082 : le marquage ne vise que les cycles VIVANTS (en cours, en attente)")
    void leMarquageNeViseQueLesCyclesVivants() {
        User user = candidat();
        Journey enCours = data.journey(user, Module.TCF, JourneyStatus.EN_COURS);
        Journey attente = data.journey(user, Module.TCF, JourneyStatus.EN_ATTENTE);
        Journey archive = data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        String sql = sqlDuMarquage();

        // 🛑 Rejoue le SQL REEL de V082 dans une transaction ANNULEE : il marque
        // toute la base, et ce test ne doit rien laisser derriere lui.
        new org.springframework.transaction.support.TransactionTemplate(txManager)
                .executeWithoutResult(status -> {
                    jdbc.execute(sql);
                    assertThat(marque(enCours)).isTrue();
                    assertThat(marque(attente)).isTrue();
                    assertThat(marque(archive)).isFalse();
                    status.setRollbackOnly();
                });
        // Un cycle cree apres le lancement naît non marque.
        assertThat(marque(enCours)).isFalse();
    }

    @Test
    @DisplayName("Un examen passe PENDANT le cycle ferme son etape, qui s'affiche avec son resultat")
    void unExamenDuCycleFermeSonEtapeEtSertSonResultat() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);

        examens().examenEePasse(user, examens().competenceEE(0));
        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.exam().status().name()).isIn("COMPLETED", "SKIPPED");
        assertThat(ee.exam().resultat()).isNotNull();
        assertThat(vue.cycle().etapesTotal()).isEqualTo(4);
        assertThat(vue.cycle().etapesTerminees()).isEqualTo(1);
    }

    @Test
    @DisplayName("Les quatre examens du cycle d'examens passes : actualisation ⇒ cycle de TRAVAIL "
            + "sur leurs priorites ; le cycle d'examens ne compte pas pour le jalon D-68")
    void finDuCycleDExamensOuvreUnCycleDeTravail() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);

        examens().examenEePasse(user, examens().competenceEE(0));
        examens().examenProductionPasse(user, EpreuveType.TCF_EO);
        examens().examenQcmPasse(user, QuestionType.CO);
        examens().examenQcmPasse(user, QuestionType.CE);

        JourneyDto termine = journeyService.lire(user.getId(), Module.TCF);
        assertThat(termine.cycle().complete()).isTrue();
        assertThat(termine.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(termine.nextStep()).isNotNull();
        assertThat(termine.nextStep().actualisationPossible()).isTrue();
        assertThat(termine.examenComplet()).isNull();
        assertThat(termine.cycle().prioritesCycleSuivant()).isPositive();

        JourneyDto second = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(second.cycle().numero()).isEqualTo(2);
        assertThat(second.cycle().cycleDeMesure()).isFalse();
        assertThat(second.cycle().cycleDAffinage()).isFalse();
        assertThat(blocDe(second, EpreuveType.TCF_EE).steps())
                .extracting(step -> step.skillCode())
                .contains(examens().competenceEE(0).getCode());
        assertThat(blocDe(second, EpreuveType.TCF_EE).exam().lockReason())
                .isEqualTo(JourneyLockReason.PROGRESSION);
        // D-67 : au plus trois priorites par epreuve.
        assertThat(second.blocs()).allSatisfy(bloc -> assertThat(bloc.steps()).hasSizeLessThanOrEqualTo(3));
        // D-68 : zero cycle de TRAVAIL termine — le cycle d'examens n'en est pas un.
        assertThat(second.examenComplet()).isNull();
    }

    // ------------------------------------------------------------------ outils

    private ExamensDuParcours examens() {
        return new ExamensDuParcours(data, journeyService, attemptService,
                attemptQuestionManager, txManager, skillManager);
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

    private Journey cycleEnCours(User user, Module module) {
        return journeys.findByUserIdAndModuleAndStatus(
                user.getId(), module, JourneyStatus.EN_COURS).orElseThrow();
    }

    private List<JourneyStep> etapes(User user) {
        return journeySteps.findAllByJourney(cycleEnCours(user, Module.TCF).getId());
    }

    private List<String> competencesEnAttente(User user) {
        return journeys.findByUserIdAndModuleAndStatus(
                        user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE)
                .map(attente -> journeySteps.findAllByJourney(attente.getId()).stream()
                        .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                        .filter(JourneyStep::estOuverte)
                        .map(step -> step.getSkill().getCode())
                        .toList())
                .orElse(List.of());
    }

    private boolean marque(Journey journey) {
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT reinitialiser_au_lancement FROM journey WHERE id = ?",
                Boolean.class, journey.getId()));
    }

    private static String sqlDuMarquage() {
        String sentinelle = "-- @@MARQUAGE_DU_LANCEMENT@@";
        var resource = new org.springframework.core.io.ClassPathResource(
                "db/migration/00_schema/V082__journey_reinitialisation_lancement.sql");
        try (var in = resource.getInputStream()) {
            String migration = new String(in.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
            int coupe = migration.indexOf(sentinelle);
            assertThat(coupe).as("sentinelle de V082").isPositive();
            return migration.substring(coupe + sentinelle.length());
        } catch (java.io.IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
    }

    private static JourneyBlocDto blocDe(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }
}
