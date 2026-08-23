package com.sejourfr.app.progression;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfigLoader;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AttemptCompletionStatus;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.PartialPractice;
import com.sejourfr.app.progression.engine.DefaultProgressionEngine;
import com.sejourfr.app.progression.service.ContentIdentityService;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ReceptiveEvidenceAdapter;
import com.sejourfr.app.progression.service.ReceptiveEvidenceAdapter.ReponseQcm;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Ce que l'adaptateur fabrique à partir d'une session terminée — et surtout ce
 * qu'il refuse de fabriquer.
 */
class ReceptiveEvidenceAdapterTest {

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");
    private static final UUID USER = UUID.randomUUID();
    private static final UUID ATTEMPT = UUID.randomUUID();

    private ProgressionIngestionService ingestionService;
    private ReceptiveEvidenceAdapter adapter;

    @BeforeEach
    void setUp() {
        ingestionService = mock(ProgressionIngestionService.class);
        ContentIdentityService contentIdentity = mock(ContentIdentityService.class);
        when(contentIdentity.contentIdDeSerie(any())).thenReturn("contenu");
        when(contentIdentity.classerSerie(any(), any(), any(), any(), any(), any()))
                .thenReturn(IndependenceClass.NEW_CONTENT);
        when(ingestionService.ingerer(any())).thenReturn(Optional.empty());

        ProgressionProperties properties = new ProgressionProperties();
        adapter = new ReceptiveEvidenceAdapter(
                ProgressionConfigLoader.load(1), properties,
                new DefaultProgressionEngine(ProgressionConfigLoader.load(1)),
                ingestionService, contentIdentity);
    }

    /**
     * 🛑 Le test le plus important du fichier — invariants I6 et I8.
     *
     * <p>Sur une session rendue ou expirée, le dénominateur est le nombre total
     * de questions. Utiliser {@code answeredCount} récompenserait le candidat
     * qui s'arrête dès qu'il doute : 8 bonnes sur 12 répondues donnerait 0,67
     * là où la vérité est 8/20, soit 0,40 brut et 0,20 corrigé du hasard.
     */
    @Test
    @DisplayName("Un examen expiré compte les non-répondues comme fausses")
    void examenExpireCompteSurLeTotal() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, true));
        }
        for (int i = 0; i < 4; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, false));
        }
        for (int i = 0; i < 8; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, false, false));
        }

        adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.TIME_EXPIRED,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, reponses);

        assertThat(capturer().result()).isCloseTo(0.20d, within(1e-9));
    }

    @Test
    @DisplayName("Une session abandonnée n'émet aucune preuve, seulement du parcours")
    void abandonNEmetAucunePreuve() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 12; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, true));
        }
        for (int i = 0; i < 8; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, false, false));
        }

        int ecrites = adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.ABANDONED,
                EvidenceSourceType.CO_CE_20_SERIES, EvidenceEntryPoint.REVISER, reponses);

        assertThat(ecrites).isZero();
        verify(ingestionService, never()).ingerer(any());
        ArgumentCaptor<PartialPractice> partielle = ArgumentCaptor.forClass(PartialPractice.class);
        verify(ingestionService).ingererPratiquePartielle(any(), partielle.capture());
        assertThat(partielle.getValue().completedUnits()).isEqualTo(12);
        assertThat(partielle.getValue().totalUnits()).isEqualTo(20);
    }

    /**
     * §6.4 — un examen mesure plusieurs paliers à la fois. Le réduire à un
     * niveau unique jetterait ce qu'il a de plus utile : c'est cette ventilation
     * qui permettra qu'un B1 acquis satisfasse A2 sans qu'on invente une preuve
     * A2.
     */
    @Test
    @DisplayName("Un examen produit une preuve par palier réellement mesuré")
    void unExamenProduitUnePreuveParPalier() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, true));
        }
        for (int i = 0; i < 9; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.B1, 4, true, i < 6));
        }
        for (int i = 0; i < 8; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.B2, 4, true, i < 2));
        }

        adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.SUBMITTED,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, reponses);

        List<LearningEvidence> preuves = capturerToutes();
        assertThat(preuves).hasSize(3);
        assertThat(preuves).extracting(LearningEvidence::level)
                .containsExactlyInAnyOrder(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);
        assertThat(preuves).allMatch(p -> p.section() == SkillSection.CO);
        // A2 : 8/8 -> (1.0 - 0.25) / 0.75 = 1.0
        assertThat(niveau(preuves, TargetLevel.A2).result()).isCloseTo(1.0d, within(1e-9));
        // B2 : 2/8 -> (0.25 - 0.25) / 0.75 = 0.0 — au hasard près, il n'a rien montré.
        assertThat(niveau(preuves, TargetLevel.B2).result()).isCloseTo(0.0d, within(1e-9));
    }

    @Test
    @DisplayName("CO et CE ne se mélangent jamais dans une même preuve")
    void coEtCeRestentSepares() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, true));
            reponses.add(reponse(QuestionType.CE, Difficulty.A2, 4, true, false));
        }

        adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.SUBMITTED,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, reponses);

        List<LearningEvidence> preuves = capturerToutes();
        assertThat(preuves).hasSize(2);
        assertThat(preuves).extracting(LearningEvidence::section)
                .containsExactlyInAnyOrder(SkillSection.CO, SkillSection.CE);
    }

    /**
     * §6.3, phase 4 — tant que le catalogue ne porte pas de
     * {@code difficultyBand}, une série d'entraînement reste non calibrée : elle
     * pèse 0,50 et ne peut jamais verrouiller un palier. Le choix inverse
     * validerait des paliers sur des séries dont on ignore la composition.
     */
    @Test
    @DisplayName("Une série d'entraînement reste non calibrée tant que le blueprint n'est pas tagué")
    void serieDEntrainementNonCalibree() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 4, true, i < 16));
        }

        adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.SUBMITTED,
                EvidenceSourceType.CO_CE_20_SERIES, EvidenceEntryPoint.REVISER, reponses);

        LearningEvidence preuve = capturer();
        assertThat(preuve.calibrationStatus()).isEqualTo(CalibrationStatus.UNCALIBRATED);
        assertThat(preuve.sourceType())
                .isEqualTo(EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED);
    }

    /**
     * §6.1 — le taux de hasard est une moyenne <b>par question</b>, pas une
     * constante 0,25. Sans ça, le moteur récompenserait le format de la question
     * plutôt que la compréhension.
     */
    @Test
    @DisplayName("Le taux de hasard suit le nombre de propositions de chaque question")
    void tauxDeHasardParQuestion() {
        List<ReponseQcm> reponses = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            reponses.add(reponse(QuestionType.CO, Difficulty.A2, 3, true, i < 16));
        }

        adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.SUBMITTED,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, reponses);

        // 16/20 à trois propositions : (0.80 - 1/3) / (2/3) = 0.70, et non 0.733.
        assertThat(capturer().result()).isCloseTo(0.70d, within(1e-9));
    }

    @Test
    @DisplayName("Une question civique ou sans palier CECRL n'entre dans aucune preuve")
    void horsPerimetreIgnore() {
        List<ReponseQcm> reponses = List.of(
                reponse(QuestionType.CONNAISSANCE, Difficulty.CSP, 4, true, true),
                reponse(QuestionType.MISE_SITUATION, Difficulty.NAT, 4, true, true),
                reponse(QuestionType.CO, null, 4, true, true));

        int ecrites = adapter.ingerer(USER, ATTEMPT, T0, AttemptCompletionStatus.SUBMITTED,
                EvidenceSourceType.DOMAIN_MOCK, EvidenceEntryPoint.EXAM_HUB, reponses);

        assertThat(ecrites).isZero();
        verify(ingestionService, never()).ingerer(any());
    }

    private static ReponseQcm reponse(QuestionType type, Difficulty difficulte, int options,
                                      boolean repondue, boolean correcte) {
        return new ReponseQcm(UUID.randomUUID(), type, difficulte, options, repondue, correcte);
    }

    private LearningEvidence capturer() {
        return capturerToutes().getFirst();
    }

    private List<LearningEvidence> capturerToutes() {
        ArgumentCaptor<LearningEvidence> captor = ArgumentCaptor.forClass(LearningEvidence.class);
        verify(ingestionService, org.mockito.Mockito.atLeastOnce()).ingerer(captor.capture());
        return captor.getAllValues();
    }

    private static LearningEvidence niveau(List<LearningEvidence> preuves, TargetLevel level) {
        return preuves.stream().filter(p -> p.level() == level).findFirst().orElseThrow();
    }
}
