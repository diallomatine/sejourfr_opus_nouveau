package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.repository.ProductionTaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link ProductionTask}.
 * Seule classe autorisee a appeler {@link ProductionTaskRepository}.
 */
@Component
@RequiredArgsConstructor
public class ProductionTaskManager {

    private final ProductionTaskRepository repository;

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
}
