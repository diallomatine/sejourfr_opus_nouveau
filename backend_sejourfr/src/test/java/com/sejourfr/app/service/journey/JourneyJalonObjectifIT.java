package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyExamenCompletDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyJalonRaison;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le jalon « Faire un examen blanc complet » au titre de l'OBJECTIF ATTEINT</b>
 * (2026-09-27, D-68) : les quatre epreuves au niveau de l'objectif, <b>mesurees
 * par un examen blanc</b> — jamais par le diagnostic.
 *
 * <p>🛑 <b>Transactionnel, a la difference de {@link JourneyJalonExamenCompletIT}</b> :
 * un examen QCM fabrique ({@code TestData.examenQcmTcfPasse}) cree ses questions
 * et leur thematique, et hors transaction elles survivraient au test — vingt-cinq
 * thematiques CIVIQUES de plus par examen, que les tests du cycle civique
 * compteraient. Ces cas-ci ne font que <b>lire</b> le parcours : ils n'ont pas
 * besoin des ecritures {@code REQUIRES_NEW}.
 */
class JourneyJalonObjectifIT extends AbstractIntegrationTest {

    @Autowired private JourneyService journeyService;
    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;
    @Autowired private SkillManager skillManager;
    @Autowired private TestData data;

    // =====================================================================
    // D-68 — le jalon : l'objectif atteint partout, par EXAMEN BLANC
    // =====================================================================

    @Test
    @DisplayName("D-68 — objectif atteint sur les quatre epreuves par examen blanc : jalon "
            + "propose des le premier cycle, et il l'emporte sur le compte des cycles")
    void lObjectifAtteintParExamenProposeLeJalon() {
        User user = abonne();
        quatreEpreuvesParExamen(user, NiveauCecrl.B2);
        cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        JourneyExamenCompletDto jalon = journeyService.lire(user.getId(), Module.TCF).examenComplet();

        assertThat(jalon).isNotNull();
        assertThat(jalon.raison()).isEqualTo(JourneyJalonRaison.OBJECTIF_ATTEINT);
        assertThat(jalon.cyclesDeTravail()).isZero();
    }

    @Test
    @DisplayName("D-68 — un palier sous l'objectif sur UNE epreuve : pas de jalon")
    void unPalierSousLObjectifNeProposeRien() {
        User user = abonne();
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.B2);
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CE, NiveauCecrl.B1);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EE, NiveauCecrl.B2);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EO, NiveauCecrl.B2);
        cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet()).isNull();
    }

    @Test
    @DisplayName("D-68 — un palier lu sur le DIAGNOSTIC ne compte jamais, meme a l'objectif")
    void unPalierDuDiagnosticNeComptePas() {
        User user = abonne();
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.B2);
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CE, NiveauCecrl.B2);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EO, NiveauCecrl.B2);
        // EE : seulement le diagnostic rapide, au niveau de l'objectif.
        DiagnosticSession session = data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        ProductionSubmission ecrit = data.diagnosticSubmission(
                session.getWrittenAttempt(), session.getWrittenTask(), user);
        data.diagnosticAnalysis(ecrit, NiveauCecrl.B2);
        cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet()).isNull();
    }

    @Test
    @DisplayName("D-68 — objectif atteint mais examen complet a peine passe : pas de jalon "
            + "tant qu'aucun cycle de travail n'est termine")
    void pasDeJalonJusteApresUnExamenComplet() {
        User user = abonne();
        quatreEpreuvesParExamen(user, NiveauCecrl.B2);
        cycleDeTravail(user, JourneyStatus.HISTORISE, false, JourneyFinDeCycle.INTERROMPU);
        cycleDExamensClos(user);
        Journey courant = cycleDeTravail(user, JourneyStatus.EN_COURS, false, null);

        assertThat(journeyService.lire(user.getId(), Module.TCF).examenComplet()).isNull();

        cloreToutesLesEtapes(courant);
        JourneyExamenCompletDto jalon = journeyService.lire(user.getId(), Module.TCF).examenComplet();
        assertThat(jalon).isNotNull();
        assertThat(jalon.raison()).isEqualTo(JourneyJalonRaison.OBJECTIF_ATTEINT);
    }

    // ------------------------------------------------------------- fabriques

    /** Les quatre epreuves mesurees par EXAMEN BLANC au palier donne. */
    private void quatreEpreuvesParExamen(User user, NiveauCecrl niveau) {
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, niveau);
        data.examenQcmTcfPasse(user, EpreuveType.TCF_CE, niveau);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EE, niveau);
        data.epreuveProductionPassee(user, EpreuveType.TCF_EO, niveau);
    }

    private User candidat() {
        User user = data.user();
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
