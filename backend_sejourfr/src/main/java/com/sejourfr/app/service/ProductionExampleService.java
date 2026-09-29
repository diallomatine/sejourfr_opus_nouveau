package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionExampleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Lecture des exemples-modeles d'une categorie (epreuve, tacheNumero) exposés à
 * l'apprenant. Indépendants du sujet précis qu'il a choisi.
 */
@Service
@RequiredArgsConstructor
public class ProductionExampleService {

    private final ProductionTaskManager taskManager;
    private final ProductionExampleMapper mapper;

    public List<ProductionExampleDto> listByEpreuveAndTache(EpreuveType epreuve, short tacheNumero) {
        if (epreuve != EpreuveType.TCF_EO && epreuve != EpreuveType.TCF_EE) {
            throw new BusinessException("epreuve doit etre TCF_EO ou TCF_EE.");
        }
        if (tacheNumero < 1 || tacheNumero > 3) {
            throw new BusinessException("tacheNumero doit etre entre 1 et 3.");
        }
        return taskManager.findExamplesByEpreuveAndTache(epreuve, tacheNumero).stream()
                .map(mapper::toDto)
                .toList();
    }
}
