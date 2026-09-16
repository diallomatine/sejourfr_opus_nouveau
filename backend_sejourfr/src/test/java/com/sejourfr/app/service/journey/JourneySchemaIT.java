package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.repository.JourneyAssessmentEventRepository;
import com.sejourfr.app.repository.JourneyLotRepository;
import com.sejourfr.app.repository.JourneyRepository;
import com.sejourfr.app.repository.JourneyStepRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * <b>Le schema du parcours tient ses invariants, et c'est la BASE qui les
 * tient</b> — pas une convention de service.
 *
 * <p>Motif : le parcours est ecrit depuis plusieurs branchements best-effort
 * (fin de QCM, fin d'evaluation de production, cloture de diagnostic), chacun
 * dans sa propre transaction. Une regle que seul un service tiendrait finirait
 * par etre contournee par le branchement suivant. Les contraintes verifiees ici
 * sont donc celles qu'aucun appelant ne peut violer.
 */
class JourneySchemaIT extends AbstractIntegrationTest {

    @Autowired private JourneyRepository journeys;
    @Autowired private JourneyLotRepository lots;
    @Autowired private JourneyStepRepository steps;
    @Autowired private JourneyAssessmentEventRepository events;
    @Autowired private TestData data;

    // ------------------------------------------------------------------ R18

    @Test
    @DisplayName("Un parcours par (candidat, niveau cible) — le second est refuse")
    void unParcoursParCandidatEtNiveau() {
        User user = data.user();
        journeys.saveAndFlush(journey(user, TargetLevel.B2));
        // Le meme candidat PEUT avoir un parcours B1 : c'est R18, « l'ancien est
        // conserve tel quel ». Ce qu'on refuse, c'est un DOUBLON du meme niveau.
        journeys.saveAndFlush(journey(user, TargetLevel.B1));

        assertThatThrownBy(() -> journeys.saveAndFlush(journey(user, TargetLevel.B2)))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_journey_user_target");
    }

    // ------------------------------------------------------------------- R5

    @Test
    @DisplayName("Au plus un lot OUVERT par epreuve (R5), et c'est un index qui le tient")
    void auPlusUnLotOuvertParEpreuve() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        lots.saveAndFlush(lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN));
        // Une autre EPREUVE reste libre : l'invariant est par epreuve, pas par
        // parcours — sinon une seule epreuve monopoliserait le Plan (R6).
        lots.saveAndFlush(lot(journey, EpreuveType.TCF_CO, JourneyLotStatus.OPEN));

        assertThatThrownBy(() ->
                lots.saveAndFlush(lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN)))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_journey_lot_open_par_epreuve");
    }

    @Test
    @DisplayName("Plusieurs lots FERMES de la meme epreuve coexistent — c'est l'historique")
    void plusieursLotsFermesCoexistent() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyLot ferme = lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.CLOSED);
        ferme.setClosedAt(Instant.now());
        lots.saveAndFlush(ferme);
        JourneyLot remplace = lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.SUPERSEDED);
        remplace.setClosedAt(Instant.now());
        lots.saveAndFlush(remplace);

        // R7 fait defiler les lots d'une meme epreuve : les garder tous est le
        // sens meme de « le Plan apprend des evaluations ».
        assertThat(lots.findByJourneyIdAndStatus(journey.getId(), JourneyLotStatus.OPEN))
                .isEmpty();
    }

    @Test
    @DisplayName("Un lot ouvert ne peut pas porter de date de cloture")
    void unLotOuvertNaPasDeDateDeCloture() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyLot incoherent = lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN);
        incoherent.setClosedAt(Instant.now());

        assertThatThrownBy(() -> lots.saveAndFlush(incoherent))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_lot_closed_at");
    }

    // ------------------------------------------------------------------- D-7

    @Test
    @DisplayName("Une cloture est ATOMIQUE : pas de date sans motif")
    void uneClotureEstAtomique() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyStep sansMotif = diagnostic(journey, 1L);
        sansMotif.setClosedAt(Instant.now());   // ... et pas de resolution

        assertThatThrownBy(() -> steps.saveAndFlush(sansMotif))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_step_closure");
    }

    @Test
    @DisplayName("clore() ne reecrit JAMAIS une cloture deja posee")
    void clorerNeReecritJamais() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyStep step = steps.saveAndFlush(diagnostic(journey, 1L));
        Instant premiere = Instant.now().minusSeconds(3600);

        assertThat(step.clore(JourneyStepResolution.MASTERED, null, premiere)).isTrue();
        // 🛑 L'invariant D-7 : « ecrite une seule fois, jamais reouverte ». Un
        // rejeu, une course ou un double branchement retombent sur la premiere
        // cloture — celle qui est vraie.
        assertThat(step.clore(JourneyStepResolution.SUPERSEDED, UUID.randomUUID(), Instant.now()))
                .isFalse();
        assertThat(step.getClosedAt()).isEqualTo(premiere);
        assertThat(step.getResolution()).isEqualTo(JourneyStepResolution.MASTERED);
    }

    // ------------------------------------------------------- forme des etapes

    @Test
    @DisplayName("Une etape DIAGNOSTIC ne porte ni epreuve, ni lot, ni competence")
    void uneEtapeDiagnosticNePorteRien() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyStep incoherent = diagnostic(journey, 1L);
        incoherent.setExamType(EpreuveType.TCF_EE);

        assertThatThrownBy(() -> steps.saveAndFlush(incoherent))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_step_diagnostic");
    }

    @Test
    @DisplayName("Une etape TRAIN_SKILL sans competence est refusee")
    void uneEtapeDEntrainementPorteToujoursSaCompetence() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyLot lot = lots.saveAndFlush(lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN));
        JourneyStep sansCompetence = new JourneyStep();
        sansCompetence.setJourney(journey);
        sansCompetence.setLot(lot);
        sansCompetence.setType(JourneyStepType.TRAIN_SKILL);
        sansCompetence.setExamType(EpreuveType.TCF_EE);
        sansCompetence.setPosition(1L);

        assertThatThrownBy(() -> steps.saveAndFlush(sansCompetence))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_step_train_skill");
    }

    @Test
    @DisplayName("Une etape SECTION_EXAM porte toujours son intention")
    void uneEtapeDExamenPorteToujoursSonIntention() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyStep sansPurpose = new JourneyStep();
        sansPurpose.setJourney(journey);
        sansPurpose.setType(JourneyStepType.SECTION_EXAM);
        sansPurpose.setExamType(EpreuveType.TCF_CO);
        sansPurpose.setPosition(1L);

        // « Evaluer mon niveau » et « Verifier mes progres » sont la meme action
        // pour deux raisons differentes : sans purpose, l'ecran ne peut pas
        // choisir laquelle annoncer.
        assertThatThrownBy(() -> steps.saveAndFlush(sansPurpose))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_step_section_exam");
    }

    // ------------------------------------------------------------------ R13

    @Test
    @DisplayName("Pas deux fois la meme competence dans un meme lot (R13)")
    void pasDeuxFoisLaMemeCompetenceDansUnLot() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        JourneyLot lot = lots.saveAndFlush(lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN));
        Skill skill = data.skill(SkillTaskCode.EE1);
        steps.saveAndFlush(trainSkill(journey, lot, skill, 1L));

        assertThatThrownBy(() -> steps.saveAndFlush(trainSkill(journey, lot, skill, 2L)))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_journey_step_lot_skill");
    }

    @Test
    @DisplayName("La meme competence revient dans un AUTRE lot — nouvelle occurrence legitime")
    void laMemeCompetenceRevientDansUnAutreLot() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        Skill skill = data.skill(SkillTaskCode.EE1);
        JourneyLot ancien = lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.CLOSED);
        ancien.setClosedAt(Instant.now());
        lots.saveAndFlush(ancien);
        steps.saveAndFlush(trainSkill(journey, ancien, skill, 1L));

        JourneyLot nouveau =
                lots.saveAndFlush(lot(journey, EpreuveType.TCF_EE, JourneyLotStatus.OPEN));
        JourneyStep reprise = steps.saveAndFlush(trainSkill(journey, nouveau, skill, 2L));

        // R13 : l'unicite est bornee au LOT, jamais au parcours. Une fragilite
        // qu'un examen redetecte est une mesure neuve, pas un doublon.
        assertThat(reprise.getId()).isNotNull();
        assertThat(steps.findAllByJourney(journey.getId())).hasSize(2);
    }

    @Test
    @DisplayName("Deux etapes ne partagent jamais une position")
    void deuxEtapesNePartagentJamaisUnePosition() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        steps.saveAndFlush(diagnostic(journey, 7L));
        JourneyStep doublon = new JourneyStep();
        doublon.setJourney(journey);
        doublon.setType(JourneyStepType.SECTION_EXAM);
        doublon.setExamType(EpreuveType.TCF_CO);
        doublon.setPurpose(JourneyStepPurpose.INITIAL_ASSESSMENT);
        doublon.setPosition(7L);

        // Deux etapes « au meme rang » rendraient l'election de CURRENT non
        // deterministe : le candidat verrait une etape differente a chaque appel.
        assertThatThrownBy(() -> steps.saveAndFlush(doublon))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_journey_step_position");
    }

    // ------------------------------------------------------------------ R14

    @Test
    @DisplayName("Une evaluation n'est enregistree qu'une fois (R14)")
    void uneEvaluationNestEnregistreeQuUneFois() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        UUID evaluation = UUID.randomUUID();
        events.saveAndFlush(event(journey, evaluation, JourneyAssessmentKind.SECTION_EXAM,
                EpreuveType.TCF_CO, Instant.now()));

        assertThatThrownBy(() -> events.saveAndFlush(
                event(journey, evaluation, JourneyAssessmentKind.SECTION_EXAM,
                        EpreuveType.TCF_CO, Instant.now())))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("uq_journey_assessment_event");
    }

    @Test
    @DisplayName("Seul le diagnostic RAPIDE ne mesure aucune epreuve (R11)")
    void seulLeDiagnosticRapideNeMesureRien() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        events.saveAndFlush(event(journey, UUID.randomUUID(),
                JourneyAssessmentKind.QUICK_DIAGNOSTIC, null, Instant.now()));

        // Un examen qui ne dirait pas quelle epreuve il mesure priverait R14 de
        // son repere : c'est exactement le trou que ce CHECK ferme.
        assertThatThrownBy(() -> events.saveAndFlush(
                event(journey, UUID.randomUUID(), JourneyAssessmentKind.SECTION_EXAM,
                        null, Instant.now())))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_journey_assessment_epreuve_mesuree");
    }

    @Test
    @DisplayName("La derniere mesure d'une epreuve se lit sur les evenements, par epreuve")
    void laDerniereMesureSeLitParEpreuve() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));
        Instant vieux = Instant.now().minusSeconds(7200);
        Instant recent = Instant.now().minusSeconds(60);
        events.saveAndFlush(event(journey, UUID.randomUUID(),
                JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_CO, vieux));
        events.saveAndFlush(event(journey, UUID.randomUUID(),
                JourneyAssessmentKind.MOCK_EXAM, EpreuveType.TCF_CO, recent));
        events.saveAndFlush(event(journey, UUID.randomUUID(),
                JourneyAssessmentKind.SECTION_EXAM, EpreuveType.TCF_EE, vieux));

        assertThat(events.findDerniereMesureDeLEpreuve(journey.getId(), EpreuveType.TCF_CO))
                .contains(recent);
        assertThat(events.findDerniereMesureDeLEpreuve(journey.getId(), EpreuveType.TCF_EE))
                .contains(vieux);
        // 🛑 Vide ne veut PAS dire « epreuve non mesuree » : cette question a une
        // seule autorite dans le depot, et ce n'est pas cette table.
        assertThat(events.findDerniereMesureDeLEpreuve(journey.getId(), EpreuveType.TCF_EO))
                .isEmpty();
    }

    // ---------------------------------------------------------------- R4 / R18

    @Test
    @DisplayName("Le compteur de positions est monotone")
    void leCompteurDePositionsEstMonotone() {
        Journey journey = journeys.saveAndFlush(journey(data.user(), TargetLevel.B2));

        assertThat(journey.consommerPosition()).isEqualTo(1L);
        assertThat(journey.consommerPosition()).isEqualTo(2L);
        assertThat(journey.consommerPosition()).isEqualTo(3L);
        // Il ne recule jamais : R4 veut qu'une nouvelle etape se range APRES
        // tout ce qui est deja planifie, meme apres des dizaines de clotures.
        assertThat(journey.getNextPosition()).isEqualTo(4L);
    }

    // -------------------------------------------------------------- fabriques

    private static Journey journey(User user, TargetLevel level) {
        Journey journey = new Journey();
        journey.setUser(user);
        journey.setTargetLevel(level);
        return journey;
    }

    private static JourneyLot lot(Journey journey, EpreuveType epreuve, JourneyLotStatus status) {
        JourneyLot lot = new JourneyLot();
        lot.setJourney(journey);
        lot.setExamType(epreuve);
        lot.setStatus(status);
        lot.setSourceAssessmentId(UUID.randomUUID());
        return lot;
    }

    private static JourneyStep diagnostic(Journey journey, long position) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setType(JourneyStepType.DIAGNOSTIC);
        step.setPosition(position);
        return step;
    }

    private static JourneyStep trainSkill(
            Journey journey, JourneyLot lot, Skill skill, long position) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setLot(lot);
        step.setType(JourneyStepType.TRAIN_SKILL);
        step.setExamType(lot.getExamType());
        step.setSkill(skill);
        step.setPosition(position);
        return step;
    }

    private static JourneyAssessmentEvent event(
            Journey journey, UUID assessmentId, JourneyAssessmentKind kind,
            EpreuveType epreuve, Instant completedAt) {
        JourneyAssessmentEvent event = new JourneyAssessmentEvent();
        event.setJourney(journey);
        event.setSourceAssessmentId(assessmentId);
        event.setAssessmentKind(kind);
        event.setExamType(epreuve);
        event.setCompletedAt(completedAt);
        return event;
    }
}
