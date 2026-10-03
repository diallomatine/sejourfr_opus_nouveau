package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    /**
     * Purge <b>bornée</b> : supprime au plus {@code limit} lignes expirées avant
     * {@code before} (révoquées ou non), les plus anciennes d'abord. Appelée en
     * boucle par {@code RefreshTokenPurgeService}, une transaction par lot. La FK
     * {@code replaced_by} est en {@code ON DELETE SET NULL} (V086) : l'ordre des
     * lots est sans risque.
     */
    @Modifying
    @Query(value = """
            DELETE FROM refresh_tokens
             WHERE jti IN (SELECT jti FROM refresh_tokens
                            WHERE expires_at < :before
                            ORDER BY expires_at
                            LIMIT :limit)
            """, nativeQuery = true)
    int deleteExpiredBefore(@Param("before") Instant before, @Param("limit") int limit);
}
