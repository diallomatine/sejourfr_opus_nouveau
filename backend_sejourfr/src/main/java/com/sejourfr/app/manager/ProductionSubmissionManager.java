package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.repository.ProductionSubmissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link ProductionSubmission}.
 * Seule classe autorisee a appeler {@link ProductionSubmissionRepository}.
 */
@Component
@RequiredArgsConstructor
public class ProductionSubmissionManager {

    private final ProductionSubmissionRepository repository;

    public Optional<ProductionSubmission> findById(UUID id) {
        return repository.findById(id);
    }

    /** Submission avec sa {@code productionTask} eager-loadée (retry hors session Hibernate). */
    public Optional<ProductionSubmission> findByIdWithTask(UUID id) {
        return repository.findByIdWithTask(id);
    }

    public ProductionSubmission save(ProductionSubmission submission) {
        return repository.save(submission);
    }

    /** Toutes les submissions liées à un attempt EE/EO (utile pour assembler un examen blanc complet). */
    public List<ProductionSubmission> findByAttemptId(UUID attemptId) {
        return repository.findByAttemptIdOrderBySubmittedAtAsc(attemptId);
    }

    public long countByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.countByUserAndEpreuve(userId, epreuve);
    }

    /** Soumissions d'entrainement seules (hors sessions d'examen blanc). */
    public long countTrainingByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.countTrainingByUserAndEpreuve(userId, epreuve);
    }

    /**
     * Vrai si l'utilisateur a déjà soumis au moins une tâche EE/EO dans un
     * examen blanc TCF complet. Au-delà, les examens complets gratuits
     * verrouillent EE/EO (freebie consommé).
     */
    public boolean hasFullExamProductionSubmission(UUID userId) {
        return repository.countByUserAndParentEpreuve(userId, EpreuveType.TCF_COMPLET) > 0;
    }

    /** Historique utilisateur, tri descendant, plafonne par {@code limit}. */
    public List<ProductionSubmission> findRecentByUser(UUID userId, int limit) {
        return repository.findByUserIdOrderBySubmittedAtDesc(userId, PageRequest.of(0, limit));
    }

    /** Historique utilisateur filtre par epreuve, tri descendant, plafonne par {@code limit}. */
    public List<ProductionSubmission> findRecentByUserAndEpreuve(UUID userId, EpreuveType epreuve, int limit) {
        return repository.findByUserAndEpreuve(userId, epreuve, PageRequest.of(0, limit));
    }

    /** 0 a 3 lignes : derniere submission par numero de tache (hub d'entrainement). */
    public List<ProductionSubmission> findLatestPerTask(UUID userId, EpreuveType epreuve, String niveauCible) {
        return repository.findLatestPerTask(userId, epreuve.name(), niveauCible);
    }

    /** Submissions par statut, tri par date de soumission asc (calibration admin). */
    public List<ProductionSubmission> findByStatutOrderedBySubmittedAt(SubmissionStatut statut) {
        return repository.findByStatutOrderBySubmittedAtAsc(statut);
    }
}
