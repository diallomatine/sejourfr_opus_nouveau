package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import org.springframework.stereotype.Component;

@Component
public class ProductionTaskMapper {

    /**
     * ⚠️ <b>Une seule forme depuis le 2026-09-13</b> : la surcharge de session
     * portait {@code conditionsReelles}, dont la regle est revoquee — toute
     * tache se joue en conditions d'examen.
     */
    public ProductionTaskDto toDto(ProductionTask task) {
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
            task.getMotsMax()
        );
    }
}
