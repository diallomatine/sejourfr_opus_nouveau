package com.sejourfr.app.progression;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.engine.ProgressionEngine;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import static com.sejourfr.app.progression.EvidenceFixtures.T0;
import static com.sejourfr.app.progression.EvidenceFixtures.diagnostic;
import static com.sejourfr.app.progression.EvidenceFixtures.examenEpreuve;
import static com.sejourfr.app.progression.EvidenceFixtures.microSujet;
import static com.sejourfr.app.progression.EvidenceFixtures.serie;
import static com.sejourfr.app.progression.EvidenceFixtures.serieNonCalibree;
import static com.sejourfr.app.progression.EvidenceFixtures.vraieTache;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * <b>T01–T36 — les tests d'acceptation normatifs du moteur de progression
 * V4.2</b>, ecrits <i>avant</i> le moteur comme l'impose §49 phase 0.
 *
 * <p>Ce fichier est le contrat. Il n'est pas la pour verifier une
 * implementation : c'est l'implementation qui devra le satisfaire, sans qu'une
 * seule valeur attendue soit renegociee en route. Les valeurs de T01 a T06 sont
 * <b>normatives</b> et verifiees a {@code 1e-6} ; les agregats epoch a
 * {@code 1e-12}.
 *
 * <p>🛑 <b>Classe desactivee tant que la phase 1 n'a pas commence.</b> Le moteur
 * n'existe pas encore : la desactiver garde {@code ./mvnw verify} honnete
 * plutot que rouge en permanence, ce qui reviendrait a ne plus le regarder. La
 * phase 1 se termine quand on retire {@link Disabled} et que les 36 passent —
 * pas quand « ca a l'air de marcher ».
 *
 * <p>Le calcul a la main de T01 :
 * <pre>
 * 16/20 a 4 options   accuracy = 0.800000   guessRate = 0.250000
 * result   = (0.800000 - 0.250000) / 0.750000            = 0.733333
 * baseW    = 0.70 (serie calibree) x 1 x 1 x 1           = 0.700000
 * mastery  = 0.733333
 * conf     = min(1, 0.700000 / 1.50)                     = 0.466667
 * coverage = min(1, 1.00 / 3.0)                          = 0.333333
 * visible  = 100 x (0.55 x 0.333333 + 0.45 x 0.733333)   = 51.333333 -> 51
 * </pre>
 */
@Disabled("Phase 0 : contrat écrit avant le moteur (V4.2 §49). À réactiver en phase 1.")
class ProgressionEngineAcceptanceTest {

    private static final double EPS = 1e-6;
    private static final double EPS_AGGREGATE = 1e-12;

    private final ProgressionEngine engine = PhaseZeroEngine.pending();

    private static final ProgressionStateKey CO_A2 =
            ProgressionStateKey.receptive(SkillSection.CO, TargetLevel.A2);
    private static final ProgressionStateKey CO_B1 =
            ProgressionStateKey.receptive(SkillSection.CO, TargetLevel.B1);
    private static final ProgressionStateKey CO_B2 =
            ProgressionStateKey.receptive(SkillSection.CO, TargetLevel.B2);
    private static final ProgressionStateKey CE_B1 =
            ProgressionStateKey.receptive(SkillSection.CE, TargetLevel.B1);

    private static final String EE_CONNECTEURS = "EE_CONNECTEURS_B1";
    private static final ProgressionStateKey EE_SKILL =
            ProgressionStateKey.productive(SkillSection.EE, EE_CONNECTEURS);

    /* ------------------------------------------------ T01–T06 : valeurs dures */

    @Test
    @DisplayName("T01 — une seule bonne série A2 ne suffit pas à verrouiller")
    void t01() {
        List<LearningEvidence> preuves = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(preuves.getFirst().result()).isCloseTo(0.733333d, within(EPS));
        assertThat(engine.baseEffectiveWeight(preuves.getFirst()))
                .isCloseTo(0.700000d, within(EPS));
        assertThat(etat.masteryScore()).isCloseTo(0.733333d, within(EPS));
        assertThat(etat.confidence()).isCloseTo(0.466667d, within(EPS));
        assertThat(etat.qualificationGate()).isFalse();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.PROGRESSING);
        assertThat(etat.visibleProgress()).isEqualTo(51);

        DomainProjection co = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, preuves, T0);
        assertThat(co.activeLearningLevel()).isEqualTo(TargetLevel.A2);
        assertThat(co.prescriptionLevel()).isEqualTo(TargetLevel.A2);
    }

    @Test
    @DisplayName("T02 — deuxième série 17/20 confirme A2")
    void t02() {
        List<LearningEvidence> preuves = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0),
                serie(SkillSection.CO, TargetLevel.A2, 17, 20, 4, "S2", T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(preuves.get(1).result()).isCloseTo(0.800000d, within(EPS));
        assertThat(etat.masteryScore()).isCloseTo(0.766667d, within(EPS));
        assertThat(etat.confidence()).isCloseTo(0.933333d, within(EPS));
        assertThat(etat.qualificationGate()).isTrue();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.SOLID);
        assertThat(etat.directQualification()).isTrue();
        assertThat(etat.visibleProgress()).isEqualTo(100);

        DomainProjection co = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, preuves, T0);
        assertThat(co.activeLearningLevel()).isEqualTo(TargetLevel.B1);
    }

    @Test
    @DisplayName("T03 — preuve B1 isolée hors Plan ne mélange pas A2 et B1")
    void t03() {
        List<LearningEvidence> preuves = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0),
                serie(SkillSection.CO, TargetLevel.B1, 18, 20, 4, "S9", T0));

        ProgressionSnapshot b1 = engine.project(CO_B1, preuves, T0);
        assertThat(b1.masteryScore()).isCloseTo(0.866667d, within(EPS));
        assertThat(b1.confidence()).isCloseTo(0.466667d, within(EPS));
        assertThat(b1.qualificationGate()).isFalse();
        assertThat(b1.status()).isEqualTo(ProgressionStatus.PROGRESSING);
        assertThat(b1.directQualification()).isFalse();

        DomainProjection co = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, preuves, T0);
        assertThat(co.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, false);
        assertThat(co.activeLearningLevel()).isEqualTo(TargetLevel.A2);
        assertThat(co.prescriptionLevel()).isEqualTo(TargetLevel.A2);
    }

    @Test
    @DisplayName("T04 — CO et CE évoluent indépendamment")
    void t04() {
        List<LearningEvidence> preuves = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0),
                serie(SkillSection.CE, TargetLevel.A2, 16, 20, 4, "S2", T0),
                serie(SkillSection.CE, TargetLevel.A2, 17, 20, 4, "S3", T0),
                serie(SkillSection.CE, TargetLevel.B1, 16, 20, 4, "S4", T0));

        DomainProjection co = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, preuves, T0);
        DomainProjection ce = engine.projectDomain(
                SkillSection.CE, TargetLevel.B2, preuves, T0);

        assertThat(co.activeLearningLevel()).isEqualTo(TargetLevel.A2);
        assertThat(ce.activeLearningLevel()).isEqualTo(TargetLevel.B1);
        assertThat(engine.project(CE_B1, preuves, T0).status())
                .isEqualTo(ProgressionStatus.PROGRESSING);
    }

    @Test
    @DisplayName("T05 — deux séries non calibrées parfaites ne verrouillent pas")
    void t05() {
        List<LearningEvidence> preuves = List.of(
                serieNonCalibree(SkillSection.CO, TargetLevel.A2, 20, 20, 4, "S1", T0),
                serieNonCalibree(SkillSection.CO, TargetLevel.A2, 20, 20, 4, "S2", T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(preuves).allSatisfy(preuve ->
                assertThat(preuve.result()).isCloseTo(1.000000d, within(EPS)));
        assertThat(etat.masteryScore()).isCloseTo(1.000000d, within(EPS));
        assertThat(etat.confidence()).isCloseTo(0.666667d, within(EPS));
        assertThat(etat.qualificationGate()).isFalse();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.PROGRESSING);
        assertThat(engine.projectDomain(SkillSection.CO, TargetLevel.B2, preuves, T0)
                .activeLearningLevel()).isEqualTo(TargetLevel.A2);
    }

    @Test
    @DisplayName("T06 — la correction du hasard fonctionne aussi à 3 options")
    void t06() {
        List<LearningEvidence> preuves = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 3, "S1", T0),
                serie(SkillSection.CO, TargetLevel.A2, 17, 20, 3, "S2", T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(preuves.get(0).result()).isCloseTo(0.700000d, within(EPS));
        assertThat(preuves.get(1).result()).isCloseTo(0.775000d, within(EPS));
        assertThat(etat.masteryScore()).isCloseTo(0.737500d, within(EPS));
        assertThat(etat.confidence()).isCloseTo(0.933333d, within(EPS));
        assertThat(etat.qualificationGate()).isTrue();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.SOLID);
    }

    /* -------------------------------------------- T07–T10 : gates et politiques */

    @Test
    @DisplayName("T07 — un examen blanc fort peut verrouiller seul")
    void t07() {
        List<LearningEvidence> preuves = List.of(
                examenEpreuve(SkillSection.CO, TargetLevel.A2, 0.85d, "MOCK1", T0),
                examenEpreuve(SkillSection.CO, TargetLevel.A2, 0.82d, "MOCK2", T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(etat.masteryScore()).isGreaterThanOrEqualTo(0.70d);
        assertThat(etat.confidence()).isGreaterThanOrEqualTo(0.60d);
        assertThat(etat.qualificationGate()).isTrue();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T08 — un diagnostic seul ne verrouille jamais")
    void t08() {
        List<LearningEvidence> preuves = List.of(
                diagnostic(SkillSection.CO, TargetLevel.A2, 0.95d, T0));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(etat.qualificationGate()).isFalse();
        assertThat(etat.status()).isNotEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T09 — une série de pratique interrompue n'émet aucune preuve")
    void t09() {
        ProgressionSnapshot etat = engine.project(CO_A2, List.of(), T0);

        assertThat(etat.hasNoDirectEvidence()).isTrue();
        assertThat(etat.masteryScore()).isNull();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(etat.practicePoints()).isCloseTo(0.60d, within(EPS));
    }

    @Test
    @DisplayName("T10 — un examen expiré compte sur totalQuestions, jamais answeredCount")
    void t10() {
        assertThat(engine.chanceAdjustedResult(8, 20, 0.25d))
                .isCloseTo(0.200000d, within(EPS));
        assertThat(engine.chanceAdjustedResult(8, 12, 0.25d))
                .isNotCloseTo(0.200000d, within(EPS));
    }

    /* ------------------------------------- T11–T12 : commutativité, idempotence */

    @Test
    @DisplayName("T11 — les six permutations d'ingestion donnent le même agrégat")
    void t11() {
        LearningEvidence a = serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1",
                T0.minus(Duration.ofDays(30)));
        LearningEvidence b = serie(SkillSection.CO, TargetLevel.A2, 17, 20, 4, "S2",
                T0.minus(Duration.ofDays(10)));
        LearningEvidence c = serie(SkillSection.CO, TargetLevel.A2, 12, 20, 4, "S3", T0);

        ProgressionSnapshot reference = engine.project(CO_A2, List.of(a, b, c), T0);

        for (List<LearningEvidence> permutation : permutations(List.of(a, b, c))) {
            ProgressionSnapshot autre = engine.project(CO_A2, permutation, T0);
            assertThat(autre.sumWeightEpoch())
                    .isCloseTo(reference.sumWeightEpoch(), within(EPS_AGGREGATE));
            assertThat(autre.sumWeightedResultEpoch())
                    .isCloseTo(reference.sumWeightedResultEpoch(), within(EPS_AGGREGATE));
            assertThat(autre.masteryScore())
                    .isCloseTo(reference.masteryScore(), within(EPS_AGGREGATE));
            assertThat(autre.confidence())
                    .isCloseTo(reference.confidence(), within(EPS_AGGREGATE));
            assertThat(autre.status()).isEqualTo(reference.status());
        }
    }

    @Test
    @DisplayName("T12 — la même clé naturelle deux fois ne double pas l'agrégat")
    void t12() {
        LearningEvidence preuve = serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0);
        LearningEvidence retry = preuve.toBuilder().id(null).ingestedAt(T0.plusSeconds(3)).build();

        assertThat(retry.naturalKey()).isEqualTo(preuve.naturalKey());

        ProgressionSnapshot une = engine.project(CO_A2, List.of(preuve), T0);
        ProgressionSnapshot deux = engine.project(CO_A2, List.of(preuve, retry), T0);

        assertThat(deux.sumWeightEpoch())
                .isCloseTo(une.sumWeightEpoch(), within(EPS_AGGREGATE));
        assertThat(deux.masteryScore()).isCloseTo(une.masteryScore(), within(EPS_AGGREGATE));
    }

    /* --------------------------------------------- T13–T17 : prérequis dérivés */

    @Nested
    @DisplayName("Prérequis dérivés — sans jamais fabriquer de preuve inférieure")
    class Prerequis {

        @Test
        @DisplayName("T13 — B1 directement SOLID satisfait A2 sans fausse preuve")
        void t13() {
            List<LearningEvidence> preuves = deuxSeriesQualifiantes(TargetLevel.B1);

            DomainProjection co = engine.projectDomain(
                    SkillSection.CO, TargetLevel.B2, preuves, T0);

            assertThat(engine.project(CO_B1, preuves, T0).directQualification()).isTrue();
            assertThat(co.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, true);
            assertThat(co.prerequisiteSatisfiedByLevel())
                    .containsEntry(TargetLevel.A2, TargetLevel.B1);
            assertThat(preuves).noneMatch(preuve -> preuve.level() == TargetLevel.A2);
        }

        @Test
        @DisplayName("T14 — la transitivité descend de B2 jusqu'à A2")
        void t14() {
            List<LearningEvidence> preuves = deuxSeriesQualifiantes(TargetLevel.B2);

            DomainProjection co = engine.projectDomain(
                    SkillSection.CO, TargetLevel.B2, preuves, T0);

            assertThat(co.prerequisiteSatisfied())
                    .containsEntry(TargetLevel.B1, true)
                    .containsEntry(TargetLevel.A2, true);
        }

        @Test
        @DisplayName("T15 — un niveau seulement satisfait ne satisfait rien à son tour")
        void t15() {
            List<LearningEvidence> preuves = deuxSeriesQualifiantes(TargetLevel.B2);

            DomainProjection co = engine.projectDomain(
                    SkillSection.CO, TargetLevel.B2, preuves, T0);

            assertThat(engine.project(CO_B1, preuves, T0).directQualification()).isFalse();
            assertThat(co.prerequisiteSatisfiedByLevel())
                    .containsEntry(TargetLevel.A2, TargetLevel.B2)
                    .containsEntry(TargetLevel.B1, TargetLevel.B2);
        }

        @Test
        @DisplayName("T16 — le prérequis est révoqué dès que B1 passe en WATCH")
        void t16() {
            List<LearningEvidence> preuves = new ArrayList<>(
                    deuxSeriesQualifiantes(TargetLevel.B1));
            preuves.add(examenEpreuve(SkillSection.CO, TargetLevel.B1, 0.20d, "MOCK-KO",
                    T0.plus(Duration.ofDays(1))));
            Instant apres = T0.plus(Duration.ofDays(2));

            ProgressionSnapshot b1 = engine.project(CO_B1, preuves, apres);
            DomainProjection co = engine.projectDomain(
                    SkillSection.CO, TargetLevel.B2, preuves, apres);

            assertThat(b1.status()).isEqualTo(ProgressionStatus.WATCH);
            assertThat(co.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, false);
            assertThat(co.prescriptionLevel()).isEqualTo(TargetLevel.B1);
        }

        @Test
        @DisplayName("T17 — une mauvaise preuve B2 ne dégrade ni A2 ni B1")
        void t17() {
            List<LearningEvidence> preuves = new ArrayList<>(
                    deuxSeriesQualifiantes(TargetLevel.A2));
            preuves.add(examenEpreuve(SkillSection.CO, TargetLevel.B2, 0.10d, "MOCK-B2", T0));

            assertThat(engine.project(CO_A2, preuves, T0).status())
                    .isEqualTo(ProgressionStatus.SOLID);
            assertThat(engine.project(CO_B1, preuves, T0).hasNoDirectEvidence()).isTrue();
            assertThat(preuves).filteredOn(preuve -> preuve.result() < 0.25d)
                    .allMatch(preuve -> preuve.level() == TargetLevel.B2);
        }
    }

    /* ------------------------------------------------ T18–T19 : contradictions */

    @Test
    @DisplayName("T18 — la première contradiction forte met en WATCH, jamais à zéro")
    void t18() {
        List<LearningEvidence> preuves = new ArrayList<>(deuxSeriesQualifiantes(TargetLevel.A2));
        double avant = engine.project(CO_A2, preuves, T0).masteryScore();
        preuves.add(examenEpreuve(SkillSection.CO, TargetLevel.A2, 0.20d, "MOCK-KO",
                T0.plus(Duration.ofDays(1))));

        ProgressionSnapshot apres = engine.project(CO_A2, preuves, T0.plus(Duration.ofDays(1)));

        assertThat(apres.status()).isEqualTo(ProgressionStatus.WATCH);
        assertThat(apres.masteryScore()).isNotNull().isLessThan(avant).isGreaterThan(0.0d);
        assertThat(apres.sumWeightEpoch()).isGreaterThan(0.0d);
    }

    @Test
    @DisplayName("T19 — la deuxième contradiction indépendante peut faire sortir de WATCH")
    void t19() {
        List<LearningEvidence> preuves = new ArrayList<>(deuxSeriesQualifiantes(TargetLevel.A2));
        preuves.add(examenEpreuve(SkillSection.CO, TargetLevel.A2, 0.20d, "MOCK-KO-1",
                T0.plus(Duration.ofDays(1))));
        preuves.add(examenEpreuve(SkillSection.CO, TargetLevel.A2, 0.15d, "MOCK-KO-2",
                T0.plus(Duration.ofDays(5))));
        Instant apres = T0.plus(Duration.ofDays(6));

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, apres);

        assertThat(etat.recentStrongNegativeCount()).isGreaterThanOrEqualTo(2);
        assertThat(etat.status())
                .isIn(ProgressionStatus.PROGRESSING, ProgressionStatus.FRAGILE);
    }

    /* --------------------------------------------------- T20–T24 : EE/EO, isolation */

    @Test
    @DisplayName("T20 — vingt micro-sujets parfaits ne rendent jamais SOLID")
    void t20() {
        List<LearningEvidence> preuves = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            preuves.add(microSujet(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d,
                    "MICRO-" + i, T0));
        }

        ProgressionSnapshot etat = engine.project(EE_SKILL, preuves, T0);

        assertThat(etat.masteryScore()).isCloseTo(1.0d, within(EPS));
        assertThat(etat.transferGate()).isFalse();
        assertThat(etat.status()).isNotEqualTo(ProgressionStatus.SOLID);
        assertThat(etat.microSumWeightEpoch()).isGreaterThan(0.80d);
        assertThat(etat.confidence()).isLessThan(0.60d);
    }

    @Test
    @DisplayName("T21 — les micro-sujets peuvent rendre prêt à vérifier")
    void t21() {
        List<LearningEvidence> preuves = List.of(
                microSujet(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "M1", T0),
                microSujet(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "M2", T0),
                microSujet(SkillSection.EE, EE_CONNECTEURS, 0.5d, 0.90d, "M3", T0),
                microSujet(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "M4", T0));

        ProgressionSnapshot etat = engine.project(EE_SKILL, preuves, T0);

        assertThat(etat.masteryScore()).isGreaterThanOrEqualTo(0.70d);
        assertThat(etat.confidence()).isGreaterThanOrEqualTo(0.50d);
        assertThat(etat.transferGate()).isFalse();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.READY_FOR_REASSESSMENT);
    }

    @Test
    @DisplayName("T22 — deux vraies tâches suffisent, sans imposer les micro-sujets")
    void t22() {
        List<LearningEvidence> preuves = List.of(
                vraieTache(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "TACHE-1", T0),
                vraieTache(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "TACHE-2", T0));

        ProgressionSnapshot etat = engine.project(EE_SKILL, preuves, T0);

        assertThat(preuves).noneMatch(p -> p.sourceType() == EvidenceSourceType.MICRO_SKILL);
        assertThat(etat.transferGate()).isTrue();
        assertThat(etat.masteryScore()).isGreaterThanOrEqualTo(0.75d);
        assertThat(etat.confidence()).isGreaterThanOrEqualTo(0.60d);
        assertThat(etat.status()).isEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T23 — un examen blanc EE n'affecte ni CO, ni CE, ni EO")
    void t23() {
        List<LearningEvidence> preuves = List.of(
                vraieTache(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "TACHE-1", T0));

        assertThat(engine.project(CO_A2, preuves, T0).hasNoDirectEvidence()).isTrue();
        assertThat(engine.project(CE_B1, preuves, T0).hasNoDirectEvidence()).isTrue();
        assertThat(engine.project(
                ProgressionStateKey.productive(SkillSection.EO, "EO_FLUIDITE_B1"), preuves, T0)
                .hasNoDirectEvidence()).isTrue();
    }

    @Test
    @DisplayName("T24 — le point d'entrée ne change jamais la valeur pédagogique")
    void t24() {
        LearningEvidence depuisPlan = serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0);
        LearningEvidence depuisReviser = depuisPlan.toBuilder()
                .entryPoint(EvidenceEntryPoint.REVISER).build();

        assertThat(engine.baseEffectiveWeight(depuisReviser))
                .isCloseTo(engine.baseEffectiveWeight(depuisPlan), within(EPS_AGGREGATE));
        assertThat(engine.project(CO_A2, List.of(depuisReviser), T0).masteryScore())
                .isCloseTo(engine.project(CO_A2, List.of(depuisPlan), T0).masteryScore(),
                        within(EPS_AGGREGATE));
    }

    /* --------------------------------------- T25–T29 : progression visible, cycles */

    @Test
    @DisplayName("T25 — la progression visible ne baisse pas dans un cycle")
    void t25() {
        List<LearningEvidence> bonnes = List.of(
                serie(SkillSection.CO, TargetLevel.A2, 16, 20, 4, "S1", T0));
        int avant = engine.project(CO_A2, bonnes, T0).visibleProgress();

        List<LearningEvidence> avecMauvaise = List.of(
                bonnes.getFirst(),
                serie(SkillSection.CO, TargetLevel.A2, 5, 20, 4, "S2",
                        T0.plus(Duration.ofDays(1))));
        int apres = engine.project(CO_A2, avecMauvaise, T0.plus(Duration.ofDays(1)))
                .visibleProgress();

        assertThat(apres).isGreaterThanOrEqualTo(avant);
    }

    @Test
    @DisplayName("T26 — la progression visible est plafonnée à 95 avant confirmation")
    void t26() {
        List<LearningEvidence> preuves = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            preuves.add(serieNonCalibree(SkillSection.CO, TargetLevel.A2, 20, 20, 4,
                    "S" + i, T0));
        }

        ProgressionSnapshot etat = engine.project(CO_A2, preuves, T0);

        assertThat(etat.status()).isNotEqualTo(ProgressionStatus.SOLID);
        assertThat(etat.visibleProgress()).isLessThanOrEqualTo(95);
    }

    @Test
    @DisplayName("T27 — une confirmation directe vaut 100")
    void t27() {
        assertThat(engine.project(CO_A2, deuxSeriesQualifiantes(TargetLevel.A2), T0)
                .visibleProgress()).isEqualTo(100);
    }

    @Test
    @DisplayName("T28 — le niveau suivant démarre un nouveau cycle à zéro")
    void t28() {
        List<LearningEvidence> preuves = deuxSeriesQualifiantes(TargetLevel.A2);

        ProgressionSnapshot a2 = engine.project(CO_A2, preuves, T0);
        ProgressionSnapshot b1 = engine.project(CO_B1, preuves, T0);

        assertThat(a2.levelCycleId()).isNotEqualTo(b1.levelCycleId());
        assertThat(a2.visibleProgress()).isEqualTo(100);
        assertThat(b1.visibleProgress()).isNull();
    }

    @Test
    @DisplayName("T29 — un domaine inconnu reste NOT_EVALUATED, aucun niveau inventé")
    void t29() {
        ProgressionSnapshot etat = engine.project(CO_B2, List.of(), T0);

        assertThat(etat.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(etat.masteryScore()).isNull();
        assertThat(etat.visibleProgress()).isNull();
    }

    /* ------------------------------------------------------ T30–T32 : sticky, shadow */

    @Test
    @DisplayName("T30 — une reco sticky tombe quand une activité hors Plan la rend inutile")
    void t30() {
        List<LearningEvidence> preuves = List.of(
                vraieTache(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "T1", T0),
                vraieTache(SkillSection.EE, EE_CONNECTEURS, 1.0d, 0.90d, "T2", T0));

        assertThat(engine.project(EE_SKILL, preuves, T0).status())
                .isEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T31 — une prédiction shadow garde les valeurs de son predictedAt")
    void t31() {
        List<LearningEvidence> preuves = deuxSeriesQualifiantes(TargetLevel.A2);

        ProgressionSnapshot auMomentDeLaPrediction = engine.project(CO_A2, preuves, T0);
        ProgressionSnapshot bienPlusTard =
                engine.project(CO_A2, preuves, T0.plus(Duration.ofDays(120)));

        assertThat(auMomentDeLaPrediction.confidence())
                .isGreaterThan(bienPlusTard.confidence());
        assertThat(auMomentDeLaPrediction.masteryScore())
                .isCloseTo(bienPlusTard.masteryScore(), within(EPS_AGGREGATE));
    }

    @Test
    @DisplayName("T32 — seul un mock du même stateKey dans les 30 jours est rattaché")
    void t32() {
        LearningEvidence dansLaFenetre = examenEpreuve(SkillSection.CO, TargetLevel.A2,
                0.80d, "MOCK-J20", T0.plus(Duration.ofDays(20)));
        LearningEvidence horsFenetre = examenEpreuve(SkillSection.CO, TargetLevel.A2,
                0.80d, "MOCK-J40", T0.plus(Duration.ofDays(40)));

        assertThat(Duration.between(T0, dansLaFenetre.occurredAt()).toDays())
                .isLessThanOrEqualTo(30);
        assertThat(Duration.between(T0, horsFenetre.occurredAt()).toDays())
                .isGreaterThan(30);
    }

    /* -------------------------------------- T33–T35 : null, recouvrement, relance */

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>C'est la confusion {@code null}/{@code 0} qui a produit les faux
     * {@code A1_NON_ATTEINT} de V040–V042. Un candidat dont A2 n'a jamais ete
     * mesure directement n'a pas regresse quand B1 tombe en WATCH : il n'a
     * simplement jamais ete mesure. Afficher {@code A2 — 0 %} lui ment.
     */
    @Test
    @DisplayName("T33 — un niveau sans preuve directe vaut null, jamais 0 %")
    void t33() {
        List<LearningEvidence> qualifiantes = deuxSeriesQualifiantes(TargetLevel.B1);

        ProgressionSnapshot a2 = engine.project(CO_A2, qualifiantes, T0);
        DomainProjection co = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, qualifiantes, T0);

        assertThat(a2.sumWeightEpoch()).isZero();
        assertThat(a2.masteryScore()).isNull();
        assertThat(a2.visibleProgress()).isNull();
        assertThat(co.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, true);
        assertThat(co.prerequisiteSatisfiedByLevel())
                .containsEntry(TargetLevel.A2, TargetLevel.B1);
        assertThat(co.activeLearningLevel()).isEqualTo(TargetLevel.B2);

        List<LearningEvidence> avecContradictions = new ArrayList<>(qualifiantes);
        avecContradictions.add(examenEpreuve(SkillSection.CO, TargetLevel.B1, 0.20d,
                "MOCK-KO-1", T0.plus(Duration.ofDays(1))));
        avecContradictions.add(examenEpreuve(SkillSection.CO, TargetLevel.B1, 0.15d,
                "MOCK-KO-2", T0.plus(Duration.ofDays(3))));
        Instant apres = T0.plus(Duration.ofDays(4));

        ProgressionSnapshot a2Apres = engine.project(CO_A2, avecContradictions, apres);
        DomainProjection coApres = engine.projectDomain(
                SkillSection.CO, TargetLevel.B2, avecContradictions, apres);

        assertThat(coApres.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, false);
        assertThat(a2Apres.visibleProgress()).isNull();
        assertThat(a2Apres.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(coApres.prescriptionLevel()).isEqualTo(TargetLevel.B1);
    }

    @Test
    @DisplayName("T34 — un recouvrement d'items ≥ 0,50 ne donne pas une 2e preuve qualifiante")
    void t34() {
        List<String> q1a20 = questions(1, 20);
        List<String> chevauchante = new ArrayList<>(questions(1, 14));
        chevauchante.addAll(questions(21, 26));
        List<String> disjointe = questions(31, 50);

        LearningEvidence s1 = serieAvecQuestions(q1a20, 16, IndependenceClass.NEW_CONTENT, T0);
        LearningEvidence s2 = serieAvecQuestions(chevauchante, 17,
                IndependenceClass.NEW_CONTENT_SAME_BLUEPRINT, T0.plus(Duration.ofDays(1)));

        assertThat(s1.contentId()).isNotEqualTo(s2.contentId());
        assertThat(s2.independenceClass())
                .isEqualTo(IndependenceClass.NEW_CONTENT_SAME_BLUEPRINT);
        ProgressionSnapshot deuxSeries = engine.project(CO_A2, List.of(s1, s2), T0);
        assertThat(deuxSeries.qualificationGate()).isFalse();
        assertThat(deuxSeries.status()).isNotEqualTo(ProgressionStatus.SOLID);

        LearningEvidence s3 = serieAvecQuestions(disjointe, 16,
                IndependenceClass.NEW_CONTENT, T0.plus(Duration.ofDays(2)));
        ProgressionSnapshot troisSeries = engine.project(
                CO_A2, List.of(s1, s2, s3), T0.plus(Duration.ofDays(2)));

        assertThat(troisSeries.qualificationGate()).isTrue();
        assertThat(troisSeries.status()).isEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T35 — relancer la série identique ne verrouille jamais")
    void t35() {
        List<String> memes = questions(1, 20);
        LearningEvidence s1 = serieAvecQuestions(memes, 16, IndependenceClass.NEW_CONTENT, T0);
        LearningEvidence s2 = serieAvecQuestions(memes, 20,
                IndependenceClass.REPEATED_EXACT_CONTENT, T0.plus(Duration.ofDays(1)));
        LearningEvidence s3 = serieAvecQuestions(memes, 20,
                IndependenceClass.REPEATED_EXACT_CONTENT, T0.plus(Duration.ofDays(2)));

        assertThat(s1.contentId()).isEqualTo(s2.contentId()).isEqualTo(s3.contentId());
        ProgressionSnapshot etat = engine.project(
                CO_A2, List.of(s1, s2, s3), T0.plus(Duration.ofDays(2)));

        assertThat(etat.qualificationGate()).isFalse();
        assertThat(etat.status()).isNotEqualTo(ProgressionStatus.SOLID);
    }

    /*
     * T36 — conformite front. Ce test-la n'est pas ici : il porte sur du code
     * TypeScript et Dart, et le depot n'accepte aucun test sur les fronts
     * (CLAUDE.md racine). Il vit en verificateur statique autonome :
     *
     *     node scripts/verifier-contrat-front-progression.mjs
     *
     * Voir docs/regles/progression.md, section « T36 ».
     */

    /* --------------------------------------------------------------- helpers */

    private static List<LearningEvidence> deuxSeriesQualifiantes(TargetLevel level) {
        return List.of(
                serie(SkillSection.CO, level, 16, 20, 4, "QUALIF-1-" + level, T0),
                serie(SkillSection.CO, level, 17, 20, 4, "QUALIF-2-" + level, T0));
    }

    private static LearningEvidence serieAvecQuestions(List<String> questionIds, int correct,
                                                       IndependenceClass independence,
                                                       Instant occurredAt) {
        return serie(SkillSection.CO, TargetLevel.A2, correct, 20, 4,
                EvidenceFixtures.contentIdDeSerie(questionIds), occurredAt)
                .toBuilder()
                .independenceClass(independence)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .assistanceLevel(AssistanceLevel.NONE)
                .build();
    }

    private static List<String> questions(int from, int to) {
        List<String> ids = new ArrayList<>();
        for (int i = from; i <= to; i++) {
            ids.add("Q" + i);
        }
        return ids;
    }

    /** Les six ordres d'ingestion possibles de trois preuves (T11). */
    private static List<List<LearningEvidence>> permutations(Collection<LearningEvidence> items) {
        List<LearningEvidence> source = List.copyOf(items);
        List<List<LearningEvidence>> out = new ArrayList<>();
        for (int i = 0; i < source.size(); i++) {
            for (int j = 0; j < source.size(); j++) {
                for (int k = 0; k < source.size(); k++) {
                    if (i != j && j != k && i != k) {
                        out.add(List.of(source.get(i), source.get(j), source.get(k)));
                    }
                }
            }
        }
        return out;
    }
}
