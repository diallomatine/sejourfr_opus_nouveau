package com.sejourfr.app.progression;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.progression.config.ProgressionConfigLoader;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.service.ContentIdentityService;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter.ObservationCompetence;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Ce que l'évaluation IA d'une expression devient — et ce qu'elle ne devient pas. */
class ProductiveEvidenceAdapterTest {

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");
    private static final UUID USER = UUID.randomUUID();
    private static final UUID ATTEMPT = UUID.randomUUID();
    private static final UUID SUJET = UUID.randomUUID();

    private ProgressionIngestionService ingestionService;
    private ProductiveEvidenceAdapter adapter;

    @BeforeEach
    void setUp() {
        ingestionService = mock(ProgressionIngestionService.class);
        when(ingestionService.ingerer(any())).thenReturn(Optional.empty());
        ContentIdentityService contentIdentity = mock(ContentIdentityService.class);
        when(contentIdentity.contentIdDeSujet(any())).thenReturn("sujet:" + SUJET);
        when(contentIdentity.classerSujet(any(), any(), any(), any(), any()))
                .thenReturn(IndependenceClass.NEW_CONTENT);

        adapter = new ProductiveEvidenceAdapter(
                ProgressionConfigLoader.load(1), new ProgressionProperties(),
                ingestionService, contentIdentity);
    }

    /**
     * 🛑 Le test le plus important du fichier — invariant « {@code null} =
     * inconnu, jamais mauvais ».
     *
     * <p>Une compétence que l'IA n'a pas pu observer dans la production n'est
     * pas une compétence ratée. La compter à zéro, c'est exactement ce qui a
     * produit les faux {@code A1_NON_ATTEINT} de V040–V042.
     */
    @Test
    @DisplayName("Une compétence non observée ne produit aucune preuve, surtout pas un zéro")
    void nonObserveNestPasRate() {
        int ecrites = adapter.ingererProduction(USER, ATTEMPT, SUJET, SkillSection.EE,
                EvidenceSourceType.FULL_TASK, EvidenceEntryPoint.PLAN, T0,
                List.of(new ObservationCompetence("EE_CONNECTEURS", false,
                        LearningPlanSkillStatus.NOT_OBSERVED, ObservationConfidence.LOW)));

        assertThat(ecrites).isZero();
        verify(ingestionService, never()).ingerer(any());
    }

    @Test
    @DisplayName("§6.5 — les trois verdicts se traduisent en 1 / 0,5 / 0")
    void mappingNormatifDesVerdicts() {
        adapter.ingererProduction(USER, ATTEMPT, SUJET, SkillSection.EE,
                EvidenceSourceType.FULL_TASK, EvidenceEntryPoint.PLAN, T0, List.of(
                        observee("EE_A", LearningPlanSkillStatus.SOLID),
                        observee("EE_B", LearningPlanSkillStatus.TO_REINFORCE),
                        observee("EE_C", LearningPlanSkillStatus.PRIORITY)));

        List<LearningEvidence> preuves = capturer();
        assertThat(preuves).hasSize(3);
        assertThat(competence(preuves, "EE_A").result()).isCloseTo(1.00d, within(1e-9));
        assertThat(competence(preuves, "EE_B").result()).isCloseTo(0.50d, within(1e-9));
        assertThat(competence(preuves, "EE_C").result()).isCloseTo(0.00d, within(1e-9));
        assertThat(preuves).allMatch(p -> p.section() == SkillSection.EE);
        assertThat(preuves).allMatch(p -> p.level() == null);
    }

    @Test
    @DisplayName("La confiance de l'IA devient scoringConfidence, sans jamais valoir 1")
    void confianceIaTransmise() {
        adapter.ingererProduction(USER, ATTEMPT, SUJET, SkillSection.EO,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, T0, List.of(
                        new ObservationCompetence("EO_A", true,
                                LearningPlanSkillStatus.SOLID, ObservationConfidence.HIGH),
                        new ObservationCompetence("EO_B", true,
                                LearningPlanSkillStatus.SOLID, ObservationConfidence.LOW)));

        List<LearningEvidence> preuves = capturer();
        assertThat(competence(preuves, "EO_A").scoringConfidence())
                .isCloseTo(0.95d, within(1e-9)).isLessThan(1.0d);
        assertThat(competence(preuves, "EO_B").scoringConfidence())
                .isCloseTo(0.50d, within(1e-9));
    }

    @Test
    @DisplayName("Un micro-sujet entre en MICRO_SKILL, et son guidage pèse")
    void microSujetGuideEtPlafonne() {
        adapter.ingererMicroSujet(USER, ATTEMPT, SUJET, SkillSection.EE, "EE_CONNECTEURS",
                SkillCriterionStatus.VALIDATED, true, T0);

        LearningEvidence preuve = capturer().getFirst();
        assertThat(preuve.sourceType()).isEqualTo(EvidenceSourceType.MICRO_SKILL);
        assertThat(preuve.assistanceLevel()).isEqualTo(AssistanceLevel.LIGHT);
        assertThat(preuve.result()).isCloseTo(1.00d, within(1e-9));
        assertThat(preuve.entryPoint()).isEqualTo(EvidenceEntryPoint.COMPETENCES);
    }

    @Test
    @DisplayName("Un micro-sujet sans guidage n'est pas pénalisé")
    void microSujetSansGuidage() {
        adapter.ingererMicroSujet(USER, ATTEMPT, SUJET, SkillSection.EE, "EE_CONNECTEURS",
                SkillCriterionStatus.PARTIAL, false, T0);

        LearningEvidence preuve = capturer().getFirst();
        assertThat(preuve.assistanceLevel()).isEqualTo(AssistanceLevel.NONE);
        assertThat(preuve.result()).isCloseTo(0.50d, within(1e-9));
    }

    /**
     * §12 — le sujet fait l'identité, pas la tentative. Reprendre le même petit
     * sujet après en avoir lu la correction n'est pas une preuve neuve.
     */
    @Test
    @DisplayName("Le contentId porte le sujet, pas la tentative")
    void contentIdPorteLeSujet() {
        adapter.ingererMicroSujet(USER, ATTEMPT, SUJET, SkillSection.EE, "EE_CONNECTEURS",
                SkillCriterionStatus.VALIDATED, true, T0);
        adapter.ingererMicroSujet(USER, UUID.randomUUID(), SUJET, SkillSection.EE,
                "EE_CONNECTEURS", SkillCriterionStatus.VALIDATED, true, T0.plusSeconds(600));

        List<LearningEvidence> preuves = capturer();
        assertThat(preuves).hasSize(2);
        assertThat(preuves.get(0).contentId()).isEqualTo(preuves.get(1).contentId());
        assertThat(preuves.get(0).attemptId()).isNotEqualTo(preuves.get(1).attemptId());
    }

    private static ObservationCompetence observee(String code, LearningPlanSkillStatus status) {
        return new ObservationCompetence(code, true, status, ObservationConfidence.MEDIUM);
    }

    private List<LearningEvidence> capturer() {
        ArgumentCaptor<LearningEvidence> captor = ArgumentCaptor.forClass(LearningEvidence.class);
        verify(ingestionService, atLeastOnce()).ingerer(captor.capture());
        return captor.getAllValues();
    }

    private static LearningEvidence competence(List<LearningEvidence> preuves, String code) {
        return preuves.stream().filter(p -> code.equals(p.skillId())).findFirst().orElseThrow();
    }
}
