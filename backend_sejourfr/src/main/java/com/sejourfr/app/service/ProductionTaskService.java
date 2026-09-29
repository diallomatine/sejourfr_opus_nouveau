package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Orchestration des cas d'usage du catalogue EO/EE expose aux utilisateurs finaux.
 * Le controller ne porte aucune logique : tout passe par ici.
 */
@Service
@RequiredArgsConstructor
public class ProductionTaskService {

    private final ProductionTaskManager taskManager;
    private final ProductionTaskMapper mapper;

    public List<ProductionTaskDto> listActiveTasks(EpreuveType epreuve, String niveau, Short tacheNumero) {
        validateEpreuve(epreuve);
        validateTacheNumero(tacheNumero);

        String niveauUpper = normalizeNiveau(niveau);
        List<ProductionTask> tasks = taskManager.findActive(epreuve, niveauUpper, tacheNumero);

        return tasks.stream().map(mapper::toDto).toList();
    }

    public ProductionTaskDto getActiveTask(UUID id) {
        ProductionTask task = taskManager.findActiveById(id)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + id));
        return mapper.toDto(task);
    }

    private void validateEpreuve(EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }
    }

    private void validateTacheNumero(Short tacheNumero) {
        if (tacheNumero != null && (tacheNumero < 1 || tacheNumero > 3)) {
            throw new BusinessException("tacheNumero doit etre entre 1 et 3.");
        }
    }

    private String normalizeNiveau(String niveau) {
        return (niveau == null || niveau.isBlank()) ? null : niveau.toUpperCase();
    }
}
