package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import org.springframework.stereotype.Component;

@Component
public class ProductionTaskMapper {

    /**
     * Vue catalogue : {@code conditionsReelles} reste {@code null} — hors
     * session, la question n'a pas de reponse.
     */
    public ProductionTaskDto toDto(ProductionTask task) {
        return toDto(task, null);
    }

    /**
     * Vue de session : le fait « en conditions reelles ? » est derive par
     * {@code ProductionExamConditions} et servi tel quel aux deux runners.
     */
    public ProductionTaskDto toDto(ProductionTask task, Boolean conditionsReelles) {
        return new ProductionTaskDto(
            task.getId(),
            task.getEpreuve(),
            task.getTacheNumero() != null ? task.getTacheNumero() : 0,
            task.getNiveauCible(),
            task.getTitre(),
            task.getConsigne(),
            task.getContexte(),
            task.getDureeMaxSec(),
            task.getDureeMinSec(),
            task.getMotsMin(),
            task.getMotsMax(),
            conditionsReelles
        );
    }
}
