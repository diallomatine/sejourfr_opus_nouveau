package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.repository.AiEvaluationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
     * La derniere evaluation de CHACUNE des submissions demandees, en une seule
     * requete. Meme regle d'arbitrage que {@link #findLatestBySubmissionId} :
     * la plus recente fait foi, et une date absente ne l'emporte jamais — la
     * requete trie {@code NULLS FIRST}, le {@code put} en ecrasement garde donc
     * la derniere lue.
     *
     * <p>Rend une map vide sans toucher la base quand la liste est vide : un
     * {@code IN ()} n'a pas de sens, et c'est le cas du candidat qui n'a jamais
     * rien rendu.
     */
    public Map<UUID, AiEvaluation> findLatestBySubmissionIds(Collection<UUID> submissionIds) {
        if (submissionIds == null || submissionIds.isEmpty()) return Map.of();
        final Map<UUID, AiEvaluation> latest = new HashMap<>();
        for (final AiEvaluation e : repository.findBySubmissionIds(submissionIds)) {
            if (e.getSubmission() == null) continue;
            latest.put(e.getSubmission().getId(), e);
        }
        return latest;
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

    /** Nombre d'evaluations ayant a la fois le niveau LLM et le niveau calcule (calibration). */
    public long countWithBothNiveaux() {
        return repository.countWithBothNiveaux();
    }

    /** Nombre d'evaluations ou le niveau LLM diverge du niveau calcule (≥ 1 cran). */
    public long countNiveauDivergent() {
        return repository.countNiveauDivergent();
    }
}
