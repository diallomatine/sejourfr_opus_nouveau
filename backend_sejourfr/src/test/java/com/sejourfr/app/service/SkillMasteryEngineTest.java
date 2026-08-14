package com.sejourfr.app.service;

import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillMasteryState;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le coeur du moteur de maitrise, teste sur les <b>valeurs de configuration par
 * defaut</b> — celles qui tourneront en production.
 *
 * <p>Ce qui est verrouille ici n'est pas un nombre, c'est une <b>regle
 * pedagogique</b> : un micro-exercice ne declare jamais une maitrise, une preuve
 * en situation vaut plus qu'une preuve guidee, une erreur isolee ne detruit pas
 * un acquis, et « je n'ai pas pu observer » ne devient jamais « le candidat est
 * mauvais ». Recalibrer une ponderation doit garder ces phrases vraies.
 */
class SkillMasteryEngineTest {

    private final LearningPlanProperties properties = new LearningPlanProperties();
    private final SkillMasteryEngine engine = new SkillMasteryEngine(properties);
    private final Instant now = Instant.parse("2026-08-12T10:00:00Z");

    // ------------------------------------------------------------------------
    // Rien observe : le moteur n'invente rien
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Sans aucune observation, aucun etat n'est invente")
    void sansObservationAucunEtat() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(), now);

        assertThat(mastery.state()).isNull();
        assertThat(mastery.observationCount()).isZero();
        assertThat(mastery.readyForReassessment()).isFalse();
        assertThat(mastery.lastObservedAt()).isNull();
    }

    @Test
    @DisplayName("« Pas observable » n'est jamais « le candidat est mauvais »")
    void lesNonObserveesSontIgnorees() {
        UUID sujet = UUID.randomUUID();
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, sujet, jours(2)),
                nonObservee(jours(1)),
                nonObservee(jours(3)),
                nonObservee(jours(5))), now);

        assertThat(mastery.observationCount()).isEqualTo(1);
        assertThat(mastery.score()).isEqualTo(1.0);
        assertThat(engine.evaluate(List.of(nonObservee(jours(1))), now).state()).isNull();
    }

    @Test
    @DisplayName("Hors fenetre glissante, une observation ne compte plus du tout")
    void horsFenetreRienNestRetenu() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(400))), now);

        assertThat(mastery.state()).isNull();
    }

    // ------------------------------------------------------------------------
    // Micro-entrainement : il fait progresser, il ne conclut jamais
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Un micro-entrainement reussi seul ne declare jamais SOLID")
    void unMicroEntrainementSeulNeDeclareJamaisSolide() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                microReussi(UUID.randomUUID(), jours(1))), now);

        assertThat(mastery.state())
                .isNotEqualTo(SkillMasteryState.SOLID)
                .isEqualTo(SkillMasteryState.TO_REINFORCE);
        assertThat(mastery.readyForReassessment()).isFalse();
    }

    @Test
    @DisplayName("Meme excellents et repetes, des micro-entrainements plafonnent a EN CONSOLIDATION")
    void desMicroEntrainementsSeulsPlafonnentAConsolidating() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(1)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(3)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(5))), now);

        assertThat(mastery.score()).isEqualTo(1.0);
        assertThat(mastery.contextualPositiveCount()).isZero();
        assertThat(mastery.state()).isEqualTo(SkillMasteryState.CONSOLIDATING);
    }

    @Test
    @DisplayName("Plusieurs reussites ciblees : EN CONSOLIDATION et le signal de verification")
    void plusieursReussitesCibleesOuvrentLaVerification() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                microReussi(UUID.randomUUID(), jours(1)),
                microReussi(UUID.randomUUID(), jours(4))), now);

        assertThat(mastery.state()).isEqualTo(SkillMasteryState.CONSOLIDATING);
        assertThat(mastery.readyForReassessment()).isTrue();
    }

    /** La boucle de reference du brief : un exercice rate, deux reussis, on verifie. */
    @Test
    @DisplayName("Un premier essai rate n'empeche pas d'ouvrir la verification")
    void unPremierEssaiRateNempechePasLaVerification() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(40)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(20)),
                microReussi(UUID.randomUUID(), jours(10)),
                microReussi(UUID.randomUUID(), jours(5))), now);

        assertThat(mastery.readyForReassessment()).isTrue();
    }

    @Test
    @DisplayName("Deux reussites noyees dans les echecs n'ouvrent pas la verification")
    void deuxReussitesNoyeesDansLesEchecsNouvrentPasLaVerification() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                microReussi(UUID.randomUUID(), jours(10)),
                microReussi(UUID.randomUUID(), jours(9)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(3)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(2)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(1))), now);

        assertThat(mastery.readyForReassessment()).isFalse();
    }

    /**
     * Le filtre des reussites ciblees est <b>propre au signal de reevaluation</b> :
     * deux echecs sur deux sujets differents n'ouvrent rien, meme si le candidat
     * a « couvert » les deux sujets.
     */
    @Test
    @DisplayName("Deux echecs cibles sur deux sujets differents n'ouvrent pas la verification")
    void deuxEchecsCiblesNouvrentPasLaVerification() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(2)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.MEDIUM, UUID.randomUUID(), jours(1))), now);

        assertThat(mastery.readyForReassessment()).isFalse();
        assertThat(mastery.state()).isEqualTo(SkillMasteryState.PRIORITY);
    }

    /**
     * Garde-fou de calibration, pas de comportement : la voie ciblee n'ecrit
     * jamais {@code SOLID}, donc la performance ciblee ne depasse jamais
     * {@code 0.5}. Un seuil au-dela eteindrait le signal au lieu de le durcir —
     * et avec lui {@code SOLID}, qui reclame la preuve contextualisee que seule
     * la verification apporte a un candidat en micro-entrainement.
     */
    @Test
    @DisplayName("Le seuil de performance ciblee reste sous le plafond reellement atteignable")
    void leSeuilCibleResteAtteignable() {
        assertThat(properties.getMastery().getReadinessTargetedScore()).isLessThan(0.5);
    }

    @Test
    @DisplayName("Le meme sujet repete n'ouvre pas la verification : on cherche le transfert")
    void leMemeSujetRepeteNouvrePasLaVerification() {
        UUID memeSujet = UUID.randomUUID();
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                microReussi(memeSujet, jours(1)),
                microReussi(memeSujet, jours(2)),
                microReussi(memeSujet, jours(3))), now);

        assertThat(mastery.readyForReassessment()).isFalse();
        assertThat(mastery.state()).isNotEqualTo(SkillMasteryState.SOLID);
    }

    @Test
    @DisplayName("Une preuve de transfert recente ferme le signal de verification")
    void unePreuveDeTransfertRecenteFermeLaVerification() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                microReussi(UUID.randomUUID(), jours(10)),
                microReussi(UUID.randomUUID(), jours(12)),
                observation(LearningPlanSourceType.PRODUCTION_EO,
                        LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM,
                        UUID.randomUUID(), jours(2))), now);

        assertThat(mastery.readyForReassessment()).isFalse();
    }

    // ------------------------------------------------------------------------
    // Preuve en situation
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une reussite contextualisee confirme SOLID")
    void uneReussiteContextualiseeConfirmeSolide() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(parcoursConfirme(), now);

        assertThat(mastery.state()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(mastery.contextualPositiveCount()).isEqualTo(1);
        assertThat(mastery.vigilance()).isFalse();
        assertThat(mastery.readyForReassessment()).isFalse();
    }

    @Test
    @DisplayName("Toutes les preuves sur le MEME sujet ne confirment pas une maitrise")
    void toutesLesPreuvesSurLeMemeSujetNeConfirmentPas() {
        UUID memeSujet = UUID.randomUUID();
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, memeSujet, jours(1)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, memeSujet, jours(3)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, memeSujet, jours(5))), now);

        assertThat(mastery.score()).isEqualTo(1.0);
        assertThat(mastery.distinctSubjectCount()).isEqualTo(1);
        assertThat(mastery.state()).isEqualTo(SkillMasteryState.CONSOLIDATING);
    }

    // ------------------------------------------------------------------------
    // Stabilite
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une seule production moins bonne ne casse pas une competence solide")
    void uneSeuleFragiliteNeCassePasUneCompetenceSolide() {
        List<LearningPlanObservation> historique = new java.util.ArrayList<>(parcoursConfirme());
        historique.add(fragiliteContextualisee(jours(1)));

        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(historique, now);

        assertThat(mastery.state()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(mastery.vigilance()).isTrue();
        // Le score BRUT est bien tombe : c'est le filet de stabilite qui tient
        // l'etat, pas une moyenne complaisante.
        assertThat(mastery.score()).isLessThan(properties.getMastery().getSolidScore());
    }

    @Test
    @DisplayName("Deux fragilites contextualisees recentes font redescendre la competence")
    void deuxFragilitesContextualiseesFontRedescendre() {
        List<LearningPlanObservation> historique = new java.util.ArrayList<>(parcoursConfirme());
        historique.add(fragiliteContextualisee(jours(1)));
        historique.add(fragiliteContextualisee(jours(3)));

        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(historique, now);

        assertThat(mastery.state()).isNotEqualTo(SkillMasteryState.SOLID);
        assertThat(mastery.vigilance()).isFalse();
    }

    @Test
    @DisplayName("Une fragilite en micro-entrainement ne remet pas en cause une maitrise")
    void uneFragiliteCibleeNeRemetPasEnCauseUneMaitrise() {
        List<LearningPlanObservation> historique = new java.util.ArrayList<>(parcoursConfirme());
        historique.add(observation(LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.PRIORITY, ObservationConfidence.MEDIUM,
                UUID.randomUUID(), jours(1)));

        assertThat(engine.evaluate(historique, now).state()).isEqualTo(SkillMasteryState.SOLID);
    }

    // ------------------------------------------------------------------------
    // Ponderations
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("Une observation ancienne pese moins qu'une recente")
    void uneObservationAnciennePeseMoinsQuUneRecente() {
        double reussiteRecente = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(2)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(100))), now).score();

        double reussiteAncienne = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(100)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(2))), now).score();

        assertThat(reussiteRecente).isGreaterThan(reussiteAncienne);
    }

    @Test
    @DisplayName("Une observation d'examen blanc pese plus qu'un micro-entrainement")
    void unExamenBlancPesePlusQuUnMicroEntrainement() {
        UUID a = UUID.randomUUID();
        UUID b = UUID.randomUUID();
        double examenReussi = engine.evaluate(List.of(
                observation(LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, a, jours(2)),
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, b, jours(2))), now).score();

        double microReussi = engine.evaluate(List.of(
                observation(LearningPlanSourceType.SKILL_TRAINING, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, a, jours(2)),
                observation(LearningPlanSourceType.MOCK_EXAM_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, b, jours(2))), now).score();

        assertThat(examenReussi).isGreaterThan(microReussi);
        assertThat(examenReussi).isGreaterThan(properties.getMastery().getConsolidatingScore());
        assertThat(microReussi).isLessThan(properties.getMastery().getReinforceScore());
    }

    @Test
    @DisplayName("Une confiance basse pese moins qu'une confiance haute")
    void uneConfianceBassePeseMoins() {
        UUID a = UUID.randomUUID();
        UUID b = UUID.randomUUID();
        double reussiteSure = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, a, jours(2)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.LOW, b, jours(2))), now).score();

        double reussiteIncertaine = engine.evaluate(List.of(
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.LOW, a, jours(2)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, b, jours(2))), now).score();

        assertThat(reussiteSure).isGreaterThan(reussiteIncertaine);
    }

    @Test
    @DisplayName("Trente micro-exercices dans la journee n'ecrasent pas l'historique")
    void leNombreDObservationsRetenuesEstPlafonne() {
        List<LearningPlanObservation> serie = new java.util.ArrayList<>();
        for (int i = 0; i < 30; i++) {
            serie.add(microReussi(UUID.randomUUID(), jours(1)));
        }

        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(serie, now);

        assertThat(mastery.observationCount())
                .isEqualTo(properties.getMastery().getMaxObservations());
    }

    @Test
    @DisplayName("Une fragilite du diagnostic seule reste une priorite")
    void uneFragiliteDeBaselineResteUnePriorite() {
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                observation(LearningPlanSourceType.DIAGNOSTIC_EE, LearningPlanSkillStatus.PRIORITY,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(3))), now);

        assertThat(mastery.state()).isEqualTo(SkillMasteryState.PRIORITY);
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    /** Deux micro-exercices reussis sur des sujets differents, puis une vraie production. */
    private List<LearningPlanObservation> parcoursConfirme() {
        return List.of(
                microReussi(UUID.randomUUID(), jours(20)),
                microReussi(UUID.randomUUID(), jours(15)),
                observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.SOLID,
                        ObservationConfidence.HIGH, UUID.randomUUID(), jours(6)));
    }

    /** Ce qu'ecrit reellement le module Competences apres un critere valide. */
    private LearningPlanObservation microReussi(UUID sujet, Instant quand) {
        return observation(LearningPlanSourceType.SKILL_TRAINING,
                LearningPlanSkillStatus.TO_REINFORCE, ObservationConfidence.MEDIUM, sujet, quand);
    }

    private LearningPlanObservation fragiliteContextualisee(Instant quand) {
        return observation(LearningPlanSourceType.PRODUCTION_EE, LearningPlanSkillStatus.PRIORITY,
                ObservationConfidence.HIGH, UUID.randomUUID(), quand);
    }

    private LearningPlanObservation nonObservee(Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSourceType(LearningPlanSourceType.PRODUCTION_EO);
        observation.setStatus(LearningPlanSkillStatus.NOT_OBSERVED);
        observation.setObserved(false);
        observation.setObservedAt(quand);
        return observation;
    }

    private static LearningPlanObservation observation(
            LearningPlanSourceType source, LearningPlanSkillStatus status,
            ObservationConfidence confidence, UUID sujet, Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSourceType(source);
        observation.setStatus(status);
        observation.setConfidence(confidence);
        observation.setObserved(true);
        observation.setSubjectId(sujet);
        observation.setObservedAt(quand);
        return observation;
    }

    private Instant jours(int nombre) {
        return now.minus(Duration.ofDays(nombre));
    }
}
