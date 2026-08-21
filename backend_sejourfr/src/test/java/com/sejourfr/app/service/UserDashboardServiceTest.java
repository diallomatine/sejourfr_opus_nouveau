package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardSummaryResponse;
import com.sejourfr.app.dto.TcfDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
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
    private TcfProfileService tcfProfileService;
    private UserDashboardService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        answerManager = mock(AnswerManager.class);
        questionManager = mock(QuestionManager.class);
        themeManager = mock(ThemeManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        // Le niveau TCF estimé est dérivé par TcfProfileService (plancher des 4
        // épreuves, meilleur résultat de chacune) : ici on n'exerce que le
        // branchement, la règle elle-même vit dans TcfProfileServiceTest.
        tcfProfileService = mock(TcfProfileService.class);
        when(tcfProfileService.levelProfile(userId))
                .thenReturn(new TcfLevelProfile(null, null, null, null, null));
        service = new UserDashboardService(attemptManager, answerManager, questionManager,
                themeManager, aiEvaluationManager, tcfProfileService);
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
        // Zéro épreuve : le niveau vaut déjà null (« — » à l'écran), il n'y a
        // rien à annoter — « partiel » sur un niveau absent n'aurait aucun sens.
        assertThat(resp.estimatedTcfLevelEpreuvesCounted()).isZero();
        assertThat(resp.estimatedTcfLevelEpreuvesExpected()).isEqualTo(4);
        assertThat(resp.estimatedTcfLevelPartial()).isFalse();
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
    void summary_estimatedTcfLevel_vientDuPlancherDesEpreuves() {
        when(tcfProfileService.levelProfile(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B2, NiveauCecrl.B2, NiveauCecrl.B1, null, NiveauCecrl.B1));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.estimatedTcfLevel()).isEqualTo(NiveauCecrl.B1);
        // 3 épreuves sur 4 : le niveau est vrai, mais il ne porte pas sur tout.
        assertThat(resp.estimatedTcfLevelEpreuvesCounted()).isEqualTo(3);
        assertThat(resp.estimatedTcfLevelPartial()).isTrue();
    }

    @Test
    void summary_estimatedTcfLevel_uneSeuleEpreuve_estPartiel() {
        // Le cas vécu : un candidat qui n'a fait que l'expression écrite lisait
        // « Niveau TCF estimé : B1 » sans que rien ne dise sur quoi il portait.
        when(tcfProfileService.levelProfile(userId)).thenReturn(new TcfLevelProfile(
                null, null, NiveauCecrl.B1, null, NiveauCecrl.B1));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.estimatedTcfLevelEpreuvesCounted()).isEqualTo(1);
        assertThat(resp.estimatedTcfLevelEpreuvesExpected()).isEqualTo(4);
        assertThat(resp.estimatedTcfLevelPartial()).isTrue();
    }

    @Test
    void summary_estimatedTcfLevel_quatreEpreuves_nEstPasPartiel() {
        when(tcfProfileService.levelProfile(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B2, NiveauCecrl.B1, NiveauCecrl.B1, NiveauCecrl.A2, NiveauCecrl.A2));

        DashboardSummaryResponse resp = service.summary(userId);

        assertThat(resp.estimatedTcfLevelEpreuvesCounted()).isEqualTo(4);
        assertThat(resp.estimatedTcfLevelPartial()).isFalse();
    }

    // -------------------------------------------------- profil TCF par domaine

    /**
     * Le bloc par domaine et les trois scalaires historiques disent la
     * <b>même</b> chose : ils sortent de la même {@code TcfLevelProfile}, pas
     * d'un second calcul.
     */
    @Test
    void summary_profilParDomaine_publieLesQuatreDomainesDansUnOrdreFige() {
        when(tcfProfileService.levelProfile(userId)).thenReturn(new TcfLevelProfile(
                NiveauCecrl.B2, null, NiveauCecrl.B1, NiveauCecrl.A2, NiveauCecrl.A2));

        TcfDomainProfileDto profil = service.summary(userId).tcfDomainProfile();

        assertThat(profil.domaines()).extracting(TcfDomainDto::epreuve)
                .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                        EpreuveType.TCF_EO, EpreuveType.TCF_EE);
        assertThat(profil.domaines()).extracting(TcfDomainDto::niveau)
                .containsExactly(NiveauCecrl.B2, null, NiveauCecrl.A2, NiveauCecrl.B1);
        assertThat(profil.globalLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(profil.evaluated()).isEqualTo(3);
        assertThat(profil.expected()).isEqualTo(4);
        assertThat(profil.partial()).isTrue();
    }

    /** Un domaine jamais passé est PRÉSENT, non évalué, sans niveau — jamais A1 non atteint. */
    @Test
    void summary_profilParDomaine_domaineJamaisPasse_estPresentSansNiveau() {
        when(tcfProfileService.levelProfile(userId)).thenReturn(new TcfLevelProfile(
                null, null, NiveauCecrl.B1, null, NiveauCecrl.B1));

        TcfDomainProfileDto profil = service.summary(userId).tcfDomainProfile();

        assertThat(profil.domaines()).hasSize(4);
        TcfDomainDto co = profil.domaines().get(0);
        assertThat(co.epreuve()).isEqualTo(EpreuveType.TCF_CO);
        assertThat(co.evaluated()).isFalse();
        assertThat(co.niveau()).isNull();
        assertThat(profil.evaluated()).isEqualTo(1);
    }

    /** Aucune donnée : 4 domaines quand même, aucun évalué, pas de « partiel » à annoter. */
    @Test
    void summary_profilParDomaine_aucuneDonnee_resteUneListeDeQuatre() {
        TcfDomainProfileDto profil = service.summary(userId).tcfDomainProfile();

        assertThat(profil.domaines()).hasSize(4)
                .allMatch(d -> !d.evaluated() && d.niveau() == null);
        assertThat(profil.globalLevel()).isNull();
        assertThat(profil.evaluated()).isZero();
        assertThat(profil.partial()).isFalse();
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
