package com.sejourfr.app.audioquestion.repository;

import com.sejourfr.app.audioquestion.entity.AudioQuestionGenerationLog;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AudioQuestionGenerationLogRepository extends JpaRepository<AudioQuestionGenerationLog, UUID> {

    long countByAdminUserIdAndStatusAndCreatedAtAfter(
        UUID adminUserId,
        GenerationStatus status,
        Instant createdAtAfter
    );

    @Query("""
        SELECT MIN(l.createdAt) FROM AudioQuestionGenerationLog l
        WHERE l.adminUserId = :adminUserId
          AND l.status = com.sejourfr.app.audioquestion.entity.GenerationStatus.SUCCESS
          AND l.createdAt >= :since
        """)
    Optional<Instant> findOldestRecentSuccessAt(
        @Param("adminUserId") UUID adminUserId,
        @Param("since") Instant since
    );

    @Query("""
        SELECT COALESCE(SUM(COALESCE(l.anthropicCostEur, 0) + COALESCE(l.azureCostEur, 0)), 0)
        FROM AudioQuestionGenerationLog l
        WHERE l.status = com.sejourfr.app.audioquestion.entity.GenerationStatus.SUCCESS
          AND l.createdAt >= :since
        """)
    BigDecimal sumCostSince(@Param("since") Instant since);

    Page<AudioQuestionGenerationLog> findByStatus(GenerationStatus status, Pageable pageable);

    Page<AudioQuestionGenerationLog> findByAdminUserId(UUID adminUserId, Pageable pageable);

    Page<AudioQuestionGenerationLog> findByStatusAndAdminUserId(
        GenerationStatus status,
        UUID adminUserId,
        Pageable pageable
    );

    Optional<AudioQuestionGenerationLog> findFirstByQuestionIdOrderByCreatedAtDesc(UUID questionId);
}
