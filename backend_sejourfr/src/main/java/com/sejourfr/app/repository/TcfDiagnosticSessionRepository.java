package com.sejourfr.app.repository;

import com.sejourfr.app.entity.TcfDiagnosticSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TcfDiagnosticSessionRepository extends JpaRepository<TcfDiagnosticSession, UUID> {

    /** Le diagnostic le plus recent d'un candidat, termine ou non. */
    @Query("""
            SELECT d FROM TcfDiagnosticSession d
            JOIN FETCH d.parentAttempt
            WHERE d.user.id = :userId
            ORDER BY d.startedAt DESC
            """)
    List<TcfDiagnosticSession> findByUserOrderByStartedAtDesc(@Param("userId") UUID userId);

    @Query("""
            SELECT d FROM TcfDiagnosticSession d
            JOIN FETCH d.parentAttempt
            WHERE d.id = :id
            """)
    Optional<TcfDiagnosticSession> findByIdWithParent(@Param("id") UUID id);

    /**
     * Combien de diagnostics ce candidat a-t-il deja ouverts ? Sert au verrou
     * freemium : le premier est offert, les suivants sont une reevaluation
     * premium (10_ §4.6).
     */
    long countByUserId(UUID userId);
}
