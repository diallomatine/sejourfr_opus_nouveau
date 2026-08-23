package com.sejourfr.app.progression;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionEngineMode;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import com.sejourfr.app.progression.manager.ProgressionPredictionManager;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ProgressionShadowService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * <b>Le shadow mode et T32</b> (V4.2 §47).
 *
 * <p>Ce qui se vérifie ici est la seule chose qui autorisera un jour le passage
 * en {@code ACTIVE} : le moteur note ce qu'il croit, on rattache ce qui s'est
 * réellement passé, et on mesure. Tant que ce n'est pas fait, les seuils de
 * {@code progression-config-v1.json} restent des hypothèses produit.
 */
class ProgressionShadowServiceIT extends AbstractIntegrationTest {

    @Autowired ProgressionIngestionService ingestionService;
    @Autowired ProgressionShadowService shadowService;
    @Autowired ProgressionPredictionManager predictionManager;
    @Autowired ProgressionProperties properties;
    @Autowired TestData data;

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");

    /**
     * §47 — <b>le moteur démarre en SHADOW et n'en sort pas tout seul.</b>
     *
     * <p>Le défaut n'est pas un détail de configuration : c'est ce qui garantit
     * qu'aucun candidat ne verra un Plan calculé sur des seuils qui n'ont pas
     * encore été confrontés à de vraies données.
     */
    @Test
    @DisplayName("Le moteur ne pilote pas le Plan tant qu'il est en SHADOW")
    void shadowParDefaut() {
        assertThat(properties.getMode()).isEqualTo(ProgressionEngineMode.SHADOW);
        assertThat(shadowService.piloteLePlan()).isFalse();
    }

    @Test
    @DisplayName("Une transition vers SOLID écrit une prédiction, une seule par cycle")
    void unePredictionParCycle() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), 17, "S2", T0));
        ingestionService.ingerer(serie(user.getId(), 18, "S3", T0.plus(Duration.ofDays(1))));

        List<ProgressionPredictionRecord> predictions =
                predictionManager.pourUtilisateur(user.getId());

        assertThat(predictions).hasSize(1);
        ProgressionPredictionRecord prediction = predictions.getFirst();
        assertThat(prediction.getStatus()).isEqualTo(ProgressionStatus.SOLID);
        assertThat(prediction.getStateKey()).isEqualTo("CO:A2");
        assertThat(prediction.isDirectQualification()).isTrue();
        assertThat(prediction.getOutcomeAt()).isNull();
    }

    /**
     * 🛑 Le test le plus important du fichier — T32.
     *
     * <p>Le <b>premier</b> examen dans les 30 jours, et lui seul. Prendre le
     * meilleur examen des six mois suivants mesurerait la persévérance du
     * candidat, pas la justesse de la prédiction.
     */
    @Test
    @DisplayName("T32 — seul le premier examen du même palier, dans les 30 jours, est rattaché")
    void rattachementDansLaFenetre() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), 17, "S2", T0));

        Instant predite = antidater(user.getId(), 40);
        Instant maintenant = Instant.now();

        // Un examen APRÈS la fenêtre de 30 jours d'abord : il ne doit rien
        // déclencher, même excellent.
        ingestionService.ingerer(examen(user.getId(), 0.90d, "MOCK-TARD",
                predite.plus(Duration.ofDays(35))));
        assertThat(shadowService.rattacherResultats(maintenant)).isZero();

        // Puis un examen dans la fenêtre.
        Instant dansLaFenetre = predite.plus(Duration.ofDays(10));
        ingestionService.ingerer(examen(user.getId(), 0.82d, "MOCK-TOT", dansLaFenetre));
        assertThat(shadowService.rattacherResultats(maintenant)).isEqualTo(1);

        ProgressionPredictionRecord rattachee =
                predictionManager.pourUtilisateur(user.getId()).getFirst();
        assertThat(rattachee.getOutcomeResult()).isCloseTo(0.82d, within(1e-9));
        assertThat(rattachee.getOutcomeAt()).isEqualTo(dansLaFenetre);
    }

    /**
     * §47.4 — la métrique de go/no-go. Elle est vide, pas nulle, tant qu'aucune
     * prédiction n'a de résultat : <b>absence de mesure n'est pas 0 %</b>.
     */
    @Test
    @DisplayName("La précision SOLID est vide sans résultat, puis se calcule sur les rattachées")
    void precisionSolid() {
        User user = data.user();
        assertThat(shadowService.precisionSolid()).isEmpty();

        ingestionService.ingerer(serie(user.getId(), 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), 17, "S2", T0));
        Instant predite = antidater(user.getId(), 40);
        ingestionService.ingerer(examen(user.getId(), 0.82d, "MOCK",
                predite.plus(Duration.ofDays(5))));
        shadowService.rattacherResultats(Instant.now());

        assertThat(shadowService.precisionSolid()).contains(1.0d);
    }

    /**
     * Recule la prédiction dans le passé pour pouvoir dater ses examens de
     * suite <b>avant maintenant</b>.
     *
     * <p>Sans ça, le test devrait produire des preuves datées dans le futur —
     * que l'ingestion refuse, à raison (§5) : un {@code occurredAt} impossible
     * fausse le poids de la preuve et toute la récence qui en découle.
     */
    private Instant antidater(UUID userId, int jours) {
        ProgressionPredictionRecord prediction =
                predictionManager.pourUtilisateur(userId).getFirst();
        Instant recule = Instant.now().minus(Duration.ofDays(jours));
        prediction.setPredictedAt(recule);
        predictionManager.enregistrer(prediction);
        return recule;
    }

    private LearningEvidence serie(UUID userId, int correctes, String contenu, Instant quand) {
        double accuracy = correctes / 20.0d;
        return preuve(userId, EvidenceSourceType.CO_CE_20_SERIES,
                (accuracy - 0.25d) / 0.75d, contenu, quand);
    }

    private LearningEvidence examen(UUID userId, double result, String contenu, Instant quand) {
        return preuve(userId, EvidenceSourceType.DOMAIN_MOCK, result, contenu, quand);
    }

    private LearningEvidence preuve(UUID userId, EvidenceSourceType source, double result,
                                    String contenu, Instant quand) {
        return LearningEvidence.builder()
                .userId(userId)
                .attemptId(UUID.randomUUID())
                .occurredAt(quand)
                .ingestedAt(Instant.now())
                .entryPoint(EvidenceEntryPoint.REVISER)
                .sourceType(source)
                .section(SkillSection.CO)
                .level(TargetLevel.A2)
                .result(result)
                .scoringConfidence(1.0d)
                .assistanceLevel(AssistanceLevel.NONE)
                .contentId(contenu)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .independenceClass(IndependenceClass.NEW_CONTENT)
                .engineVersionAtCreation(1)
                .metadata(Map.of())
                .build();
    }
}
