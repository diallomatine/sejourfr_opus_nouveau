package com.sejourfr.app.progression;

import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.config.ProgressionConfigLoader;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.ProgressionStateType;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * <b>Verrouille {@code progression-config-v1.json} valeur par valeur.</b>
 *
 * <p>Ce n'est pas un test de plomberie Jackson : c'est le filet qui rend
 * l'invariant I33 opposable. Chacun de ces nombres a un cout produit derriere
 * lui, et le seul chemin autorise pour en changer un est un <b>nouveau
 * fichier</b> {@code progression-config-v2.json} + {@code engineVersion 2} +
 * replay controle (§4, §29, §50). Un ajustement discret « pour faire passer un
 * test » casse ici, et c'est exactement l'intention.
 */
class ProgressionConfigTest {

    private static final ProgressionConfig CONFIG = ProgressionConfigLoader.load(1);

    @Test
    @DisplayName("La v1 déclare l'epoch et la demi-vie normatives")
    void epochEtDemiVie() {
        assertThat(CONFIG.engineVersion()).isEqualTo(1);
        assertThat(CONFIG.weightEpoch()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(CONFIG.recencyHalfLifeDays()).isEqualTo(45.0d);
        assertThat(CONFIG.lambda()).isCloseTo(Math.log(2) / 45, within(1e-12));
    }

    @Test
    @DisplayName("Les poids de source sont ceux de §4, aux huit valeurs près")
    void poidsDeSource() {
        assertThat(CONFIG.sourceWeights())
                .containsEntry(EvidenceSourceType.FULL_MOCK_EXAM, 1.00d)
                .containsEntry(EvidenceSourceType.DOMAIN_MOCK, 0.95d)
                .containsEntry(EvidenceSourceType.FULL_TASK, 0.80d)
                .containsEntry(EvidenceSourceType.REASSESSMENT, 0.85d)
                .containsEntry(EvidenceSourceType.DIAGNOSTIC, 0.70d)
                .containsEntry(EvidenceSourceType.CO_CE_20_SERIES, 0.70d)
                .containsEntry(EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED, 0.50d)
                .containsEntry(EvidenceSourceType.MICRO_SKILL, 0.35d)
                .hasSize(EvidenceSourceType.values().length);
    }

    @Test
    @DisplayName("L'assistance et l'indépendance pèsent réellement, sans plancher")
    void assistanceEtIndependance() {
        assertThat(CONFIG.assistanceFactors())
                .containsEntry(AssistanceLevel.NONE, 1.00d)
                .containsEntry(AssistanceLevel.LIGHT, 0.85d)
                .containsEntry(AssistanceLevel.HEAVY, 0.60d)
                .containsEntry(AssistanceLevel.ANSWER_OR_MODEL_SEEN_BEFORE_SUBMISSION, 0.45d);
        assertThat(CONFIG.independenceFactors())
                .containsEntry(IndependenceClass.NEW_CONTENT, 1.00d)
                .containsEntry(IndependenceClass.NEW_CONTENT_SAME_BLUEPRINT, 0.90d)
                .containsEntry(IndependenceClass.REPEATED_EXACT_CONTENT, 0.50d);
        assertThat(CONFIG.independence().overlapWindowDays()).isEqualTo(60);
        assertThat(CONFIG.independence().independenceOverlapThreshold()).isEqualTo(0.50d);
    }

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>CO/CE agrege un {@code result} corrige du hasard, EE/EO des
     * observations IA {@code 0 / 0.5 / 1}. Les deux echelles n'ont pas de
     * commune mesure, et reutiliser silencieusement un profil pour l'autre est
     * la faute la plus facile a commettre et la plus dure a voir (§4, I14).
     */
    @Test
    @DisplayName("Les deux profils de seuils sont distincts et ne se confondent pas")
    void profilsDistincts() {
        ProgressionConfig.ReceptiveThresholds receptif = CONFIG.thresholds().receptiveLevel();
        ProgressionConfig.ProductiveThresholds productif = CONFIG.thresholds().productiveSkill();

        assertThat(receptif.fragileMax()).isEqualTo(0.35d);
        assertThat(receptif.progressIn()).isEqualTo(0.50d);
        assertThat(receptif.progressOut()).isEqualTo(0.40d);
        assertThat(receptif.solidIn()).isEqualTo(0.70d);
        assertThat(receptif.solidOut()).isEqualTo(0.55d);
        assertThat(receptif.minConfidenceForProgress()).isEqualTo(0.35d);
        assertThat(receptif.minConfidenceForSolid()).isEqualTo(0.60d);

        assertThat(productif.fragileMax()).isEqualTo(0.45d);
        assertThat(productif.progressIn()).isEqualTo(0.55d);
        assertThat(productif.progressOut()).isEqualTo(0.45d);
        assertThat(productif.readyForReassessment()).isEqualTo(0.70d);
        assertThat(productif.solidIn()).isEqualTo(0.75d);
        assertThat(productif.solidOut()).isEqualTo(0.60d);
        assertThat(productif.minConfidenceForReady()).isEqualTo(0.50d);
        assertThat(productif.minConfidenceForSolid()).isEqualTo(0.60d);

        assertThat(receptif.solidIn()).isNotEqualTo(productif.solidIn());
        assertThat(CONFIG.thresholdProfile(ProgressionStateType.RECEPTIVE_LEVEL))
                .isSameAs(receptif);
        assertThat(CONFIG.thresholdProfile(ProgressionStateType.PRODUCTIVE_SKILL))
                .isSameAs(productif);
    }

    @Test
    @DisplayName("Les K de confiance diffèrent par type d'état")
    void confianceK() {
        assertThat(CONFIG.confidenceK())
                .containsEntry(ProgressionStateType.RECEPTIVE_LEVEL, 1.50d)
                .containsEntry(ProgressionStateType.PRODUCTIVE_SKILL, 1.60d);
    }

    @Test
    @DisplayName("Les preuves fortes ont leurs seuils et leur fenêtre de 30 jours")
    void preuvesFortes() {
        ProgressionConfig.StrongEvidence receptif =
                CONFIG.strongEvidence().get(ProgressionStateType.RECEPTIVE_LEVEL);
        ProgressionConfig.StrongEvidence productif =
                CONFIG.strongEvidence().get(ProgressionStateType.PRODUCTIVE_SKILL);

        assertThat(receptif.positiveResult()).isEqualTo(0.80d);
        assertThat(receptif.negativeResult()).isEqualTo(0.25d);
        assertThat(receptif.windowDays()).isEqualTo(30);
        assertThat(receptif.negativeCountToDowngradeSolid()).isEqualTo(2);

        assertThat(productif.positiveResult()).isEqualTo(0.85d);
        assertThat(productif.negativeResult()).isEqualTo(0.40d);
        assertThat(productif.windowDays()).isEqualTo(30);
        assertThat(productif.negativeCountToDowngradeSolid()).isEqualTo(2);
    }

    @Test
    @DisplayName("Les gates et le cap micro sont ceux de §16, §17 et §11.1")
    void gatesEtCapMicro() {
        assertThat(CONFIG.qualificationGates().receptiveLevel().mockStrongResult())
                .isEqualTo(0.80d);
        assertThat(CONFIG.qualificationGates().receptiveLevel().seriesPositiveResult())
                .isEqualTo(0.70d);
        assertThat(CONFIG.qualificationGates().receptiveLevel().diagnosticPositiveResult())
                .isEqualTo(0.70d);
        assertThat(CONFIG.qualificationGates().receptiveLevel().confirmationPositiveResult())
                .isEqualTo(0.70d);
        assertThat(CONFIG.qualificationGates().productiveSkill().transferResult())
                .isEqualTo(0.75d);
        assertThat(CONFIG.microEvidenceCaps().maxConfidenceMass()).isEqualTo(0.80d);
    }

    @Test
    @DisplayName("La progression visible est plafonnée à 95 avant confirmation")
    void progressionVisible() {
        ProgressionConfig.VisibleProgress visible = CONFIG.visibleProgress();
        assertThat(visible.coverageWeight()).isEqualTo(0.55d);
        assertThat(visible.masteryWeight()).isEqualTo(0.45d);
        assertThat(visible.coverageWeight() + visible.masteryWeight()).isEqualTo(1.0d);
        assertThat(visible.unconfirmedCap()).isEqualTo(95);
        assertThat(visible.practicePointsRequired()).isEqualTo(3.0d);
        assertThat(visible.practicePoints())
                .containsEntry(EvidenceSourceType.FULL_MOCK_EXAM, 1.50d)
                .containsEntry(EvidenceSourceType.DOMAIN_MOCK, 1.50d)
                .containsEntry(EvidenceSourceType.FULL_TASK, 1.20d)
                .containsEntry(EvidenceSourceType.REASSESSMENT, 1.20d)
                .containsEntry(EvidenceSourceType.DIAGNOSTIC, 0.80d)
                .containsEntry(EvidenceSourceType.CO_CE_20_SERIES, 1.00d)
                .containsEntry(EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED, 0.75d)
                .containsEntry(EvidenceSourceType.MICRO_SKILL, 0.40d);
    }

    @Test
    @DisplayName("Le blueprint reste 6 / 10 / 4 sur 20 questions")
    void blueprint() {
        ProgressionConfig.ReceptiveSeriesBlueprint blueprint = CONFIG.receptiveSeriesBlueprint();
        assertThat(blueprint.questionCount()).isEqualTo(20);
        assertThat(blueprint.easy()).isEqualTo(6);
        assertThat(blueprint.medium()).isEqualTo(10);
        assertThat(blueprint.hard()).isEqualTo(4);
    }

    @Test
    @DisplayName("Le shadow mode a son objectif, sa fenêtre ET son effectif minimum")
    void shadowEtMaintenance() {
        assertThat(CONFIG.shadowValidation().predictionWindowDays()).isEqualTo(30);
        assertThat(CONFIG.shadowValidation().minSolidPrecision()).isEqualTo(0.70d);
        // 0,70 sur quatre issues n'est pas une validation, c'est un chiffre.
        assertThat(CONFIG.shadowValidation().minOutcomeCount()).isEqualTo(30);
        assertThat(CONFIG.maintenance().maxEpochAgeDays()).isEqualTo(1095);
    }

    /**
     * 🛑 Ces quatre valeurs multiplient directement {@code baseEffectiveWeight}.
     *
     * <p>Elles ont vécu en constantes Java jusqu'au 2026-08-23 : les changer ne
     * bumpait alors ni {@code engineVersion} ni le replay, et deux campagnes
     * shadow séparées par une telle édition n'auraient plus été comparables sans
     * que rien ne le signale. Elles sont ici pour que ce soit impossible.
     */
    @Test
    @DisplayName("La notation IA est en config, valeur par valeur")
    void notationIa() {
        ProgressionConfig.AiScoring aiScoring = CONFIG.aiScoring();
        assertThat(aiScoring.confidenceMapping())
                .containsEntry(ObservationConfidence.LOW, 0.50d)
                .containsEntry(ObservationConfidence.MEDIUM, 0.75d)
                .containsEntry(ObservationConfidence.HIGH, 0.95d)
                .hasSize(ObservationConfidence.values().length);
        // Une évaluation IA n'est jamais une certitude : HIGH ne vaut pas 1,00.
        assertThat(aiScoring.confidenceMapping().get(ObservationConfidence.HIGH))
                .isLessThan(1.0d);
        assertThat(aiScoring.microSkillAssistance()).isEqualTo(AssistanceLevel.LIGHT);
        assertThat(aiScoring.microSkillScoringConfidence()).isEqualTo(0.75d);
    }

    /**
     * §25 bis.3 : une UI qui ne gererait que quatre etats est non conforme.
     * {@code WATCH} et {@code READY_FOR_REASSESSMENT} sont precisement ceux qui
     * portent la valeur pedagogique du produit, et ce sont les premiers qu'on
     * perd en recopiant un ancien vocabulaire.
     */
    @Test
    @DisplayName("Les six états servent leur libellé et leur ton, aucun n'en manque")
    void sixEtatsLibellesEtTons() {
        assertThat(ProgressionStatus.values()).hasSize(6);
        assertThat(ProgressionStatus.NOT_EVALUATED.getLabel()).isEqualTo("À évaluer");
        assertThat(ProgressionStatus.FRAGILE.getLabel()).isEqualTo("À renforcer");
        assertThat(ProgressionStatus.PROGRESSING.getLabel()).isEqualTo("En progression");
        assertThat(ProgressionStatus.READY_FOR_REASSESSMENT.getLabel())
                .isEqualTo("Prêt à vérifier");
        assertThat(ProgressionStatus.SOLID.getLabel()).isEqualTo("Acquis");
        assertThat(ProgressionStatus.WATCH.getLabel()).isEqualTo("À vérifier");

        assertThat(ProgressionStatus.NOT_EVALUATED.getTone()).isEqualTo("neutral");
        assertThat(ProgressionStatus.FRAGILE.getTone()).isEqualTo("danger");
        assertThat(ProgressionStatus.PROGRESSING.getTone()).isEqualTo("primary");
        assertThat(ProgressionStatus.READY_FOR_REASSESSMENT.getTone()).isEqualTo("accent");
        assertThat(ProgressionStatus.SOLID.getTone()).isEqualTo("success");
        assertThat(ProgressionStatus.WATCH.getTone()).isEqualTo("warn");
    }
}
