package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiEvaluationRepository extends JpaRepository<AiEvaluation, UUID> {

    /** Derniere evaluation d'une submission (cf. index idx_ai_eval_submission_latest). */
    Optional<AiEvaluation> findFirstBySubmissionIdOrderByEvaluatedAtDesc(UUID submissionId);

    /**
     * Toutes les évaluations IA du user pour une épreuve donnée (EE ou EO),
     * avec un niveau CECRL non null. Sert à calculer le niveau plafond
     * dans le résumé de progression TCF.
     */
    @Query("""
            SELECT e FROM AiEvaluation e
            WHERE e.submission.user.id = :userId
              AND e.submission.productionTask.epreuve = :epreuve
              AND e.niveauCecrl IS NOT NULL
            """)
    List<AiEvaluation> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve);
}
