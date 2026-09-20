package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyLotRepository;
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

/**
 * <b>La jointure entre une evaluation et ses observations</b> — le defaut que
 * {@link JourneyObservationSources} existe pour fermer.
 *
 * <h2>Ce qui etait casse, et pourquoi ca ne se voyait pas</h2>
 * <p>Le parcours retenait les observations d'une evaluation par <b>egalite
 * brute</b> : {@code evaluation.sourceAssessmentId().equals(observation
 * .getSourceId())}. Or cote <b>production</b> les deux viennent de tables
 * differentes — l'evaluation est un {@code attempts.id} (ou un
 * {@code diagnostic_sessions.id}), l'observation un
 * {@code production_submissions.id}. L'egalite ne matchait donc
 * <b>jamais</b> : un diagnostic rapide termine avec quatre fragilites EE ne
 * creait <b>aucun lot</b>, et l'ecran affichait « Aucune competence a
 * travailler » pendant que la carte « A faire maintenant » annoncait
 * « Expression ecrite ».
 *
 * <p>🛑 <b>Le defaut ne se voyait que sur le chemin LIVE</b>, donc sur les
 * comptes neufs : le <b>bootstrap R19</b>, lui, se cale sur
 * {@code observation.getSourceId()} et fabriquait bien les lots. C'est pourquoi
 * chaque test ci-dessous <b>ouvre d'abord le parcours</b> — le candidat consulte
 * son Plan —, et <b>ensuite seulement</b> passe son evaluation.
 *
 * <h2>🛑 Pourquoi ces tests ne sont PAS transactionnels (A14)</h2>
 * <p>{@code JourneyService} ecrit en {@link Propagation#REQUIRES_NEW}. Une
 * transaction de test qui l'enveloppe la <b>suspend</b> : le service ne voit
 * rien, sort en silence, et les assertions passent pour de mauvaises raisons.
 * Le menage se fait donc a la main. Aucune competence ni aucun petit sujet n'est
 * cree ici : le referentiel seede est <b>emprunte</b>.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class JourneyObservationSourcesIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyManager journeyManager;
    @Autowired private TestData data;
    @Autowired private SkillManager skillManager;
    @Autowired private AccountDeletionService accountDeletionService;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;

    private final List<UUID> candidats = new ArrayList<>();

    @AfterEach
    void menage() {
        candidats.forEach(id -> accountDeletionService.deleteAccount(id));
        candidats.clear();
    }

    // =====================================================================
    // 1 — le scenario mesure : diagnostic rapide ⇒ lot EE
    // =====================================================================

    @Test
    @DisplayName("Diagnostic rapide termine : les fragilites EE ouvrent un lot TCF_EE")
    void leDiagnosticRapideOuvreUnLotEE() {
        User user = candidat();
        // Le candidat ouvre son Plan AVANT de passer le diagnostic : le
        // bootstrap n'a rien a amorcer, tout viendra du chemin live.
        journeyService.lire(user.getId(), Module.TCF);

        DiagnosticSession session = diagnosticTermine(user);
        ProductionSubmission ecrit = soumissionEcriteDe(session, user);
        // 🛑 Les observations sont clavetees sur la SOUMISSION, jamais sur la
        // session : c'est ce que fait LearningPlanObservationService, et c'est
        // ce que la base montre (240 lignes sur une soumission, 0 sur une
        // session).
        observationDeDiagnostic(user, competenceEE(0), ecrit, LearningPlanSkillStatus.PRIORITY);
        observationDeDiagnostic(user, competenceEE(1), ecrit, LearningPlanSkillStatus.PRIORITY);
        observationDeDiagnostic(user, competenceEE(2), ecrit,
                LearningPlanSkillStatus.TO_REINFORCE);
        observationDeDiagnostic(user, competenceEE(3), ecrit,
                LearningPlanSkillStatus.TO_REINFORCE);

        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.diagnosticRapide(session.getId(), session.getCompletedAt()));

        JourneyLot lot = lotOuvert(user, EpreuveType.TCF_EE);
        assertThat(lot).as("le lot EE que le diagnostic devait ouvrir").isNotNull();
        // D-20 : au plus trois priorites par lot, les plus graves d'abord.
        assertThat(entrainementsDuLot(lot)).hasSize(3);
    }

    // =====================================================================
    // 2 — l'autre occurrence du meme defaut : l'examen de production LIVE
    // =====================================================================

    @Test
    @DisplayName("Examen EE live : les 3 taches evaluees ouvrent UN lot, pas trois")
    void lExamenDeProductionOuvreUnLot() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);

        Attempt epreuve = epreuveDeProduction(user, EpreuveType.TCF_EE);
        // Trois taches, donc trois soumissions — et c'est exactement pour cela
        // que l'identite reste l'ATTEMPT (A11).
        for (short numero = 1; numero <= 3; numero++) {
            ProductionSubmission tache = data.productionSubmission(
                    epreuve, data.productionTacheNumero(EpreuveType.TCF_EE, numero), user);
            observation(user, competenceEE(numero - 1), tache.getId(),
                    LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY);
        }

        journeyService.onAssessmentCompleted(user.getId(), new JourneyEvaluation(
                epreuve.getId(), JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE,
                epreuve.getFinishedAt()));

        JourneyLot lot = lotOuvert(user, EpreuveType.TCF_EE);
        assertThat(lot).as("le lot EE que l'examen devait ouvrir").isNotNull();
        assertThat(entrainementsDuLot(lot)).hasSize(3);
        // 🛑 UN seul lot : la tache 2 ne remplace pas celui de la tache 1 (R7).
        assertThat(lots.findByJourneyIdAndStatus(lot.getJourney().getId(), JourneyLotStatus.OPEN)
                .stream()
                .filter(ouvert -> ouvert.getExamType() == EpreuveType.TCF_EE))
                .hasSize(1);
    }

    // =====================================================================
    // 3 — le garde-fou A11 : l'identite reste l'attempt / la session
    // =====================================================================

    @Test
    @DisplayName("A11 — l'identite d'une evaluation reste l'attempt ou la session, "
            + "jamais la soumission")
    void lIdentiteResteLAttemptOuLaSession() {
        User user = candidat();
        journeyService.lire(user.getId(), Module.TCF);

        DiagnosticSession session = diagnosticTermine(user);
        ProductionSubmission ecrit = soumissionEcriteDe(session, user);
        observationDeDiagnostic(user, competenceEE(0), ecrit, LearningPlanSkillStatus.PRIORITY);

        journeyService.onAssessmentCompleted(user.getId(),
                JourneyEvaluation.diagnosticRapide(session.getId(), session.getCompletedAt()));

        JourneyLot lot = lotOuvert(user, EpreuveType.TCF_EE);
        assertThat(lot).isNotNull();
        // 🛑 Le lot et ses etapes portent la SESSION, pas la soumission :
        // repasser a l'id de soumission rouvrirait A11 mot pour mot.
        assertThat(lot.getSourceAssessmentId()).isEqualTo(session.getId());
        assertThat(entrainementsDuLot(lot))
                .allSatisfy(step -> assertThat(step.getSourceAssessmentId())
                        .isEqualTo(session.getId()));
        // 🛑 Et le JOURNAL parle la meme langue : c'est ce qui rend `dejaTraitee`
        // capable de reconnaitre l'evaluation que le chemin live lui passe.
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, session.getId()))
                .as("la session est journalisee").isTrue();
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, ecrit.getId()))
                .as("la soumission n'est JAMAIS une identite d'evaluation").isFalse();
    }

    // =====================================================================
    // 4 — le bootstrap R19 parle la meme langue que le chemin live
    // =====================================================================

    @Test
    @DisplayName("R19 — le bootstrap journalise l'IDENTITE d'evaluation, pas l'id "
            + "de la soumission")
    void leBootstrapJournaliseLIdentiteDEvaluation() {
        User user = candidat();
        // L'historique existe AVANT le parcours : c'est le cas du bootstrap.
        Attempt epreuve = epreuveDeProduction(user, EpreuveType.TCF_EE);
        ProductionSubmission tache = data.productionSubmission(
                epreuve, data.productionTacheNumero(EpreuveType.TCF_EE, (short) 1), user);
        observation(user, competenceEE(0), tache.getId(),
                LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY);

        journeyService.lire(user.getId(), Module.TCF);

        // 🛑 La colonne `source_assessment_id` ne porte qu'UN espace
        // d'identifiants. Sans cela, `getOrCreate` amorcait sous l'id de
        // soumission, `dejaTraitee` interrogeait l'id d'attempt — absent — et la
        // MEME evaluation etait traitee une seconde fois.
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, epreuve.getId()))
                .as("l'attempt est journalise par l'amorce").isTrue();
        assertThat(journeyManager.dejaTraitee(user.getId(), Module.TCF, tache.getId()))
                .as("la soumission n'entre jamais au journal").isFalse();

        JourneyLot lot = lotOuvert(user, EpreuveType.TCF_EE);
        assertThat(lot).as("le bootstrap ouvre bien le lot").isNotNull();
        assertThat(lot.getSourceAssessmentId()).isEqualTo(epreuve.getId());
    }

    // =====================================================================

    private User candidat() {
        User user = data.user();
        candidats.add(user.getId());
        user.setTargetProcedure(TargetProcedure.NAT);
        user.setTargetLevel(TargetProcedure.NAT.getRequiredTcfLevel());
        return data.saveUser(user);
    }

    /**
     * Une competence du <b>referentiel seede</b>, jamais une competence creee :
     * une ligne creee ici survivrait a la classe (ces tests ne sont pas
     * transactionnels) et ferait echouer, a distance, les tests qui comptent le
     * referentiel.
     */
    private Skill competenceEE(int rang) {
        List<Skill> seedees = skillManager.findActiveByTaskCode(SkillTaskCode.EE1);
        assertThat(seedees).as("referentiel seede EE1").hasSizeGreaterThan(rang);
        return seedees.get(rang);
    }

    private DiagnosticSession diagnosticTermine(User user) {
        return data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
    }

    private ProductionSubmission soumissionEcriteDe(DiagnosticSession session, User user) {
        return data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user);
    }

    /**
     * Une epreuve de production reellement passee : <b>slot pose au demarrage</b>
     * et session close — meme forme que {@code TestData.epreuveProductionPassee},
     * dont on ne peut pas se servir ici parce qu'il faut les identifiants des
     * soumissions pour y claveter les observations.
     */
    private Attempt epreuveDeProduction(User user, EpreuveType epreuve) {
        Attempt attempt = data.attempt(user);
        attempt.setModule(Module.TCF);
        attempt.setEpreuve(epreuve);
        attempt.setType(AttemptType.TRAINING);
        attempt.setMode(AttemptMode.EXAMEN);
        attempt.setSlotNumber(1);
        attempt.setStatus(AttemptStatus.TERMINE);
        attempt.setFinishedAt(Instant.now().minusSeconds(60));
        return data.saveAttempt(attempt);
    }

    private void observationDeDiagnostic(
            User user, Skill skill, ProductionSubmission soumission,
            LearningPlanSkillStatus statut) {
        observation(user, skill, soumission.getId(),
                LearningPlanSourceType.DIAGNOSTIC_EE, statut);
    }

    private void observation(
            User user, Skill skill, UUID sourceId, LearningPlanSourceType source,
            LearningPlanSkillStatus statut) {
        data.learningPlanObservation(user, skill, source, statut,
                ObservationConfidence.HIGH, null, Instant.now().minusSeconds(30), sourceId);
    }

    private JourneyLot lotOuvert(User user, EpreuveType epreuve) {
        Journey journey = journeyService.getOrCreate(user.getId(), Module.TCF).orElseThrow();
        return lots.findByJourneyIdAndExamTypeAndStatus(
                journey.getId(), epreuve, JourneyLotStatus.OPEN).orElse(null);
    }

    private List<JourneyStep> entrainementsDuLot(JourneyLot lot) {
        return steps.findAllByJourney(lot.getJourney().getId()).stream()
                .filter(step -> step.getLot() != null
                        && step.getLot().getId().equals(lot.getId()))
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .toList();
    }
}
