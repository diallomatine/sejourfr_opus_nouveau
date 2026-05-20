package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.repository.AiEvaluationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link AiEvaluation}.
 * Minimaliste : n'expose que les operations consommees par les services migres.
 */
@Component
@RequiredArgsConstructor
public class AiEvaluationManager {

    private final AiEvaluationRepository repository;

    /** Derniere evaluation IA d'une submission (cf. index idx_ai_eval_submission_latest). */
    public Optional<AiEvaluation> findLatestBySubmissionId(UUID submissionId) {
        return repository.findFirstBySubmissionIdOrderByEvaluatedAtDesc(submissionId);
    }

    public AiEvaluation save(AiEvaluation evaluation) {
        return repository.save(evaluation);
    }
}
