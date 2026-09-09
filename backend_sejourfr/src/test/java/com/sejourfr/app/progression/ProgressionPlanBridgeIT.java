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
import com.sejourfr.app.progression.dto.ProgressionShadowReportDto;
import com.sejourfr.app.progression.dto.ProgressionStateDto;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ProgressionPlanBridge;
import com.sejourfr.app.progression.service.ProgressionReportService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>La bascule est un changement de variable d'environnement, pas de code</b>
 * (V4.2 §47, phase 2).
 *
 * <p>C'est la propriété qui compte le plus dans ce fichier : un moteur dont les
 * seuils sont encore des hypothèses produit doit pouvoir être arrêté en une
 * minute, sans déploiement.
 */
class ProgressionPlanBridgeIT extends AbstractIntegrationTest {

    @Autowired ProgressionPlanBridge bridge;
    @Autowired ProgressionIngestionService ingestionService;
    @Autowired ProgressionReportService reportService;
    @Autowired ProgressionProperties properties;
    @Autowired TestData data;

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");

    @AfterEach
    void remetEnObservation() {
        properties.setMode(ProgressionEngineMode.SHADOW);
    }

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>En SHADOW, le pont rend {@code empty()} <b>même quand le moteur a un
     * avis</b> — et le Plan garde donc sa propre règle. Le moteur enregistre et
     * prédit à côté ; aucun candidat ne voit un parcours calculé sur des seuils
     * qui n'ont pas encore été confrontés à de vraies données.
     */
    @Test
    @DisplayName("En SHADOW, le moteur ne prescrit rien, même avec un avis tranché")
    void shadowNePrescritRien() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 17, "S2", T0));

        assertThat(properties.getMode()).isEqualTo(ProgressionEngineMode.SHADOW);
        assertThat(bridge.actif()).isFalse();
        assertThat(bridge.prescriptionLevel(user.getId(), SkillSection.CO, TargetLevel.B2))
                .isEmpty();
        assertThat(bridge.domaine(user.getId(), SkillSection.CO, TargetLevel.B2)).isEmpty();
        assertThat(bridge.aUneVerificationEnAttente(
                user.getId(), SkillSection.CO, TargetLevel.B2)).isFalse();
    }

    @Test
    @DisplayName("En ACTIVE, le Plan reçoit le niveau prescrit par le moteur")
    void activePrescritLeNiveau() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 17, "S2", T0));
        properties.setMode(ProgressionEngineMode.ACTIVE);

        Optional<TargetLevel> prescrit =
                bridge.prescriptionLevel(user.getId(), SkillSection.CO, TargetLevel.B2);

        assertThat(bridge.actif()).isTrue();
        assertThat(prescrit).contains(TargetLevel.B1);
    }

    /**
     * §19, §20, invariant I16 — un acquis contredit passe devant l'apprentissage
     * normal. C'est ce qui empêche {@code CO A2} et {@code CO B1} le même jour
     * quand B1 vacille et que son prérequis A2 vient d'être révoqué.
     */
    @Test
    @DisplayName("Un WATCH prend la main : on vérifie avant de redescendre d'un palier")
    void watchPrendLaMain() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), TargetLevel.B1, 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), TargetLevel.B1, 17, "S2", T0));
        ingestionService.ingerer(examenRate(user.getId(), TargetLevel.B1, T0.plusSeconds(86400)));
        properties.setMode(ProgressionEngineMode.ACTIVE);

        assertThat(bridge.aUneVerificationEnAttente(
                user.getId(), SkillSection.CO, TargetLevel.B2)).isTrue();
        assertThat(bridge.prescriptionLevel(user.getId(), SkillSection.CO, TargetLevel.B2))
                .contains(TargetLevel.B1);
    }

    /**
     * §25 bis.2 — ce que le front reçoit, et ce qu'il ne reçoit pas. Le DTO n'a
     * tout simplement pas de champ pour {@code masteryScore} : un contrat qu'on
     * ne peut pas violer par distraction.
     */
    @Test
    @DisplayName("Les états servis portent l'état et son libellé, jamais un score interne")
    void etatsServisNePortentAucunScore() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 16, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), TargetLevel.A2, 17, "S2", T0));

        var servis = reportService.etatsServis(user.getId(), TargetLevel.B2);

        ProgressionStateDto a2 = servis.stream()
                .filter(etat -> etat.stateKey().equals("CO:A2")).findFirst().orElseThrow();
        assertThat(a2.status()).isEqualTo(ProgressionStatus.SOLID);
        assertThat(a2.statusLabel()).isEqualTo("Acquis");
        assertThat(a2.tone()).isEqualTo("success");
        assertThat(a2.visibleProgress()).isEqualTo(100);

        // Le palier jamais mesuré : aucun pourcentage, et surtout pas 0 (§18.6).
        ProgressionStateDto b2 = servis.stream()
                .filter(etat -> etat.stateKey().equals("CO:B2")).findFirst().orElseThrow();
        assertThat(b2.visibleProgress()).isNull();
        assertThat(b2.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(b2.statusLabel()).isEqualTo("À évaluer");
    }

    /**
     * §47.4 — une précision sans sa base est une invitation à décider trop tôt.
     * Le rapport sert les deux, et refuse de conclure quand il n'y a rien.
     */
    @Test
    @DisplayName("Le rapport shadow refuse de conclure sans résultat, et le dit")
    void rapportShadowNeConcluPasSansDonnees() {
        ProgressionShadowReportDto rapport = reportService.rapportShadow();

        assertThat(rapport.mode()).isEqualTo(ProgressionEngineMode.SHADOW);
        assertThat(rapport.engineVersion()).isEqualTo(1);
        assertThat(rapport.objectifPrecision()).isEqualTo(0.70d);
        assertThat(rapport.minOutcomeCount()).isEqualTo(30);
        if (rapport.predictionsAvecResultat() == 0) {
            assertThat(rapport.precisionSolid()).isNull();
            assertThat(rapport.verdict())
                    .isEqualTo(ProgressionShadowReportDto.Verdict.AUCUNE_DONNEE);
            assertThat(rapport.recommandation()).contains("Absence de mesure, pas 0 %");
        }
    }

    private LearningEvidence serie(UUID userId, TargetLevel level, int correctes,
                                   String contenu, Instant quand) {
        double accuracy = correctes / 20.0d;
        return preuve(userId, level, EvidenceSourceType.CO_CE_20_SERIES,
                (accuracy - 0.25d) / 0.75d, contenu, quand);
    }

    private LearningEvidence examenRate(UUID userId, TargetLevel level, Instant quand) {
        return preuve(userId, level, EvidenceSourceType.DOMAIN_MOCK, 0.20d, "MOCK-KO", quand);
    }

    private LearningEvidence preuve(UUID userId, TargetLevel level, EvidenceSourceType source,
                                    double result, String contenu, Instant quand) {
        return LearningEvidence.builder()
                .userId(userId)
                .attemptId(UUID.randomUUID())
                .occurredAt(quand)
                .ingestedAt(Instant.now())
                .entryPoint(EvidenceEntryPoint.REVISER)
                .sourceType(source)
                .section(SkillSection.CO)
                .level(level)
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
