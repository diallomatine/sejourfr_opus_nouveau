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

    public ProductionSubmission save(ProductionSubmission submission) {
        return repository.save(submission);
    }

    public long countByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.countByUserAndEpreuve(userId, epreuve);
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
