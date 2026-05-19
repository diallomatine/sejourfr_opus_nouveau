package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AiEvaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiEvaluationRepository extends JpaRepository<AiEvaluation, UUID> {

    /** Derniere evaluation d'une submission (cf. index idx_ai_eval_submission_latest). */
    Optional<AiEvaluation> findFirstBySubmissionIdOrderByEvaluatedAtDesc(UUID submissionId);
}
