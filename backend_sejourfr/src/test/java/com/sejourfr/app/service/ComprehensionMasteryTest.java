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
 * Ce que l'entree de la COMPREHENSION dans le moteur de maitrise change — et
 * surtout ce qu'elle <b>ne change pas</b>.
 *
 * <p>{@code TCF_CO} / {@code TCF_CE} sont declarees <b>contextualisees</b>
 * (2026-08-21) : un QCM de comprehension EST le format reel de l'epreuve, il
 * n'existe pas de version guidee a laquelle l'opposer, contrairement au couple
 * micro-exercice / production complete des competences d'expression. Sans cela,
 * aucune competence CO/CE ne pourrait jamais devenir solide : elle attendrait
 * une preuve en situation qui n'existe pas.
 *
 * <p>La verification centrale de ce fichier est <b>l'absence d'effet de bord sur
 * EE/EO</b> : les six autres sources gardent exactement la reponse qu'elles
 * avaient.
 */
class ComprehensionMasteryTest {

    private final LearningPlanProperties properties = new LearningPlanProperties();
    private final SkillMasteryEngine engine = new SkillMasteryEngine(properties);
    private final Instant now = Instant.parse("2026-08-21T10:00:00Z");

    @Test
    @DisplayName("Les sources d'EXPRESSION gardent exactement leur nature")
    void lesSourcesDExpressionNeBougentPas() {
        // Verrou : la comprehension a rejoint « contextualise », rien d'autre.
        assertThat(LearningPlanSourceType.PRODUCTION_EE.isContextual()).isTrue();
        assertThat(LearningPlanSourceType.PRODUCTION_EO.isContextual()).isTrue();
        assertThat(LearningPlanSourceType.MOCK_EXAM_EE.isContextual()).isTrue();
        assertThat(LearningPlanSourceType.MOCK_EXAM_EO.isContextual()).isTrue();
        // La baseline ne confirme jamais : c'est le point de depart a depasser.
        assertThat(LearningPlanSourceType.DIAGNOSTIC_EE.isContextual()).isFalse();
        assertThat(LearningPlanSourceType.DIAGNOSTIC_EO.isContextual()).isFalse();
        // Un micro-entrainement fait progresser, il ne prouve pas le transfert.
        assertThat(LearningPlanSourceType.SKILL_TRAINING.isContextual()).isFalse();
        assertThat(LearningPlanSourceType.SKILL_TRAINING.isTargeted()).isTrue();
    }

    @Test
    @DisplayName("Une serie ciblee n'est pas un micro-entrainement : elle ne pollue pas le signal de verification")
    void laComprehensionNEstJamaisUneSourceCiblee() {
        // `isTargeted` pilote `readyForReassessment`, qui n'a de sens que pour
        // les competences d'expression : leur verification est une PRODUCTION.
        // Y ranger la comprehension ferait proposer une verification en
        // situation a une competence qui n'en a pas.
        assertThat(LearningPlanSourceType.TCF_CO.isTargeted()).isFalse();
        assertThat(LearningPlanSourceType.TCF_CE.isTargeted()).isFalse();
        assertThat(LearningPlanSourceType.TCF_CO.isComprehension()).isTrue();
        assertThat(LearningPlanSourceType.TCF_CE.isComprehension()).isTrue();
        assertThat(LearningPlanSourceType.PRODUCTION_EE.isComprehension()).isFalse();
    }

    @Test
    @DisplayName("Deux series ciblees reussies rendent une competence CO solide")
    void deuxSeriesReussiesRendentSolide() {
        // Chaque serie est une session distincte, donc un sujet distinct : deux
        // preuves independantes, exactement ce que le moteur exige.
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                comprehension(LearningPlanSkillStatus.SOLID, jours(10)),
                comprehension(LearningPlanSkillStatus.SOLID, jours(2))), now);

        assertThat(mastery.state()).isEqualTo(SkillMasteryState.SOLID);
        assertThat(mastery.contextualPositiveCount()).isEqualTo(2);
        assertThat(mastery.distinctSubjectCount()).isEqualTo(2);
        assertThat(mastery.transferProven()).isTrue();
    }

    @Test
    @DisplayName("Une seule serie reussie ne conclut rien : le moteur exige deux preuves")
    void uneSeuleSerieNeConclutPas() {
        // Consequence assumee de `min-positive-observations = 2`, seuil du
        // moteur qu'on ne touche pas : « solide localement » au sens du brief
        // demande deux sessions, pas une. Une seule serie fait progresser.
        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(
                List.of(comprehension(LearningPlanSkillStatus.SOLID, jours(1))), now);

        assertThat(mastery.state()).isNotEqualTo(SkillMasteryState.SOLID);
        assertThat(mastery.positiveCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("Une observation sous le plancher de fiabilite ne pese rien")
    void uneNonObserveeDeComprehensionNePesePas() {
        LearningPlanObservation nonFiable = new LearningPlanObservation();
        nonFiable.setSourceType(LearningPlanSourceType.TCF_CE);
        nonFiable.setStatus(LearningPlanSkillStatus.NOT_OBSERVED);
        nonFiable.setObserved(false);
        nonFiable.setObservedAt(jours(1));

        SkillMasteryEngine.SkillMastery mastery = engine.evaluate(List.of(
                comprehension(LearningPlanSkillStatus.SOLID, jours(3)), nonFiable), now);

        assertThat(mastery.observationCount()).isEqualTo(1);
        assertThat(mastery.score()).isEqualTo(1.0);
    }

    // ------------------------------------------------------------------ fixtures

    private LearningPlanObservation comprehension(LearningPlanSkillStatus status, Instant quand) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSourceType(LearningPlanSourceType.TCF_CO);
        observation.setStatus(status);
        observation.setConfidence(ObservationConfidence.HIGH);
        observation.setObserved(true);
        // Le sujet d'une session QCM, c'est la session elle-meme.
        observation.setSubjectId(UUID.randomUUID());
        observation.setObservedAt(quand);
        return observation;
    }

    private Instant jours(int nombre) {
        return now.minus(Duration.ofDays(nombre));
    }
}
