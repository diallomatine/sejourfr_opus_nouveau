package com.sejourfr.app.repository;

import com.sejourfr.app.entity.CivicDiagnosticSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CivicDiagnosticSessionRepository
        extends JpaRepository<CivicDiagnosticSession, UUID> {

    @Query("""
            SELECT d FROM CivicDiagnosticSession d
            JOIN FETCH d.attempt
            WHERE d.user.id = :userId
            ORDER BY d.startedAt DESC
            """)
    List<CivicDiagnosticSession> findByUserOrderByStartedAtDesc(@Param("userId") UUID userId);

    @Query("""
            SELECT d FROM CivicDiagnosticSession d
            JOIN FETCH d.attempt
            WHERE d.id = :id
            """)
    Optional<CivicDiagnosticSession> findByIdWithAttempt(@Param("id") UUID id);

    /** Sert au verrou freemium : le premier est offert (20_ §4.3). */
    long countByUserId(UUID userId);
}
