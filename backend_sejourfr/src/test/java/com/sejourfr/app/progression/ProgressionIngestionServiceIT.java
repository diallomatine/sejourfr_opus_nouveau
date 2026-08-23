package com.sejourfr.app.progression;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStateKey;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.entity.ProgressionStateRecord;
import com.sejourfr.app.progression.manager.ProgressionStateManager;
import com.sejourfr.app.progression.repository.LearningEvidenceRepository;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ProgressionReadService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

/**
 * Le chemin d'écriture complet : une preuve arrive, le registre la garde, la
 * projection se met à jour.
 *
 * <p>Ce que vérifie ce fichier et que la suite d'acceptation ne peut pas :
 * l'idempotence <b>en base</b> (§42), la matérialisation de l'état (§27.2), et
 * le fait qu'un replay reconstruit exactement la même chose (§29).
 */
class ProgressionIngestionServiceIT extends AbstractIntegrationTest {

    @Autowired ProgressionIngestionService ingestionService;
    @Autowired ProgressionReadService readService;
    @Autowired ProgressionStateManager stateManager;
    @Autowired LearningEvidenceRepository evidenceRepository;
    @Autowired ProgressionProperties properties;
    @Autowired TestData data;

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");

    @Test
    @DisplayName("Une série ingérée matérialise son état, avec le résultat corrigé du hasard")
    void ingestionMaterialiseLEtat() {
        User user = data.user();

        ProgressionSnapshot etat = ingestionService
                .ingerer(serie(user.getId(), 16, 20, "S1", T0))
                .orElseThrow();

        assertThat(etat.masteryScore()).isCloseTo(0.733333d, within(1e-6));
        assertThat(etat.status()).isEqualTo(ProgressionStatus.PROGRESSING);

        ProgressionStateRecord ligne = stateManager
                .trouver(user.getId(), "CO:A2", properties.getEngineVersion())
                .orElseThrow();
        assertThat(ligne.getMasteryScore()).isCloseTo(0.733333d, within(1e-6));
        assertThat(ligne.getVisibleProgress()).isEqualTo(51);
        assertThat(ligne.getSumWeightEpoch()).isGreaterThan(0.0d);
    }

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>C'est l'unicité en base qui tient l'idempotence, pas un {@code exists}
     * applicatif — celui-là perd la course contre deux requêtes concurrentes,
     * c'est-à-dire contre le retry réseau qu'il est censé couvrir.
     */
    @Test
    @DisplayName("Le même retry deux fois ne double ni le registre ni l'agrégat")
    void retryIdempotent() {
        User user = data.user();
        LearningEvidence preuve = serie(user.getId(), 16, 20, "S1", T0);

        ProgressionSnapshot premier = ingestionService.ingerer(preuve).orElseThrow();
        Optional<ProgressionSnapshot> second = ingestionService.ingerer(preuve);

        assertThat(second).isEmpty();
        assertThat(evidenceRepository.findByUserIdOrderByOccurredAtAsc(user.getId())).hasSize(1);

        ProgressionStateRecord ligne = stateManager
                .trouver(user.getId(), "CO:A2", properties.getEngineVersion())
                .orElseThrow();
        assertThat(ligne.getSumWeightEpoch())
                .isCloseTo(premier.sumWeightEpoch(), within(1e-12));
    }

    @Test
    @DisplayName("Deux séries indépendantes confirment A2 et ouvrent B1")
    void deuxSeriesConfirmentLePalier() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), 16, 20, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), 17, 20, "S2", T0));

        var domaine = readService.domaine(user.getId(), SkillSection.CO, TargetLevel.B2, T0);

        assertThat(domaine.levels().get(TargetLevel.A2).status())
                .isEqualTo(ProgressionStatus.SOLID);
        assertThat(domaine.levels().get(TargetLevel.A2).visibleProgress()).isEqualTo(100);
        assertThat(domaine.activeLearningLevel()).isEqualTo(TargetLevel.B1);
        assertThat(domaine.prescriptionLevel()).isEqualTo(TargetLevel.B1);
    }

    /**
     * §18.6 — le palier jamais mesuré directement n'affiche aucun pourcentage,
     * et surtout pas 0 %. Le candidat n'a pas régressé.
     */
    @Test
    @DisplayName("B1 acquis satisfait A2 — sans preuve A2, et sans pourcentage A2")
    void prerequisSansFaussePreuve() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), TargetLevel.B1, 16, 20, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), TargetLevel.B1, 17, 20, "S2", T0));

        var domaine = readService.domaine(user.getId(), SkillSection.CO, TargetLevel.B2, T0);

        assertThat(domaine.prerequisiteSatisfied()).containsEntry(TargetLevel.A2, true);
        assertThat(domaine.prerequisiteSatisfiedByLevel())
                .containsEntry(TargetLevel.A2, TargetLevel.B1);
        assertThat(domaine.levels().get(TargetLevel.A2).visibleProgress()).isNull();
        assertThat(domaine.levels().get(TargetLevel.A2).masteryScore()).isNull();
        assertThat(evidenceRepository.findByUserIdOrderByOccurredAtAsc(user.getId()))
                .noneMatch(e -> e.getLevel() == TargetLevel.A2);
    }

    @Test
    @DisplayName("Une pratique interrompue donne des points de parcours, aucune maîtrise")
    void pratiquePartielle() {
        User user = data.user();

        ProgressionSnapshot etat = ingestionService.ingererPratiquePartielle(
                user.getId(), new PartialPractice(
                        ProgressionStateKey.receptive(SkillSection.CO, TargetLevel.A2),
                        EvidenceSourceType.CO_CE_20_SERIES, 12, 20, T0));

        assertThat(etat.practicePoints()).isCloseTo(0.60d, within(1e-9));
        assertThat(etat.masteryScore()).isNull();
        assertThat(etat.status()).isEqualTo(ProgressionStatus.NOT_EVALUATED);
        assertThat(etat.visibleProgress()).isNull();
        assertThat(evidenceRepository.findByUserIdOrderByOccurredAtAsc(user.getId())).isEmpty();
    }

    @Test
    @DisplayName("Le replay reconstruit exactement le même état")
    void replayDeterministe() {
        User user = data.user();
        ingestionService.ingerer(serie(user.getId(), 16, 20, "S1", T0));
        ingestionService.ingerer(serie(user.getId(), 17, 20, "S2", T0.plus(Duration.ofDays(3))));
        ProgressionStateRecord avant = stateManager
                .trouver(user.getId(), "CO:A2", properties.getEngineVersion()).orElseThrow();
        double masteryAvant = avant.getMasteryScore();
        double masseAvant = avant.getSumWeightEpoch();

        int cles = ingestionService.rejouer(user.getId(), Instant.now());

        ProgressionStateRecord apres = stateManager
                .trouver(user.getId(), "CO:A2", properties.getEngineVersion()).orElseThrow();
        assertThat(cles).isEqualTo(1);
        assertThat(apres.getMasteryScore()).isCloseTo(masteryAvant, within(1e-12));
        assertThat(apres.getSumWeightEpoch()).isCloseTo(masseAvant, within(1e-12));
    }

    /**
     * §5 — un {@code occurredAt} impossible ne doit jamais être accepté en
     * silence : il fausserait le poids de la preuve <i>et</i> tous les calculs
     * de récence qui suivent.
     */
    @Test
    @DisplayName("Une preuve datée dans le futur est refusée, pas normalisée en douce")
    void occurredAtDansLeFuturRefuse() {
        User user = data.user();
        LearningEvidence impossible =
                serie(user.getId(), 16, 20, "S1", Instant.now().plus(Duration.ofDays(2)));

        assertThatThrownBy(() -> ingestionService.ingerer(impossible))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("futur");
    }

    private LearningEvidence serie(UUID userId, int correct, int total, String contenu,
                                   Instant occurredAt) {
        return serie(userId, TargetLevel.A2, correct, total, contenu, occurredAt);
    }

    private LearningEvidence serie(UUID userId, TargetLevel level, int correct, int total,
                                   String contenu, Instant occurredAt) {
        double accuracy = (double) correct / total;
        double result = (accuracy - 0.25d) / 0.75d;
        return LearningEvidence.builder()
                .userId(userId)
                .attemptId(UUID.randomUUID())
                .occurredAt(occurredAt)
                .ingestedAt(Instant.now())
                .entryPoint(EvidenceEntryPoint.REVISER)
                .sourceType(EvidenceSourceType.CO_CE_20_SERIES)
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
