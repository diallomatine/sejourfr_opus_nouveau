package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExamSlotsDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.examenblanc.ExamSlotsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * La grille des examens blancs d'une épreuve, vue du compte courant : un
 * {@code locked} servi par créneau (les fronts ne le déduisent jamais du rang).
 */
@RestController
@RequestMapping("/api/exam-slots")
@RequiredArgsConstructor
public class ExamSlotsController {

    private final ExamSlotsService examSlotsService;
    private final CurrentUser currentUser;

    @GetMapping
    public ExamSlotsDto slots(@RequestParam EpreuveType epreuve) {
        return examSlotsService.slots(currentUser.getId(), epreuve);
    }
}
