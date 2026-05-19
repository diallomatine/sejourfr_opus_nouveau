package com.sejourfr.app.repository;

import com.sejourfr.app.entity.HumanCalibrationNote;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Repository
public interface HumanCalibrationNoteRepository extends JpaRepository<HumanCalibrationNote, UUID> {

    List<HumanCalibrationNote> findBySubmissionIdOrderByCreatedAtDesc(UUID submissionId);

    List<HumanCalibrationNote> findByEvaluatorIdOrderByCreatedAtDesc(UUID evaluatorId, Pageable pageable);

    /** Ecart moyen entre note humaine et IA (dashboard calibration). */
    @Query("SELECT AVG(h.ecartNote) FROM HumanCalibrationNote h WHERE h.ecartNote IS NOT NULL")
    BigDecimal averageEcart();

    /** Nombre de notes humaines avec un ecart absolu strictement superieur a {@code seuil}. */
    @Query("""
            SELECT COUNT(h) FROM HumanCalibrationNote h
            WHERE h.ecartNote IS NOT NULL
              AND ABS(h.ecartNote) > :seuil
            """)
    long countWithEcartAbove(BigDecimal seuil);

    long count();
}
