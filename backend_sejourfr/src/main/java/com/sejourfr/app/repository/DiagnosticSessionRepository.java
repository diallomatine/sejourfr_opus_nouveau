package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;

@Repository
public interface DiagnosticSessionRepository extends JpaRepository<DiagnosticSession, UUID> {

    @Query("""
            SELECT d FROM DiagnosticSession d
            JOIN FETCH d.writtenTask
            JOIN FETCH d.oralTask
            JOIN FETCH d.writtenAttempt
            JOIN FETCH d.oralAttempt
            WHERE d.user.id = :userId
              AND d.diagnosticCode = :code
              AND d.diagnosticVersion = :version
            """)
    Optional<DiagnosticSession> findByUserAndVersionWithContent(
            @Param("userId") UUID userId,
            @Param("code") String code,
            @Param("version") int version);

    @Query("""
            SELECT d FROM DiagnosticSession d
            JOIN FETCH d.writtenTask
            JOIN FETCH d.oralTask
            JOIN FETCH d.writtenAttempt
            JOIN FETCH d.oralAttempt
            WHERE d.id = :id AND d.user.id = :userId
            """)
    Optional<DiagnosticSession> findOwnedWithContent(
            @Param("id") UUID id, @Param("userId") UUID userId);

    @Query("""
            SELECT d FROM DiagnosticSession d
            JOIN FETCH d.writtenTask
            JOIN FETCH d.oralTask
            JOIN FETCH d.writtenAttempt
            JOIN FETCH d.oralAttempt
            WHERE d.writtenAttempt.id = :attemptId OR d.oralAttempt.id = :attemptId
            """)
    Optional<DiagnosticSession> findByAttemptIdWithContent(@Param("attemptId") UUID attemptId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            SELECT d FROM DiagnosticSession d
            JOIN FETCH d.user
            JOIN FETCH d.writtenTask
            JOIN FETCH d.oralTask
            JOIN FETCH d.writtenAttempt
            JOIN FETCH d.oralAttempt
            WHERE d.id = :id
            """)
    Optional<DiagnosticSession> findByIdForUpdate(@Param("id") UUID id);

    Optional<DiagnosticSession> findFirstByUserIdAndStatusOrderByCompletedAtDesc(
            UUID userId, DiagnosticSessionStatus status);

    @Query("""
            SELECT CASE WHEN COUNT(d) > 0 THEN true ELSE false END
            FROM DiagnosticSession d
            WHERE d.writtenAttempt.id = :attemptId OR d.oralAttempt.id = :attemptId
            """)
    boolean existsByAttemptId(@Param("attemptId") UUID attemptId);

    @Modifying
    @Query("DELETE FROM DiagnosticSession d WHERE d.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
