package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AttemptEpreuveResult;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class AttemptMapperTest {

    private final TcfLevelEstimatorService estimator = new TcfLevelEstimatorService();
    private final AttemptMapper mapper = new AttemptMapper(new QuestionMapper(), estimator);

    private Theme theme() {
        Theme t = new Theme();
        t.setId(UUID.randomUUID());
        t.setName("Thème");
        t.setModule(Module.TCF);
        t.setCode("c");
        return t;
    }

    private Question question(QuestionType type, Difficulty diff) {
        Question q = new Question();
        q.setId(UUID.randomUUID());
        q.setModule(Module.TCF);
        q.setTheme(theme());
        q.setDifficulty(diff);
        q.setQuestionType(type);
        q.setStatement("S");
        Choice c = new Choice();
        c.setId(UUID.randomUUID());
        c.setLabel("A");
        c.setCorrect(true);
        c.setDisplayOrder(0);
        q.setChoices(new ArrayList<>(List.of(c)));
        return q;
    }

    private AttemptQuestion attemptQuestion(Question q, int position, Boolean answeredCorrect) {
        AttemptQuestion aq = new AttemptQuestion();
        aq.setId(UUID.randomUUID());
        aq.setQuestion(q);
        aq.setPosition(position);
        if (answeredCorrect != null) {
            Answer a = new Answer();
            a.setSelectedChoiceIds(new ArrayList<>(List.of(q.getChoices().get(0).getId())));
            a.setCorrect(answeredCorrect.booleanValue());
            aq.setAnswer(a);
        }
        return aq;
    }

    @Test
    void toResponse_civiqueTraining_noTemplate_noCalibration() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(Module.CIVIQUE);
        attempt.setTotalQuestions(2);
        attempt.setTimeLimitSeconds(600);
        attempt.setPassThreshold(8);
        attempt.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        attempt.setScore(7);
        attempt.setLotThemeId(UUID.randomUUID());

        Question q1 = question(QuestionType.CONNAISSANCE, Difficulty.CSP);
        Question q2 = question(QuestionType.CONNAISSANCE, Difficulty.CSP);
        AttemptQuestion aq1 = attemptQuestion(q1, 0, Boolean.TRUE);
        AttemptQuestion aq2 = attemptQuestion(q2, 1, null);

        AttemptResponse r = mapper.toResponse(attempt, List.of(aq1, aq2), false);

        assertThat(r.id()).isEqualTo(attempt.getId());
        assertThat(r.type()).isEqualTo(AttemptType.TRAINING);
        assertThat(r.module()).isEqualTo(Module.CIVIQUE);
        assertThat(r.examTemplateId()).isNull();
        assertThat(r.examTemplateSlug()).isNull();
        assertThat(r.examTemplateName()).isNull();
        assertThat(r.totalQuestions()).isEqualTo(2);
        assertThat(r.timeLimitSeconds()).isEqualTo(600);
        assertThat(r.passThreshold()).isEqualTo(8);
        assertThat(r.startedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(r.finishedAt()).isNull();
        assertThat(r.score()).isEqualTo(7);
        assertThat(r.levelAchieved()).isNull();
        assertThat(r.moduleExamQuestionType()).isNull();
        assertThat(r.themeId()).isEqualTo(attempt.getLotThemeId());
        assertThat(r.calibratedScore()).isNull();
        assertThat(r.cecrlLevel()).isNull();
        assertThat(r.epreuveResults()).isEmpty();

        assertThat(r.questions()).hasSize(2);
        assertThat(r.questions().get(0).id()).isEqualTo(aq1.getId());
        assertThat(r.questions().get(0).position()).isZero();
        assertThat(r.questions().get(0).answered()).isTrue();
        assertThat(r.questions().get(0).selectedChoiceIds())
                .containsExactly(q1.getChoices().get(0).getId());
        assertThat(r.questions().get(0).correct()).isNull(); // revealCorrect=false
        assertThat(r.questions().get(0).question().id()).isEqualTo(q1.getId());

        assertThat(r.questions().get(1).answered()).isFalse();
        assertThat(r.questions().get(1).selectedChoiceIds()).isEmpty();
        assertThat(r.questions().get(1).correct()).isNull();
    }

    @Test
    void toResponse_tcfModuleExamFinished_revealsEpreuveResultsAndCalibration() {
        Attempt attempt = new Attempt();
        attempt.setId(UUID.randomUUID());
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(Module.TCF);
        attempt.setModuleExamQuestionType(QuestionType.CO);
        attempt.setTotalQuestions(3);
        attempt.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        attempt.setFinishedAt(Instant.parse("2026-01-01T00:30:00Z"));
        attempt.setWeightedScore(30);
        attempt.setMaxWeightedScore(50);
        attempt.setCecrlLevel(NiveauCecrl.B1); // ignored once epreuveResults present

        Question q1 = question(QuestionType.CO, Difficulty.A2);
        Question q2 = question(QuestionType.CO, Difficulty.B1);
        Question q3 = question(QuestionType.CO_IMAGE, Difficulty.B2);
        AttemptQuestion aq1 = attemptQuestion(q1, 0, Boolean.TRUE);
        AttemptQuestion aq2 = attemptQuestion(q2, 1, Boolean.FALSE);
        AttemptQuestion aq3 = attemptQuestion(q3, 2, Boolean.TRUE);

        AttemptResponse r = mapper.toResponse(attempt, List.of(aq1, aq2, aq3), true);

        // Expected per-épreuve scoring mirrors the estimator (CO_IMAGE folded into CO).
        List<QcmAnswerResult> coAnswers = List.of(
                new QcmAnswerResult(q1.getId(), Difficulty.A2, true),
                new QcmAnswerResult(q2.getId(), Difficulty.B1, false),
                new QcmAnswerResult(q3.getId(), Difficulty.B2, true));
        int expectedCalibrated = estimator.calibratedScore(coAnswers);
        NiveauCecrl expectedLevel = estimator.estimateQcm(coAnswers);
        NiveauCecrl expectedGlobal = estimator.floor(List.of(expectedLevel));

        assertThat(r.moduleExamQuestionType()).isEqualTo(QuestionType.CO);
        assertThat(r.themeId()).isNull();
        assertThat(r.calibratedScore()).isEqualTo(estimator.calibratedScore(30, 50));
        assertThat(r.cecrlLevel()).isEqualTo(expectedGlobal);

        assertThat(r.epreuveResults()).hasSize(1);
        AttemptEpreuveResult co = r.epreuveResults().get(0);
        assertThat(co.epreuve()).isEqualTo(QuestionType.CO);
        assertThat(co.correct()).isEqualTo(2);
        assertThat(co.total()).isEqualTo(3);
        assertThat(co.calibratedScore()).isEqualTo(expectedCalibrated);
        assertThat(co.cecrlLevel()).isEqualTo(expectedLevel);

        assertThat(r.questions()).hasSize(3);
        assertThat(r.questions().get(0).correct()).isTrue();
        assertThat(r.questions().get(1).correct()).isFalse();
        assertThat(r.questions().get(2).correct()).isTrue();
    }

    @Test
    void toSummary_civique_withTemplate_noCalibration() {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setTotalQuestions(40);
        a.setPassThreshold(28);
        a.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        a.setFinishedAt(Instant.parse("2026-01-01T00:20:00Z"));
        a.setScore(31);
        a.setLotThemeId(UUID.randomUUID());
        a.setSlotNumber(3);

        ExamTemplate template = new ExamTemplate();
        template.setId(UUID.randomUUID());
        template.setSlug("civique-blanc-1");
        template.setName("Examen blanc civique");
        a.setExamTemplate(template);

        Question q = question(QuestionType.CONNAISSANCE, Difficulty.NAT);
        a.setQuestions(new ArrayList<>(List.of(attemptQuestion(q, 0, Boolean.TRUE))));

        AttemptSummaryResponse s = mapper.toSummary(a);

        assertThat(s.id()).isEqualTo(a.getId());
        assertThat(s.type()).isEqualTo(AttemptType.MOCK_EXAM);
        assertThat(s.module()).isEqualTo(Module.CIVIQUE);
        assertThat(s.epreuve()).isEqualTo(EpreuveType.CIVIQUE);
        assertThat(s.difficulty()).isEqualTo(Difficulty.NAT);
        assertThat(s.totalQuestions()).isEqualTo(40);
        assertThat(s.passThreshold()).isEqualTo(28);
        assertThat(s.startedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(s.finishedAt()).isEqualTo(Instant.parse("2026-01-01T00:20:00Z"));
        assertThat(s.score()).isEqualTo(31);
        assertThat(s.examTemplateId()).isEqualTo(template.getId());
        assertThat(s.examTemplateSlug()).isEqualTo("civique-blanc-1");
        assertThat(s.examTemplateName()).isEqualTo("Examen blanc civique");
        assertThat(s.moduleExamQuestionType()).isNull();
        assertThat(s.weightedScore()).isNull();
        assertThat(s.maxWeightedScore()).isNull();
        assertThat(s.calibratedScore()).isNull();
        assertThat(s.cecrlLevel()).isNull();
        assertThat(s.lotThemeId()).isEqualTo(a.getLotThemeId());
        assertThat(s.slotNumber()).isEqualTo(3);
    }

    @Test
    void toSummary_emptyQuestions_nullDifficulty() {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        a.setQuestions(new ArrayList<>());

        AttemptSummaryResponse s = mapper.toSummary(a);

        assertThat(s.difficulty()).isNull();
        assertThat(s.examTemplateId()).isNull();
        assertThat(s.calibratedScore()).isNull();
        assertThat(s.cecrlLevel()).isNull();
    }

    @Test
    void toSummary_tcfModuleExam_storedCecrlLevelUsedAndCalibrated() {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setEpreuve(EpreuveType.TCF_CO);
        a.setModuleExamQuestionType(QuestionType.CO);
        a.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        a.setWeightedScore(40);
        a.setMaxWeightedScore(50);
        a.setCecrlLevel(NiveauCecrl.B2);
        a.setQuestions(new ArrayList<>(List.of(
                attemptQuestion(question(QuestionType.CO, Difficulty.B2), 0, Boolean.TRUE))));

        AttemptSummaryResponse s = mapper.toSummary(a);

        assertThat(s.calibratedScore()).isEqualTo(estimator.calibratedScore(40, 50));
        assertThat(s.cecrlLevel()).isEqualTo(NiveauCecrl.B2);
        assertThat(s.weightedScore()).isEqualTo(40);
        assertThat(s.maxWeightedScore()).isEqualTo(50);
    }

    @Test
    void toSummary_tcfModuleExam_nullCecrlLevel_fallsBackToWeightedDerivation() {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setEpreuve(EpreuveType.TCF_CE);
        a.setModuleExamQuestionType(QuestionType.CE);
        a.setStartedAt(Instant.parse("2026-01-01T00:00:00Z"));
        a.setWeightedScore(20);
        a.setMaxWeightedScore(50);
        a.setCecrlLevel(null);
        a.setQuestions(new ArrayList<>(List.of(
                attemptQuestion(question(QuestionType.CE, Difficulty.A2), 0, Boolean.FALSE))));

        AttemptSummaryResponse s = mapper.toSummary(a);

        assertThat(s.calibratedScore()).isEqualTo(estimator.calibratedScore(20, 50));
        assertThat(s.cecrlLevel()).isEqualTo(estimator.levelFromWeighted(20, 50));
    }
}
