package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AiEvaluationFlag;
import com.sejourfr.app.repository.AiEvaluationFlagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Accès aux signalements admin d'évaluations IA (V085). */
@Component
@RequiredArgsConstructor
public class AiEvaluationFlagManager {

    private final AiEvaluationFlagRepository repository;

    public Optional<AiEvaluationFlag> findById(UUID id) {
        return repository.findById(id);
    }

    /** Tous les signalements d'une production, retirés compris, le plus récent d'abord. */
    public List<AiEvaluationFlag> findBySubmissionId(UUID submissionId) {
        return repository.findBySubmissionIdOrderByCreatedAtDescIdDesc(submissionId);
    }

    public boolean existsActiveForEvaluation(UUID evaluationId) {
        return repository.existsByEvaluationIdAndRemovedAtIsNull(evaluationId);
    }

    /** {@code saveAndFlush} : l'index unique partiel parle tout de suite. */
    public AiEvaluationFlag save(AiEvaluationFlag flag) {
        return repository.saveAndFlush(flag);
    }
}
