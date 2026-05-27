package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.dto.ProductionSituationDto;
import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.ProductionSituationService;
import com.sejourfr.app.service.ProductionTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Catalogue des consignes EO/EE (lecture seule pour l'utilisateur final).
 * Seules les tasks {@code is_active = true} sont exposees.
 */
@RestController
@RequestMapping("/api/production-tasks")
@RequiredArgsConstructor
public class ProductionTaskController {

    private final ProductionTaskService productionTaskService;
    private final ProductionSituationService productionSituationService;

    @GetMapping
    public List<ProductionTaskDto> list(
            @RequestParam EpreuveType epreuve,
            @RequestParam(required = false) String niveau,
            @RequestParam(required = false) Short tacheNumero) {
        return productionTaskService.listActiveTasks(epreuve, niveau, tacheNumero);
    }

    @GetMapping("/{id}")
    public ProductionTaskDto detail(@PathVariable UUID id) {
        return productionTaskService.getActiveTask(id);
    }

    /** Sujets d'entrainement actifs d'une tache (situations + supports visuels). */
    @GetMapping("/{id}/situations")
    public List<ProductionSituationDto> situations(@PathVariable UUID id) {
        return productionSituationService.listByTask(id);
    }

    /** Exemples-modeles d'une tache (independants du sujet choisi). */
    @GetMapping("/{id}/examples")
    public List<ProductionExampleDto> examples(@PathVariable UUID id) {
        return productionSituationService.listExamples(id);
    }
}
