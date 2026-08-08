package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import org.springframework.stereotype.Component;

@Component
public class ProductionTaskMapper {

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
