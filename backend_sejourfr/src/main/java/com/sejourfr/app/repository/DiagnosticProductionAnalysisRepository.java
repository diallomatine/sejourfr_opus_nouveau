package com.sejourfr.app.repository;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DiagnosticProductionAnalysisRepository
        extends JpaRepository<DiagnosticProductionAnalysis, UUID> {

    Optional<DiagnosticProductionAnalysis> findBySubmissionId(UUID submissionId);

    /**
     * Niveaux estimés par le diagnostic <b>terminé</b> d'un candidat, une ligne
     * par production analysée (donc au plus une EE et une EO par session).
     *
     * <p>Seules les sessions {@code COMPLETED} comptent : une session en cours
     * ou {@code FAILED} n'a pas de verdict opposable. Le rattachement passe par
     * les deux attempts de la session — c'est la seule chose qui relie une
     * soumission diagnostique à sa session.
     */
    @Query("""
            SELECT new com.sejourfr.app.dto.DiagnosticEpreuveLevel(pt.epreuve, a.levelEstimate)
            FROM DiagnosticProductionAnalysis a
            JOIN a.submission s
            JOIN s.productionTask pt
            WHERE s.user.id = :userId
              AND s.diagnostic = true
              AND a.levelEstimate IS NOT NULL
              AND EXISTS (
                  SELECT 1 FROM DiagnosticSession ds
                    LEFT JOIN ds.oralAttempt oa
                  WHERE ds.user.id = :userId
                    AND ds.status = com.sejourfr.app.enums.DiagnosticSessionStatus.COMPLETED
                    AND (ds.writtenAttempt.id = s.attempt.id
                         OR oa.id = s.attempt.id))
            """)
    List<DiagnosticEpreuveLevel> findCompletedLevelsByUser(@Param("userId") UUID userId);
}
