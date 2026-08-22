package com.sejourfr.app.manager;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.repository.DiagnosticProductionAnalysisRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class DiagnosticProductionAnalysisManager {

    private final DiagnosticProductionAnalysisRepository repository;

    public Optional<DiagnosticProductionAnalysis> findBySubmissionId(UUID submissionId) {
        return repository.findBySubmissionId(submissionId);
    }

    /**
     * Niveaux estimés (EE / EO) par le diagnostic <b>terminé</b> du candidat.
     * Liste vide s'il n'a pas de session {@code COMPLETED} — jamais null.
     */
    public List<DiagnosticEpreuveLevel> findCompletedLevelsByUser(UUID userId) {
        return repository.findCompletedLevelsByUser(userId);
    }

    public DiagnosticProductionAnalysis save(DiagnosticProductionAnalysis analysis) {
        return repository.save(analysis);
    }
}
