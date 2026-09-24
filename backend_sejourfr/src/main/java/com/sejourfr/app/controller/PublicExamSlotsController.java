package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExamSlotsDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.examenblanc.ExamSlotsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Variante visiteur de {@link ExamSlotsController} : la même grille, vue sans
 * compte (seul ce qui est offert aux visiteurs y est ouvert).
 */
@RestController
@RequestMapping("/api/public/exam-slots")
@RequiredArgsConstructor
public class PublicExamSlotsController {

    private final ExamSlotsService examSlotsService;

    @GetMapping
    public ExamSlotsDto slots(@RequestParam EpreuveType epreuve) {
        return examSlotsService.slots(null, epreuve);
    }
}
