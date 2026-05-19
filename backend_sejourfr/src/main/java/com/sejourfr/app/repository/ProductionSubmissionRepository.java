package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProductionSubmissionRepository extends JpaRepository<ProductionSubmission, UUID> {

    /** Toutes les submissions d'un attempt (utile pour assembler le score d'un examen complet). */
    List<ProductionSubmission> findByAttemptIdOrderBySubmittedAtAsc(UUID attemptId);

    /** Historique d'un utilisateur (timeline descendante). */
    List<ProductionSubmission> findByUserIdOrderBySubmittedAtDesc(UUID userId, Pageable pageable);

    /** Quota freemium / anti-abus : compteur cumulatif (a vie) par epreuve. */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
            """)
    long countByUserAndEpreuve(@Param("userId") UUID userId, @Param("epreuve") EpreuveType epreuve);

    /** Historique filtre par epreuve (jointure sur la task). */
    @Query("""
            SELECT s FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
            ORDER BY s.submittedAt DESC
            """)
    List<ProductionSubmission> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable
    );

    /** Submissions non-finalisees (pour reprise / monitoring). */
    List<ProductionSubmission> findByStatutOrderBySubmittedAtAsc(SubmissionStatut statut);
}
