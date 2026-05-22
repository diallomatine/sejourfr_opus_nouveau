package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.repository.AiEvaluationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
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

    /**
     * Toutes les évaluations IA du user pour une épreuve donnée (EE ou EO),
     * niveau CECRL non null. Utilisé par {@link com.sejourfr.app.service.MeService}
     * pour calculer le niveau plafond dans le résumé de progression TCF.
     */
    public List<AiEvaluation> findByUserAndEpreuve(UUID userId, EpreuveType epreuve) {
        return repository.findByUserAndEpreuve(userId, epreuve);
    }

    public AiEvaluation save(AiEvaluation evaluation) {
        return repository.save(evaluation);
    }
}
