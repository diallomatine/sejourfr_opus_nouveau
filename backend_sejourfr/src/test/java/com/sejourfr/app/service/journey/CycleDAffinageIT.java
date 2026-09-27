package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyLockReason;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.ProductionBilanService;
import org.hibernate.LazyInitializationException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.service.AttemptService;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>Le premier cycle, issu du diagnostic rapide, sert a AFFINER la mesure</b>
 * (decision du proprietaire, 2026-09-27, D-64).
 *
 * <p>Ce qui est verrouille ici, contre la regle ordinaire (D-15) :
 * <ul>
 *   <li>l'examen blanc EE n'est pas verrouille par ses competences restantes,
 *       et il est l'action PRINCIPALE ({@code current}) ;</li>
 *   <li>le verrou d'ACCES (freemium) est inchange ;</li>
 *   <li>examens passes ⇒ le cycle est termine, actualisable, et le cycle
 *       suivant porte les priorites que les examens ont detectees ;</li>
 *   <li>au 2e cycle, rien ne change : competences puis examen.</li>
 * </ul>
 *
 * <p>🛑 <b>Non transactionnel</b>, comme tous les tests du parcours :
 * {@code JourneyService} ecrit en {@code REQUIRES_NEW} et ne verrait rien d'une
 * transaction de test (cf. {@code JourneyServiceIT}). Le referentiel seede est
 * emprunte, jamais cree.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class CycleDAffinageIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyCycleService cycleService;
    @Autowired private AttemptService attemptService;
    @Autowired private AttemptQuestionManager attemptQuestionManager;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyStepRepository journeySteps;
    @Autowired private PlatformTransactionManager txManager;
    @Autowired private JourneyProductionBridge productionBridge;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private ProductionBilanService bilanService;
    @Autowired private JourneyManager journeyManager;
    @Autowired private org.springframework.jdbc.core.JdbcTemplate jdbc;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(accountDeletionService::deleteAccount);
        candidats.clear();
    }

    @Test
    @DisplayName("1er cycle — l'examen EE est OUVERT malgre les competences restantes, et c'est "
            + "l'action principale")
    void premierCycleExamenEeOuvertEtPrincipal() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(vue.cycle().numero()).isEqualTo(1);
        assertThat(vue.cycle().cycleDAffinage()).isTrue();
        // D-68 : aucun jalon d'examen complet sur un premier cycle sans examen.
        assertThat(vue.examenComplet()).isNull();
        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        // Les priorites du diagnostic restent SERVIES, ouvertes, travaillables.
        assertThat(ee.steps()).hasSize(3)
                .allSatisfy(step -> assertThat(step.locked()).isFalse());
        // 🛑 Le coeur de la regle : aucun verrou PROGRESSION.
        assertThat(ee.exam()).isNotNull();
        assertThat(ee.exam().locked()).isFalse();
        assertThat(ee.exam().lockReason()).isNull();
        // L'examen blanc est l'action principale : la carte le nomme, le badge
        // le suit (le bloc EE est le premier servi, il porte le travail).
        assertThat(vue.current()).isNotNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(vue.current().bloc().code()).isEqualTo(EpreuveType.TCF_EE.name());
        assertThat(ee.status()).isEqualTo(JourneyBlocStatus.EN_COURS);
        assertThat(ee.meta()).isEqualTo("Examen à passer · 3 compétences facultatives");
        // Les competences facultatives ne comptent pas au denominateur tant
        // qu'elles ne sont pas faites.
        assertThat(vue.cycle().etapesTotal())
                .isEqualTo(etapes(user).stream()
                        .filter(step -> step.getType() != JourneyStepType.TRAIN_SKILL)
                        .count());
        assertThat(vue.state()).isEqualTo(JourneyState.IN_PROGRESS);
        assertThat(vue.nextStep()).isNull();
    }

    @Test
    @DisplayName("1er cycle, compte GRATUIT — le verrou d'ACCES est inchange : competences "
            + "fermees, examen EE ferme par la gratuite consommee, la carte passe a la CO")
    void premierCycleVerrouDAccesInchange() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);

        JourneyDto avant = journeyService.lire(user.getId(), Module.TCF);
        assertThat(avant.cycle().cycleDAffinage()).isTrue();
        // D-18 intact : travailler une competence depuis le Plan est premium.
        assertThat(blocDe(avant, EpreuveType.TCF_EE).steps())
                .allSatisfy(step -> assertThat(step.lockReason())
                        .isEqualTo(JourneyLockReason.ACCESS));
        // La gratuite d'examen EE n'est pas consommee : l'examen est ouvert.
        assertThat(blocDe(avant, EpreuveType.TCF_EE).exam().lockReason()).isNull();
        assertThat(avant.current().bloc().code()).isEqualTo(EpreuveType.TCF_EE.name());

        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);
        JourneyDto apres = journeyService.lire(user.getId(), Module.TCF);

        // 🛑 ACCESS, jamais PROGRESSION : le verrou pedagogique n'existe pas ici.
        assertThat(blocDe(apres, EpreuveType.TCF_EE).exam().lockReason())
                .isEqualTo(JourneyLockReason.ACCESS);
        // La carte saute l'examen ferme et nomme le premier examen executable.
        assertThat(apres.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(apres.current().bloc().code()).isEqualTo(EpreuveType.TCF_CO.name());
        assertThat(blocDe(apres, EpreuveType.TCF_CO).status())
                .isEqualTo(JourneyBlocStatus.EN_COURS);
        assertThat(apres.state()).isEqualTo(JourneyState.IN_PROGRESS);
    }

    @Test
    @DisplayName("2e cycle — regle inchangee : l'examen EE reste verrouille (PROGRESSION), et "
            + "un examen passe ne valide rien")
    void deuxiemeCycleVerrouilleCommeAvant() {
        User user = abonne();
        // Un cycle deja historise : celui qu'on ouvre est le 2e.
        data.journey(user, Module.TCF, JourneyStatus.HISTORISE);
        // ⚠️ D-69 (2026-09-28) : plus de lecture AVANT le diagnostic. Elle
        // ouvrirait un cycle d'examens de rang 2, qu'un diagnostic n'amorce
        // pas (seul le cycle d'examens PAR DEFAUT, rang 1, lui cede) — ses
        // priorites partiraient au cycle en attente. Le 2e cycle naît ici de
        // l'historique, diagnostic compris : c'est l'amorce ordinaire.
        diagnosticRapide(user);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);
        assertThat(vue.cycle().numero()).isEqualTo(2);
        assertThat(vue.cycle().cycleDAffinage()).isFalse();
        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        assertThat(ee.exam().lockReason()).isEqualTo(JourneyLockReason.PROGRESSION);
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.TRAIN_SKILL);
        assertThat(ee.meta()).isEqualTo("3 compétences restantes · puis examen");

        examenEePasse(user, competenceEE(0));

        // D-15 : les competences restent dues, l'examen du bloc reste ouvert.
        assertThat(etapes(user)).filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.getExamType() == EpreuveType.TCF_EE)
                .singleElement()
                .satisfies(step -> assertThat(step.estOuverte()).isTrue());
        // Et la competence encore due n'est pas remise en attente.
        assertThat(competencesEnAttente(user)).doesNotContain(competenceEE(0).getCode());
        assertThatThrownBy(() -> cycleService.actualiser(user.getId(), Module.TCF))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("1er cycle — les QUATRE examens passes, competences non faites : cycle termine, "
            + "actualisation offerte et acceptee, le 2e cycle porte les priorites des examens")
    void premierCycleExamensFaitsActualisable() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);
        Journey premier = cycleEnCours(user);

        examenEePasse(user, competenceEE(0));
        // EE : l'examen est clos, ses competences restent ouvertes (facultatives).
        JourneyDto apresEe = journeyService.lire(user.getId(), Module.TCF);
        JourneyBlocDto ee = blocDe(apresEe, EpreuveType.TCF_EE);
        assertThat(ee.exam().status().name()).isIn("COMPLETED", "SKIPPED");
        assertThat(ee.status()).isEqualTo(JourneyBlocStatus.TERMINE);
        assertThat(ee.meta()).isEqualTo("Examen blanc terminé · 3 compétences facultatives");
        // 🛑 La competence du diagnostic que l'examen a CONFIRMEE part au cycle
        // suivant, bien qu'elle soit encore ouverte ici.
        assertThat(competencesEnAttente(user)).contains(competenceEE(0).getCode());
        // La carte passe a l'examen suivant.
        assertThat(apresEe.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(apresEe.current().bloc().code()).isNotEqualTo(EpreuveType.TCF_EE.name());
        assertThat(apresEe.nextStep()).isNull();

        examenProductionPasse(user, EpreuveType.TCF_EO);
        examenQcmPasse(user, QuestionType.CO);
        examenQcmPasse(user, QuestionType.CE);

        JourneyDto termine = journeyService.lire(user.getId(), Module.TCF);
        assertThat(etapes(user)).filteredOn(JourneyStep::estOuverte)
                .isNotEmpty()
                .allSatisfy(step -> assertThat(step.getType()).isEqualTo(JourneyStepType.TRAIN_SKILL));
        assertThat(termine.cycle().complete()).isTrue();
        assertThat(termine.cycle().etapesTerminees()).isEqualTo(termine.cycle().etapesTotal());
        assertThat(termine.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        // La seule issue : l'actualisation. Pas d'examen complet enchaine.
        assertThat(termine.nextStep()).isNotNull();
        assertThat(termine.nextStep().actualisationPossible()).isTrue();
        // D-68 : l'objectif (B2) n'est pas atteint partout — pas de jalon, et le
        // geste est refuse par la meme autorite.
        assertThat(termine.examenComplet()).isNull();
        assertThatThrownBy(() -> cycleService.creerCycleDeMesure(user.getId(), Module.TCF))
                .isInstanceOf(IllegalStateException.class);

        JourneyDto second = cycleService.actualiser(user.getId(), Module.TCF);

        assertThat(journeys.findById(premier.getId()).orElseThrow().getStatus())
                .isEqualTo(JourneyStatus.HISTORISE);
        assertThat(second.cycle().numero()).isEqualTo(2);
        assertThat(second.cycle().cycleDAffinage()).isFalse();
        assertThat(blocDe(second, EpreuveType.TCF_EE).steps())
                .extracting(step -> step.skillCode())
                .contains(competenceEE(0).getCode());
        // Au 2e cycle, la regle ordinaire reprend.
        assertThat(blocDe(second, EpreuveType.TCF_EE).exam().lockReason())
                .isEqualTo(JourneyLockReason.PROGRESSION);
    }

    @Test
    @DisplayName("D-65 — 1er cycle : une competence close MASTERED sans ses series est rouverte, "
            + "reste FACULTATIVE, et les quatre examens closent toujours le cycle")
    void premierCycleCompetenceRouverteResteFacultative() {
        User user = abonne();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);
        JourneyStep maitrisee = etapes(user).stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getSkill().getId().equals(competenceEE(1).getId()))
                .findFirst().orElseThrow();
        jdbc.update("UPDATE journey_step SET closed_at = now(), resolution = 'MASTERED' "
                + "WHERE id = ?", maitrisee.getId());

        examenEePasse(user, competenceEE(0));
        examenProductionPasse(user, EpreuveType.TCF_EO);
        examenQcmPasse(user, QuestionType.CO);
        examenQcmPasse(user, QuestionType.CE);

        JourneyDto termine = journeyService.lire(user.getId(), Module.TCF);
        JourneyStep relue = journeySteps.findById(maitrisee.getId()).orElseThrow();
        assertThat(relue.estOuverte()).as("rouverte : elle n'avait pas ses series").isTrue();
        assertThat(relue.getResolution()).isNull();
        // Facultatif n'est pas ferme, et ouvert n'est pas obligatoire (D-64).
        assertThat(termine.cycle().cycleDAffinage()).isTrue();
        assertThat(termine.cycle().complete()).isTrue();
        assertThat(termine.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(termine.nextStep().actualisationPossible()).isTrue();
    }

    // =====================================================================
    // Bug du 2026-09-27 : l'examen blanc EE gratuit passe restait « à acheter »
    // =====================================================================

    @Test
    @DisplayName("Examen EE gratuit passe, signal PERDU : la lecture clot l'etape (FAIT, jamais "
            + "ACCESS), rejoue le signal, et la carte passe a l'examen suivant")
    void examenEeGratuitPasseSignalPerduRattrapeALaLecture() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);
        // L'examen offert est passe ET corrige : la gratuite est consommee…
        Attempt examen = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE, examen);
        data.learningPlanObservation(user, competenceEE(0),
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, Instant.now(), examen.getId());
        // … mais le parcours n'a jamais recu le signal (cas mesure en base).
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, examen.getId())).isFalse();

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        JourneyBlocDto ee = blocDe(vue, EpreuveType.TCF_EE);
        assertThat(ee.exam().status()).isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
        // 🛑 Un examen deja passe ne s'affiche jamais verrouille / a acheter.
        assertThat(ee.exam().locked()).isFalse();
        assertThat(ee.exam().lockReason()).isNull();
        assertThat(vue.current().type()).isEqualTo(JourneyStepType.SECTION_EXAM);
        assertThat(vue.current().bloc().code()).isNotEqualTo(EpreuveType.TCF_EE.name());
        // Le signal manque est rejoue apres le commit de la lecture : journal
        // ecrit, et la priorite confirmee attend le cycle suivant.
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, examen.getId())).isTrue();
        assertThat(competencesEnAttente(user)).contains(competenceEE(0).getCode());
    }

    @Test
    @DisplayName("Le cas mesure (2026-09-27) : CO, CE, EO signales, EE passe mais JAMAIS signale "
            + "— la lecture clot EE, le cycle est termine et l'actualisation offerte")
    void lesQuatreExamensFaitsDontEeNonSignaleTerminentLeCycle() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);
        examenQcmPasse(user, QuestionType.CO);
        examenQcmPasse(user, QuestionType.CE);
        examenProductionPasse(user, EpreuveType.TCF_EO);
        Attempt ee = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE, ee);
        // Etat en base du compte : les trois autres etapes closes, EE ouverte.
        assertThat(etapes(user)).filteredOn(step -> step.getType() == JourneyStepType.SECTION_EXAM
                        && step.estOuverte())
                .extracting(JourneyStep::getExamType)
                .containsExactly(EpreuveType.TCF_EE);

        JourneyDto vue = journeyService.lire(user.getId(), Module.TCF);

        assertThat(blocDe(vue, EpreuveType.TCF_EE).exam().lockReason()).isNull();
        assertThat(vue.cycle().complete()).isTrue();
        assertThat(vue.state()).isEqualTo(JourneyState.CYCLE_COMPLETED);
        assertThat(vue.nextStep()).isNotNull();
        assertThat(vue.nextStep().actualisationPossible()).isTrue();
        assertThat(cycleService.actualiser(user.getId(), Module.TCF).cycle().numero()).isEqualTo(2);
    }

    @Test
    @DisplayName("Examen EE soumis, corrections EN COURS : l'etape se clot des la fin, sans "
            + "journal ; l'evaluation complete arrive ensuite et porte ses priorites")
    void examenEeSoumisPuisCorrige() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);
        diagnosticRapide(user);
        Attempt examen = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        var derniere = submissionManager.findByAttemptId(examen.getId()).getLast();
        derniere.setStatut(SubmissionStatut.EVALUATING);
        submissionManager.save(derniere);

        productionBridge.onProductionAttemptClosed(examen);

        JourneyDto pendant = journeyService.lire(user.getId(), Module.TCF);
        assertThat(blocDe(pendant, EpreuveType.TCF_EE).exam().status())
                .isIn(JourneyStepStatus.COMPLETED, JourneyStepStatus.SKIPPED);
        assertThat(blocDe(pendant, EpreuveType.TCF_EE).exam().lockReason()).isNull();
        // 🛑 Rien n'est journalise tant que la correction tourne (B-13) : ni
        // par la fin d'examen, ni par le filet de lecture.
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, examen.getId())).isFalse();

        derniere.setStatut(SubmissionStatut.EVALUATED);
        submissionManager.save(derniere);
        data.learningPlanObservation(user, competenceEE(0),
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, null, Instant.now(), examen.getId());
        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                examen.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE,
                examen.getFinishedAt()));

        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, examen.getId())).isTrue();
        assertThat(competencesEnAttente(user)).contains(competenceEE(0).getCode());
    }

    @Test
    @DisplayName("Cause racine : les taches d'une epreuve se lisent HORS session (runner async)")
    void lesTachesDUneEpreuveSeLisentHorsSession() {
        User user = candidat();
        Attempt examen = data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B1);

        // L'ancienne lecture de la voie de l'analyse : taches LAZY, levait hors
        // session — l'exception etait avalee et le parcours jamais prevenu.
        assertThatThrownBy(() -> bilanService.latestEvalsByTache(
                submissionManager.findByAttemptId(examen.getId())))
                .isInstanceOf(LazyInitializationException.class);
        // La lecture corrigee : taches chargees avec leurs soumissions.
        assertThat(bilanService.latestEvalsByTache(
                submissionManager.findByAttemptIdsGrouped(List.of(examen.getId()))
                        .getOrDefault(examen.getId(), List.of())))
                .hasSize(3);
    }

    // ------------------------------------------------------------------ outils

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

    private ExamensDuParcours examens() {
        return new ExamensDuParcours(data, journeyService, attemptService,
                attemptQuestionManager, txManager, skillManager);
    }

    private void diagnosticRapide(User user) {
        examens().diagnosticRapide(user);
        assertThat(etapes(user)).filteredOn(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .as("le lot EE du diagnostic").hasSize(3);
    }

    private void examenEePasse(User user, Skill redetectee) {
        examens().examenEePasse(user, redetectee);
    }

    private void examenProductionPasse(User user, EpreuveType epreuve) {
        examens().examenProductionPasse(user, epreuve);
    }

    private void examenQcmPasse(User user, QuestionType epreuve) {
        examens().examenQcmPasse(user, epreuve);
    }

    private Skill competenceEE(int rang) {
        return examens().competenceEE(rang);
    }

    private Journey cycleEnCours(User user) {
        return journeys.findByUserIdAndModuleAndStatus(
                user.getId(), Module.TCF, JourneyStatus.EN_COURS).orElseThrow();
    }

    private List<JourneyStep> etapes(User user) {
        return journeySteps.findAllByJourney(cycleEnCours(user).getId());
    }

    /** Le cycle EN ATTENTE est invisible du candidat : on le lit en base. */
    private List<String> competencesEnAttente(User user) {
        return journeys.findByUserIdAndModuleAndStatus(
                        user.getId(), Module.TCF, JourneyStatus.EN_ATTENTE)
                .map(attente -> journeySteps.findAllByJourney(attente.getId()).stream()
                        .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                        .map(step -> step.getSkill().getCode())
                        .toList())
                .orElse(List.of());
    }

    private static JourneyBlocDto blocDe(JourneyDto vue, EpreuveType epreuve) {
        return vue.blocs().stream()
                .filter(bloc -> epreuve.name().equals(bloc.bloc().code()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aucun bloc " + epreuve));
    }
}
