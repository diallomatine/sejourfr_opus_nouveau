package com.sejourfr.app.progression.repository;

import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ProgressionPredictionRepository
        extends JpaRepository<ProgressionPredictionRecord, UUID> {

    /** Les predictions encore sans resultat — celles qu'on peut rattacher. */
    @Query("""
            SELECT p FROM ProgressionPredictionRecord p
            WHERE p.outcomeAt IS NULL
              AND p.engineVersion = :engineVersion
            ORDER BY p.predictedAt ASC
            """)
    List<ProgressionPredictionRecord> findEnAttenteDeResultat(
            @Param("engineVersion") int engineVersion);

    /**
     * La metrique primaire (§47.4) se calcule sur la <b>premiere</b> transition
     * vers SOLID d'un cycle, pour ne pas compter dix fois le meme candidat.
     */
    boolean existsByUserIdAndStateKeyAndLevelCycleIdAndStatus(
            UUID userId, String stateKey, String levelCycleId, ProgressionStatus status);

    @Query("""
            SELECT p FROM ProgressionPredictionRecord p
            WHERE p.status = :status
              AND p.engineVersion = :engineVersion
              AND p.outcomeResult IS NOT NULL
            """)
    List<ProgressionPredictionRecord> findAvecResultat(
            @Param("status") ProgressionStatus status,
            @Param("engineVersion") int engineVersion);

    List<ProgressionPredictionRecord> findByUserIdOrderByPredictedAtAsc(UUID userId);
}
