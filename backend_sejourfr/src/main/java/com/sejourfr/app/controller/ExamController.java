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
 * Vitrine authentifiee des examens blancs publies. Le demarrage d'un attempt
 * sur un template reste paywalle cote {@code AttemptService}.
 */
@RestController
@RequestMapping("/api/exams")
@RequiredArgsConstructor
public class ExamController {

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
