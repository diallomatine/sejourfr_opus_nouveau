package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface DiagnosticProductionAnalysisRepository
        extends JpaRepository<DiagnosticProductionAnalysis, UUID> {

    Optional<DiagnosticProductionAnalysis> findBySubmissionId(UUID submissionId);
}
