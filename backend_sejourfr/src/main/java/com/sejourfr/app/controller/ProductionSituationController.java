package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionSituationDto;
import com.sejourfr.app.service.ProductionSituationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Detail d'une situation d'entrainement EO/EE (lecture seule, apprenant).
 * Seules les situations {@code is_active = true} sont exposees.
 */
@RestController
@RequestMapping("/api/production-situations")
@RequiredArgsConstructor
public class ProductionSituationController {

    private final ProductionSituationService productionSituationService;

    @GetMapping("/{id}")
    public ProductionSituationDto detail(@PathVariable UUID id) {
        return productionSituationService.getDetail(id);
    }
}
