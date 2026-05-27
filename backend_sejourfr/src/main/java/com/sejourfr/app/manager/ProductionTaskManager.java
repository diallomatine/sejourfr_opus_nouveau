package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.repository.ProductionExampleRepository;
import com.sejourfr.app.repository.ProductionTaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link ProductionTask} et ses exemples-modeles
 * ({@link ProductionExample}, rattaches a la tache). Seule classe autorisee a
 * appeler les repositories correspondants.
 */
@Component
@RequiredArgsConstructor
public class ProductionTaskManager {

    private final ProductionTaskRepository repository;
    private final ProductionExampleRepository exampleRepository;

    public Optional<ProductionTask> findById(UUID id) {
        return repository.findById(id);
    }

    /** Variante qui filtre les taches desactivees (vue cote utilisateur final). */
    public Optional<ProductionTask> findActiveById(UUID id) {
        return repository.findById(id).filter(ProductionTask::isActive);
    }

    /**
     * Retourne le catalogue actif filtre selon les parametres presents.
     * Les parametres null sont ignores (pas de filtre sur cet axe).
     */
    public List<ProductionTask> findActive(EpreuveType epreuve, String niveauCible, Short tacheNumero) {
        if (niveauCible != null && tacheNumero != null) {
            return repository.findByEpreuveAndNiveauCibleAndTacheNumeroAndActiveTrueOrderByCreatedAtAsc(
                    epreuve, niveauCible, tacheNumero);
        }
        if (niveauCible != null) {
            return repository.findByEpreuveAndNiveauCibleAndActiveTrueOrderByTacheNumeroAsc(
                    epreuve, niveauCible);
        }
        return repository.findByEpreuveAndActiveTrueOrderByNiveauCibleAscTacheNumeroAsc(epreuve);
    }

    /** Exemples-modeles d'une tache (independants du sujet choisi). */
    public List<ProductionExample> findExamplesByTask(UUID taskId) {
        return exampleRepository.findByTaskIdOrderByDisplayOrderAsc(taskId);
    }
}
