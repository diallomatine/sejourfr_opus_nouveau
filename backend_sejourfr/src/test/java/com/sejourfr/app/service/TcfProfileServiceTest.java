package com.sejourfr.app.service;

import com.sejourfr.app.dto.TcfLevelProfileResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Test unitaire du profil de niveau TCF par épreuve. Les managers sont mockés ;
 * le {@link TcfLevelEstimatorService} (pure math CECRL, sans dépendance) est
 * instancié réel pour exercer le vrai calcul de plancher / plafond B2.
 */
class TcfProfileServiceTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private AiEvaluationManager aiEvaluationManager;
    private TcfProfileService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        service = new TcfProfileService(attemptManager, productionSubmissionManager,
                aiEvaluationManager, new TcfLevelEstimatorService());
    }

    @Test
    void levelProfile_noData_allEmpty_globalNull() {
        TcfLevelProfileResponse resp = service.levelProfile(userId);

        assertThat(resp.co().level()).isNull();
        assertThat(resp.ce().level()).isNull();
        assertThat(resp.ee().level()).isNull();
        assertThat(resp.eo().level()).isNull();
        assertThat(resp.globalLevel()).isNull();
        assertThat(resp.co().epreuve()).isEqualTo(EpreuveType.TCF_CO);
    }

    @Test
    void levelProfile_co_readsStoredCecrlLevel() {
        Attempt co = new Attempt();
        co.setId(UUID.randomUUID());
        co.setFinishedAt(Instant.now());
        co.setCecrlLevel(NiveauCecrl.B1);
        co.setWeightedScore(40);
        co.setMaxWeightedScore(50);
        when(attemptManager.findByUserFiltered(eq(userId), eq(AttemptType.MOCK_EXAM), eq(Module.TCF),
                eq(QuestionType.CO), eq(null), org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(co));

        TcfLevelProfileResponse resp = service.levelProfile(userId);

        assertThat(resp.co().level()).isEqualTo(NiveauCecrl.B1);
        assertThat(resp.co().weightedScore()).isEqualTo(40);
        assertThat(resp.co().maxWeightedScore()).isEqualTo(50);
        assertThat(resp.co().calibratedScore()).isNotNull();
        // Une seule épreuve renseignée → plancher = B1.
        assertThat(resp.globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void levelProfile_co_noFinishedAttempt_empty() {
        Attempt unfinished = new Attempt();
        unfinished.setId(UUID.randomUUID());
        unfinished.setCecrlLevel(NiveauCecrl.B2);
        when(attemptManager.findByUserFiltered(eq(userId), eq(AttemptType.MOCK_EXAM), eq(Module.TCF),
                eq(QuestionType.CO), eq(null), org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(unfinished));

        assertThat(service.levelProfile(userId).co().level()).isNull();
    }

    @Test
    void levelProfile_ee_floorOfEvaluatedSubmissions_andAverageNote() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setFinishedAt(Instant.now());
        when(attemptManager.findByUserAndEpreuve(eq(userId), eq(EpreuveType.TCF_EE),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(attempt));

        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());
        sub.setStatut(SubmissionStatut.EVALUATED);
        when(productionSubmissionManager.findByAttemptId(attempt.getId())).thenReturn(List.of(sub));

        AiEvaluation eval = new AiEvaluation();
        eval.setNiveauCecrl(NiveauCecrl.B1);
        eval.setNoteSur20(new BigDecimal("15.0"));
        when(aiEvaluationManager.findLatestBySubmissionId(sub.getId())).thenReturn(Optional.of(eval));

        TcfLevelProfileResponse resp = service.levelProfile(userId);

        assertThat(resp.ee().level()).isEqualTo(NiveauCecrl.B1);
        assertThat(resp.ee().note20()).isEqualByComparingTo("15.0");
        assertThat(resp.globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void levelProfile_ee_nonEvaluatedSubmissionsIgnored() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setStartedAt(Instant.now());
        when(attemptManager.findByUserAndEpreuve(eq(userId), eq(EpreuveType.TCF_EE),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of(attempt));

        ProductionSubmission pending = new ProductionSubmission();
        pending.setId(UUID.randomUUID());
        pending.setStatut(SubmissionStatut.SUBMITTED);
        when(productionSubmissionManager.findByAttemptId(attempt.getId())).thenReturn(List.of(pending));

        assertThat(service.levelProfile(userId).ee().level()).isNull();
    }
}
