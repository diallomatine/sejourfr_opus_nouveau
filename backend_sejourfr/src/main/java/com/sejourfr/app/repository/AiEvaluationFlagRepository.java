package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AiEvaluationFlag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AiEvaluationFlagRepository extends JpaRepository<AiEvaluationFlag, UUID> {

    /** Historique complet d'une production, le plus récent d'abord. */
    List<AiEvaluationFlag> findBySubmissionIdOrderByCreatedAtDescIdDesc(UUID submissionId);

    boolean existsByEvaluationIdAndRemovedAtIsNull(UUID evaluationId);
}
