package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    /**
     * Révoque toutes les sessions actives d'un user. Idempotent — les sessions
     * déjà révoquées ne sont pas touchées (clause WHERE).
     */
    @Modifying
    @Query("UPDATE RefreshToken t SET t.revokedAt = :now "
            + "WHERE t.user.id = :userId AND t.revokedAt IS NULL")
    int revokeAllForUser(UUID userId, Instant now);

    /** Nettoyage des refresh tokens expirés (à appeler depuis un cron job futur). */
    @Modifying
    @Query("DELETE FROM RefreshToken t WHERE t.expiresAt < :before")
    int deleteExpired(Instant before);
}
