package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur du dashboard web : calcul de la série (streak),
 * progression QCM (réussite × confiance), progression EE/EO (note × confiance),
 * niveau TCF estimé, agrégat global. Managers mockés ; aucune DB.
 */
class UserDashboardServiceTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private AttemptManager attemptManager;
    private AnswerManager answerManager;
    private QuestionManager questionManager;
    private ThemeManager themeManager;
    private AiEvaluationManager aiEvaluationManager;
    private UserDashboardService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        answerManager = mock(AnswerManager.class);
        questionManager = mock(QuestionManager.class);
        themeManager = mock(ThemeManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        service = new UserDashboardService(attemptManager, answerManager, questionManager,
                themeManager, aiEvaluationManager);
    }

    private static Theme theme(UUID id, Module module, String code) {
        Theme t = new Theme();
        t.setId(id);
        t.setModule(module);
        t.setCode(code);
        t.setName("Thème " + code);
        return t;
    }

    // ------------------------------------------------------------------ empty state

    @Test
    void summary_emptyState_zeroStreak_nullGlobal() {
        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.currentStreakDays()).isZero();
        assertThat(resp.recordStreakDays()).isZero();
        assertThat(resp.activeToday()).isFalse();
        assertThat(resp.mockExamsTotal()).isZero();
        assertThat(resp.globalSuccessPercent()).isNull();
        assertThat(resp.estimatedTcfLevel()).isNull();
        // Les deux entrées synthétiques EE/EO sont toujours présentes côté TCF.
        assertThat(resp.tcf()).extracting(DashboardSummaryResponse.CategoryStat::code)
                .contains("TCF_EE", "TCF_EO");
    }

    // ------------------------------------------------------------------ streak

    @Test
    void summary_streak_activeToday_countsConsecutive() {
        LocalDate today = LocalDate.now(PARIS);
        when(attemptManager.findActivityDates(userId))
                .thenReturn(List.of(today, today.minusDays(1), today.minusDays(2)));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.activeToday()).isTrue();
        assertThat(resp.currentStreakDays()).isEqualTo(3);
        assertThat(resp.recordStreakDays()).isEqualTo(3);
    }

    @Test
    void summary_streak_yesterdayOnly_stillAliveButNotActiveToday() {
        LocalDate today = LocalDate.now(PARIS);
        when(attemptManager.findActivityDates(userId))
                .thenReturn(List.of(today.minusDays(1), today.minusDays(2)));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.activeToday()).isFalse();
        assertThat(resp.currentStreakDays()).isEqualTo(2);
    }

    @Test
    void summary_streak_brokenChain_currentResetsRecordKept() {
        LocalDate today = LocalDate.now(PARIS);
        when(attemptManager.findActivityDates(userId))
                .thenReturn(List.of(today, today.minusDays(3), today.minusDays(4)));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.currentStreakDays()).isEqualTo(1);
        assertThat(resp.recordStreakDays()).isEqualTo(2);
    }

    // ------------------------------------------------------------------ qcm progression

    @Test
    void summary_qcmProgress_successTimesConfidence_drivesGlobal() {
        UUID themeId = UUID.randomUUID();
        when(themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE))
                .thenReturn(List.of(theme(themeId, Module.CIVIQUE, "CIV_X")));
        when(answerManager.aggregateByTheme(userId, Module.CIVIQUE))
                .thenReturn(List.<Object[]>of(new Object[]{themeId, "CIV_X", "Thème X", 20, 10}));
        when(questionManager.countActiveByTheme(themeId)).thenReturn(40L);

        DashboardSummaryResponse resp = service.summary(userId);

        DashboardSummaryResponse.CategoryStat civ = resp.civique().get(0);
        // réussite = 10/20 = 0.5 ; confiance = min(1, 20/40) = 0.5 ; 100*0.5*0.5 = 25.
        assertThat(civ.percent()).isEqualTo(25);
        assertThat(civ.answered()).isEqualTo(20);
        assertThat(civ.total()).isEqualTo(40);
        assertThat(resp.globalSuccessPercent()).isEqualTo(25);
    }

    // ------------------------------------------------------------------ production EE/EO

    @Test
    void summary_productionCategory_noteTimesConfidence() {
        AiEvaluation eval = new AiEvaluation();
        eval.setNoteSur20(new BigDecimal("14"));
        eval.setNiveauCecrl(NiveauCecrl.B1);
        eval.setEvaluatedAt(Instant.now());
        when(aiEvaluationManager.findByUserAndEpreuve(userId, EpreuveType.TCF_EE))
                .thenReturn(List.of(eval));

        DashboardSummaryResponse resp = service.summary(userId);

        DashboardSummaryResponse.CategoryStat ee = resp.tcf().stream()
                .filter(c -> "TCF_EE".equals(c.code()))
                .findFirst().orElseThrow();
        // avg 14 ×5 × min(1, 1/3) = 70 × 0.3333 = 23.33 → 23.
        assertThat(ee.percent()).isEqualTo(23);
        assertThat(ee.level()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ niveau TCF estimé

    @Test
    void summary_estimatedTcfLevel_prefersFinalCecrl() {
        Attempt a = new Attempt();
        a.setFinalCecrlLevel(NiveauCecrl.B1);
        a.setCecrlLevel(NiveauCecrl.A2);
        when(attemptManager.findLatestTcfWithCecrlLevel(userId)).thenReturn(Optional.of(a));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.estimatedTcfLevel()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void summary_mockExamsTotal_fromManager() {
        when(attemptManager.countFinishedMockExams(userId)).thenReturn(7L);
        // sous-stub explicite : findByUserFiltered renvoie vide par défaut Mockito.
        when(attemptManager.findByUserFiltered(eq(userId), eq(AttemptType.MOCK_EXAM), any(), any(), any(), anyInt()))
                .thenReturn(List.of());

        assertThat(service.summary(userId).mockExamsTotal()).isEqualTo(7);
    }
}
