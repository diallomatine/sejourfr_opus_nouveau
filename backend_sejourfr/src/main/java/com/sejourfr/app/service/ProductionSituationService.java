package com.sejourfr.app.service;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.dto.ProductionSituationDto;
import com.sejourfr.app.entity.ProductionSituation;
import com.sejourfr.app.entity.ProductionSituationMedia;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionSituationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.mapper.ProductionSituationMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Lecture du contenu d'entrainement expose a l'apprenant :
 *   - les SUJETS (situations) d'une tache, avec leurs supports visuels ;
 *   - les MODELES (exemples) d'une tache, independants du sujet choisi.
 * Le chargement des supports se fait en lot pour eviter le N+1.
 */
@Service
@RequiredArgsConstructor
public class ProductionSituationService {

    private final ProductionTaskManager taskManager;
    private final ProductionSituationManager situationManager;
    private final ProductionSituationMapper mapper;

    public List<ProductionSituationDto> listByTask(UUID taskId) {
        taskManager.findActiveById(taskId)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));

        List<ProductionSituation> situations = situationManager.findActiveByTask(taskId);
        if (situations.isEmpty()) return List.of();

        List<UUID> ids = situations.stream().map(ProductionSituation::getId).toList();
        Map<UUID, List<ProductionSituationMedia>> mediasBySituation = situationManager.findMediasFor(ids).stream()
                .collect(Collectors.groupingBy(ProductionSituationMedia::getSituationId));

        return situations.stream()
                .map(s -> mapper.toDto(s, mediasBySituation.getOrDefault(s.getId(), List.of())))
                .toList();
    }

    public ProductionSituationDto getDetail(UUID situationId) {
        ProductionSituation situation = situationManager.findActiveById(situationId)
                .orElseThrow(() -> new NotFoundException("Situation introuvable : " + situationId));
        return mapper.toDto(situation, situationManager.findMedias(situationId));
    }

    /** Exemples-modeles d'une tache (indépendants du sujet choisi dans le carrousel). */
    public List<ProductionExampleDto> listExamples(UUID taskId) {
        taskManager.findActiveById(taskId)
                .orElseThrow(() -> new NotFoundException("Tache introuvable : " + taskId));
        return taskManager.findExamplesByTask(taskId).stream()
                .map(mapper::toExampleDto)
                .toList();
    }
}
