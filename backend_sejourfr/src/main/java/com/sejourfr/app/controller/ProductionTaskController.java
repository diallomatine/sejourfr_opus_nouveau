package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.mapper.ProductionTaskMapper;
import com.sejourfr.app.repository.ProductionTaskRepository;
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
public class ProductionTaskController {

    private final ProductionTaskRepository taskRepository;
    private final ProductionTaskMapper mapper;

    public ProductionTaskController(ProductionTaskRepository taskRepository, ProductionTaskMapper mapper) {
        this.taskRepository = taskRepository;
        this.mapper = mapper;
    }

    @GetMapping
    public List<ProductionTaskDto> list(
            @RequestParam EpreuveType epreuve,
            @RequestParam(required = false) String niveau) {

        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }

        List<ProductionTask> tasks = (niveau == null || niveau.isBlank())
            ? taskRepository.findByEpreuveAndActiveTrueOrderByNiveauCibleAscTacheNumeroAsc(epreuve)
            : taskRepository.findByEpreuveAndNiveauCibleAndActiveTrueOrderByTacheNumeroAsc(
                epreuve, niveau.toUpperCase());

        return tasks.stream().map(mapper::toDto).toList();
    }

    @GetMapping("/{id}")
    public ProductionTaskDto detail(@PathVariable UUID id) {
        ProductionTask task = taskRepository.findById(id)
            .orElseThrow(() -> new NotFoundException("Tache introuvable : " + id));
        if (!task.isActive()) {
            // Tache desactivee : non-disponible cote utilisateur final.
            throw new NotFoundException("Tache introuvable : " + id);
        }
        return mapper.toDto(task);
    }
}
