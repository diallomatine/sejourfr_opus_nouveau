package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ExampleAudioStatus;
import com.sejourfr.app.repository.ProductionExampleRepository;
import com.sejourfr.app.repository.ProductionTaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.Collection;
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
        return repository.findById(id)
                .filter(ProductionTask::isActive)
                .filter(task -> !task.isDiagnostic());
    }

    /** Lookup candidat réservé au parcours diagnostic. */
    public Optional<ProductionTask> findActiveDiagnosticById(UUID id) {
        return repository.findById(id)
                .filter(ProductionTask::isActive)
                .filter(ProductionTask::isDiagnostic);
    }

    /**
     * Retourne le catalogue actif filtre selon les parametres presents.
     * Les parametres null sont ignores (pas de filtre sur cet axe).
     */
    public List<ProductionTask> findActive(EpreuveType epreuve, String niveauCible, Short tacheNumero) {
        if (niveauCible != null && tacheNumero != null) {
            return repository.findByEpreuveAndNiveauCibleAndTacheNumeroAndActiveTrueAndDiagnosticCodeIsNullOrderByCreatedAtAsc(
                    epreuve, niveauCible, tacheNumero);
        }
        if (niveauCible != null) {
            return repository.findByEpreuveAndNiveauCibleAndActiveTrueAndDiagnosticCodeIsNullOrderByTacheNumeroAsc(
                    epreuve, niveauCible);
        }
        if (tacheNumero != null) {
            return repository.findByEpreuveAndTacheNumeroAndActiveTrueAndDiagnosticCodeIsNullOrderByNiveauCibleAscCreatedAtAsc(
                    epreuve, tacheNumero);
        }
        return repository.findByEpreuveAndActiveTrueAndDiagnosticCodeIsNullOrderByNiveauCibleAscTacheNumeroAsc(epreuve);
    }

    /** Toutes les taches actives (toutes epreuves/niveaux) — validation des rubriques au boot. */
    public List<ProductionTask> findAllActive() {
        return repository.findByActiveTrueAndDiagnosticCodeIsNull();
    }

    public Optional<Integer> findLatestActiveDiagnosticVersion(String code) {
        return repository.findLatestActiveDiagnosticVersion(code);
    }

    public Optional<ProductionTask> findActiveDiagnostic(
            String code, int version, EpreuveType epreuve) {
        return repository.findByDiagnosticCodeAndDiagnosticVersionAndEpreuveAndActiveTrue(
                code, version, epreuve);
    }

    /** Catalogue d'une epreuve, <b>desactivees comprises</b> : console admin uniquement. */
    public List<ProductionTask> findAllByEpreuve(EpreuveType epreuve) {
        return repository.findByEpreuveOrderByNiveauCibleAscTacheNumeroAsc(epreuve);
    }

    /** Catalogue administrable classique ; les sujets diagnostic restent seed-only. */
    public List<ProductionTask> findAllStandardByEpreuve(EpreuveType epreuve) {
        return repository.findByEpreuveOrderByNiveauCibleAscTacheNumeroAsc(epreuve).stream()
                .filter(task -> !task.isDiagnostic())
                .toList();
    }

    public ProductionTask save(ProductionTask task) {
        return repository.save(task);
    }

    /** Exemples-modeles d'une categorie (epreuve, tacheNumero). */
    public List<ProductionExample> findExamplesByEpreuveAndTache(EpreuveType epreuve, short tacheNumero) {
        return exampleRepository.findByEpreuveAndTache(epreuve, tacheNumero);
    }

    public Optional<ProductionExample> findExampleById(UUID id) {
        return exampleRepository.findById(id);
    }

    public ProductionExample saveExample(ProductionExample example) {
        return exampleRepository.save(example);
    }

    /** Exemples EO sans audio, dans un statut relançable, les plus anciens d'abord. */
    public List<ProductionExample> findEoExamplesNeedingAudio(Collection<ExampleAudioStatus> statuses, int limit) {
        return exampleRepository.findNeedingAudio(EpreuveType.TCF_EO, statuses, PageRequest.of(0, limit));
    }

    public long countEoExamplesNeedingAudio(Collection<ExampleAudioStatus> statuses) {
        return exampleRepository.countNeedingAudio(EpreuveType.TCF_EO, statuses);
    }

    public List<ProductionExample> findEoExamplesByAudioStatus(ExampleAudioStatus status) {
        return exampleRepository.findByEpreuveAndAudioStatus(EpreuveType.TCF_EO, status);
    }
}
