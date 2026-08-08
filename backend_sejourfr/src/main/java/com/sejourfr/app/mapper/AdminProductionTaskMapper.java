package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import org.springframework.stereotype.Component;

/**
 * Vue console d'un sujet de production. Distincte de {@link ProductionTaskMapper}
 * (vue candidat) : elle expose {@code active} et sert aussi les sujets
 * depublies.
 */
@Component
public class AdminProductionTaskMapper {

    public AdminProductionTaskDto toDto(ProductionTask task) {
        return new AdminProductionTaskDto(
                task.getId(),
                task.getEpreuve(),
                task.getTacheNumero() != null ? task.getTacheNumero() : 0,
                task.getNiveauCible(),
                task.getTitre(),
                task.getConsigne(),
                task.getContexte(),
                task.isActive());
    }
}
