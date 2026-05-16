package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ExamTemplateRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Liste publique des examens blancs. Doublon assumé de {@link ExamController}
 * sous le préfixe {@code /api/public/*} pour offrir aux visiteurs une
 * surface d'API homogène (themes + exams + attempts/demo).
 */
@RestController
@RequestMapping("/api/public/exams")
public class PublicExamController {

    private final ExamTemplateRepository repository;

    public PublicExamController(ExamTemplateRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<ExamTemplateSummaryResponse> list(@RequestParam(required = false) Module module) {
        List<ExamTemplate> templates = module != null
                ? repository.findByModuleAndPublishedTrueOrderByPositionAsc(module)
                : repository.findByPublishedTrueOrderByModuleAscPositionAsc();
        return templates.stream().map(this::toSummary).toList();
    }

    @GetMapping("/{slug}")
    public ExamTemplateSummaryResponse getBySlug(@PathVariable String slug) {
        ExamTemplate t = repository.findBySlug(slug)
                .filter(ExamTemplate::isPublished)
                .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
        return toSummary(t);
    }

    private ExamTemplateSummaryResponse toSummary(ExamTemplate t) {
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
}
