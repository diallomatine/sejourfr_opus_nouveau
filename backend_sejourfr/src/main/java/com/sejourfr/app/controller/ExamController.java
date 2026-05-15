package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ExamTemplateRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Vitrine publique des examens blancs. Endpoint non authentifié : la liste
 * sert aussi à pousser l'utilisateur à s'inscrire / s'abonner. Le démarrage
 * d'un attempt sur un template reste lui authentifié + paywallé.
 */
@RestController
@RequestMapping("/api/exams")
public class ExamController {

    private final ExamTemplateRepository repository;

    public ExamController(ExamTemplateRepository repository) {
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
