package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.ExamService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Variante visiteur (non authentifiee) de {@link ExamController}. Memes
 * resultats, prefixe d'URL distinct ({@code /api/public/*}) pour offrir aux
 * visiteurs une surface d'API homogene (themes + exams + attempts/demo).
 */
@RestController
@RequestMapping("/api/public/exams")
@RequiredArgsConstructor
public class PublicExamController {

    private final ExamService examService;

    @GetMapping
    public List<ExamTemplateSummaryResponse> list(@RequestParam(required = false) Module module) {
        return examService.listPublished(module);
    }

    @GetMapping("/{slug}")
    public ExamTemplateSummaryResponse getBySlug(@PathVariable String slug) {
        return examService.getPublishedBySlug(slug);
    }
}
