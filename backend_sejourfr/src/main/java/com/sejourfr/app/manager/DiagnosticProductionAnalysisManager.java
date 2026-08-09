package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.repository.DiagnosticProductionAnalysisRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class DiagnosticProductionAnalysisManager {

    private final DiagnosticProductionAnalysisRepository repository;

    public Optional<DiagnosticProductionAnalysis> findBySubmissionId(UUID submissionId) {
        return repository.findBySubmissionId(submissionId);
    }

    public DiagnosticProductionAnalysis save(DiagnosticProductionAnalysis analysis) {
        return repository.save(analysis);
    }
}
