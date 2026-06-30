package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ExamTemplateMapperTest {

    private final ExamTemplateMapper mapper = new ExamTemplateMapper();

    private ExamTemplate template(UUID id) {
        ExamTemplate t = new ExamTemplate();
        t.setId(id);
        t.setSlug("tcf-co-diagnostic");
        t.setModule(Module.TCF);
        t.setTargetLevel(TargetLevel.B1);
        t.setTargetProcedure(TargetProcedure.NAT);
        t.setName("Diagnostic CO");
        t.setSubtitle("Compréhension orale");
        t.setDescription("Examen blanc de compréhension orale");
        t.setDurationSeconds(1800);
        t.setTotalQuestions(30);
        t.setPassingScore(20);
        t.setFree(true);
        t.setPublished(true);
        t.setPosition(2);
        t.setCreatedAt(Instant.parse("2026-01-01T00:00:00Z"));
        t.setUpdatedAt(Instant.parse("2026-02-01T00:00:00Z"));
        return t;
    }

    @Test
    void toSummary_mapsEveryField() {
        UUID id = UUID.randomUUID();

        ExamTemplateSummaryResponse dto = mapper.toSummary(template(id));

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.slug()).isEqualTo("tcf-co-diagnostic");
        assertThat(dto.module()).isEqualTo(Module.TCF);
        assertThat(dto.targetProcedure()).isEqualTo(TargetProcedure.NAT);
        assertThat(dto.targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(dto.name()).isEqualTo("Diagnostic CO");
        assertThat(dto.subtitle()).isEqualTo("Compréhension orale");
        assertThat(dto.description()).isEqualTo("Examen blanc de compréhension orale");
        assertThat(dto.durationSeconds()).isEqualTo(1800);
        assertThat(dto.totalQuestions()).isEqualTo(30);
        assertThat(dto.passingScore()).isEqualTo(20);
        assertThat(dto.free()).isTrue();
        assertThat(dto.position()).isEqualTo(2);
    }

    @Test
    void toAdminDto_mapsEveryFieldAndSortsRulesByPosition() {
        UUID id = UUID.randomUUID();
        ExamTemplate t = template(id);

        UUID themeId = UUID.randomUUID();
        Theme theme = new Theme();
        theme.setId(themeId);
        theme.setName("Symboles");

        UUID ruleSecondId = UUID.randomUUID();
        ExamTemplateRule ruleSecond = new ExamTemplateRule();
        ruleSecond.setId(ruleSecondId);
        ruleSecond.setQuestionType(QuestionType.CO);
        ruleSecond.setDifficulty(Difficulty.B1);
        ruleSecond.setQuestionCount(10);
        ruleSecond.setPosition(2);

        UUID ruleFirstId = UUID.randomUUID();
        ExamTemplateRule ruleFirst = new ExamTemplateRule();
        ruleFirst.setId(ruleFirstId);
        ruleFirst.setTheme(theme);
        ruleFirst.setQuestionType(QuestionType.CONNAISSANCE);
        ruleFirst.setDifficulty(Difficulty.A2);
        ruleFirst.setQuestionCount(5);
        ruleFirst.setPosition(1);

        // Inserted out of order: the mapper must sort by position ascending.
        t.setRules(new ArrayList<>(List.of(ruleSecond, ruleFirst)));

        AdminExamTemplateDto dto = mapper.toAdminDto(t);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.slug()).isEqualTo("tcf-co-diagnostic");
        assertThat(dto.module()).isEqualTo(Module.TCF);
        assertThat(dto.targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(dto.targetProcedure()).isEqualTo(TargetProcedure.NAT);
        assertThat(dto.name()).isEqualTo("Diagnostic CO");
        assertThat(dto.subtitle()).isEqualTo("Compréhension orale");
        assertThat(dto.description()).isEqualTo("Examen blanc de compréhension orale");
        assertThat(dto.durationSeconds()).isEqualTo(1800);
        assertThat(dto.totalQuestions()).isEqualTo(30);
        assertThat(dto.passingScore()).isEqualTo(20);
        assertThat(dto.free()).isTrue();
        assertThat(dto.published()).isTrue();
        assertThat(dto.position()).isEqualTo(2);
        assertThat(dto.createdAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(dto.updatedAt()).isEqualTo(Instant.parse("2026-02-01T00:00:00Z"));

        assertThat(dto.rules()).hasSize(2);
        // Position 1 first, with theme populated.
        assertThat(dto.rules().get(0).id()).isEqualTo(ruleFirstId);
        assertThat(dto.rules().get(0).themeId()).isEqualTo(themeId);
        assertThat(dto.rules().get(0).themeName()).isEqualTo("Symboles");
        assertThat(dto.rules().get(0).questionType()).isEqualTo(QuestionType.CONNAISSANCE);
        assertThat(dto.rules().get(0).difficulty()).isEqualTo(Difficulty.A2);
        assertThat(dto.rules().get(0).questionCount()).isEqualTo(5);
        assertThat(dto.rules().get(0).position()).isEqualTo(1);
        // Position 2 next, with null theme.
        assertThat(dto.rules().get(1).id()).isEqualTo(ruleSecondId);
        assertThat(dto.rules().get(1).themeId()).isNull();
        assertThat(dto.rules().get(1).themeName()).isNull();
        assertThat(dto.rules().get(1).questionType()).isEqualTo(QuestionType.CO);
        assertThat(dto.rules().get(1).difficulty()).isEqualTo(Difficulty.B1);
        assertThat(dto.rules().get(1).questionCount()).isEqualTo(10);
        assertThat(dto.rules().get(1).position()).isEqualTo(2);
    }

    @Test
    void toAdminDto_emptyRules_yieldEmptyList() {
        ExamTemplate t = template(UUID.randomUUID());
        t.setRules(new ArrayList<>());

        AdminExamTemplateDto dto = mapper.toAdminDto(t);

        assertThat(dto.rules()).isEmpty();
    }
}
