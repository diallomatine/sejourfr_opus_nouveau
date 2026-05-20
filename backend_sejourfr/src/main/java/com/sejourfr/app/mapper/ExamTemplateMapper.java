package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateRuleDto;
import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Component
public class ExamTemplateMapper {

    /** Vue publique (vitrine + selection d'un examen blanc). */
    public ExamTemplateSummaryResponse toSummary(ExamTemplate t) {
        return new ExamTemplateSummaryResponse(
                t.getId(),
                t.getSlug(),
                t.getModule(),
                t.getTargetProcedure(),
                t.getTargetLevel(),
                t.getName(),
                t.getSubtitle(),
                t.getDescription(),
                t.getDurationSeconds(),
                t.getTotalQuestions(),
                t.getPassingScore(),
                t.isFree(),
                t.getPosition()
        );
    }

    /** Vue admin (full info + rules). */
    public AdminExamTemplateDto toAdminDto(ExamTemplate t) {
        List<AdminExamTemplateRuleDto> rules = t.getRules().stream()
                .sorted(Comparator.comparingInt(ExamTemplateRule::getPosition))
                .map(this::toAdminRuleDto)
                .toList();

        return new AdminExamTemplateDto(
                t.getId(),
                t.getSlug(),
                t.getModule(),
                t.getTargetLevel(),
                t.getTargetProcedure(),
                t.getName(),
                t.getSubtitle(),
                t.getDescription(),
                t.getDurationSeconds(),
                t.getTotalQuestions(),
                t.getPassingScore(),
                t.isFree(),
                t.isPublished(),
                t.getPosition(),
                t.getCreatedAt(),
                t.getUpdatedAt(),
                rules
        );
    }

    private AdminExamTemplateRuleDto toAdminRuleDto(ExamTemplateRule r) {
        UUID themeId = r.getTheme() != null ? r.getTheme().getId() : null;
        String themeName = r.getTheme() != null ? r.getTheme().getName() : null;
        return new AdminExamTemplateRuleDto(
                r.getId(),
                themeId,
                themeName,
                r.getQuestionType(),
                r.getDifficulty(),
                r.getQuestionCount(),
                r.getPosition()
        );
    }
}
