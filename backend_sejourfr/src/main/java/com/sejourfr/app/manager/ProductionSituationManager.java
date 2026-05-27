package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionSituation;
import com.sejourfr.app.entity.ProductionSituationMedia;
import com.sejourfr.app.repository.ProductionSituationMediaRepository;
import com.sejourfr.app.repository.ProductionSituationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour les situations (sujets) d'entrainement EO/EE
 * et leurs supports visuels. Les exemples-modeles vivent cote tache
 * ({@link ProductionTaskManager}).
 */
@Component
@RequiredArgsConstructor
public class ProductionSituationManager {

    private final ProductionSituationRepository situationRepository;
    private final ProductionSituationMediaRepository mediaRepository;

    public List<ProductionSituation> findActiveByTask(UUID taskId) {
        return situationRepository.findByTaskIdAndActiveTrueOrderByDisplayOrderAsc(taskId);
    }

    public Optional<ProductionSituation> findActiveById(UUID id) {
        return situationRepository.findByIdAndActiveTrue(id);
    }

    public List<ProductionSituationMedia> findMedias(UUID situationId) {
        return mediaRepository.findBySituationIdOrderByDisplayOrderAsc(situationId);
    }

    public List<ProductionSituationMedia> findMediasFor(Collection<UUID> situationIds) {
        if (situationIds.isEmpty()) return List.of();
        return mediaRepository.findBySituationIdInOrderByDisplayOrderAsc(situationIds);
    }
}
