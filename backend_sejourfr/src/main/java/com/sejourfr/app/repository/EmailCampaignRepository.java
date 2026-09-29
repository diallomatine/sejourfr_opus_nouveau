package com.sejourfr.app.repository;

import com.sejourfr.app.entity.User;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Destinataires et journal des campagnes de service ({@code email_campaign_log}, V080-V081).
 *
 * <p>🛑 Destinataires : compte actif, non supprime, role USER, adresse non
 * anonymisee. Pas de filtre de preference : c'est une information de service
 * (REQUIRED). Un compte deja servi ({@code SENT} / {@code SKIPPED}) est exclu.
 *
 * <p>Deux files, servies dans cet ordre : les comptes <b>jamais tentes</b> (sans
 * ligne, ou {@code attempt_count = 0}), puis — seulement quand il n'en reste
 * plus — les comptes a <b>reprendre</b> ({@code FAILED} ou {@code PENDING}
 * orphelin, sous le plafond de tentatives).
 */
public interface EmailCampaignRepository extends Repository<User, UUID> {

    interface Recipient {
        UUID getUserId();
        String getEmail();
    }

    String BASE = """
              FROM users u
              LEFT JOIN email_campaign_log l ON l.campaign_code = :code AND l.user_id = u.id
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND u.email NOT LIKE '%@anon.sejourfr'
            """;

    String NEVER_ATTEMPTED = BASE + " AND (l.id IS NULL OR (l.attempt_count = 0 AND l.status <> 'SENT' "
            + "AND l.status <> 'SKIPPED'))";

    String RETRYABLE = BASE + " AND l.status IN ('FAILED', 'PENDING') AND l.attempt_count > 0 "
            + "AND l.attempt_count < :maxAttempts";

    @Query(value = "SELECT count(*) " + NEVER_ATTEMPTED, nativeQuery = true)
    long countNeverAttempted(@Param("code") String code);

    @Query(value = "SELECT u.id AS userId, u.email AS email " + NEVER_ATTEMPTED + " ORDER BY u.id LIMIT :limit",
            nativeQuery = true)
    List<Recipient> findNeverAttempted(@Param("code") String code, @Param("limit") int limit);

    @Query(value = "SELECT count(*) " + RETRYABLE, nativeQuery = true)
    long countRetryable(@Param("code") String code, @Param("maxAttempts") int maxAttempts);

    @Query(value = "SELECT u.id AS userId, u.email AS email " + RETRYABLE + " ORDER BY u.id LIMIT :limit",
            nativeQuery = true)
    List<Recipient> findRetryable(@Param("code") String code, @Param("maxAttempts") int maxAttempts,
                                  @Param("limit") int limit);

    @Query(value = "SELECT count(*) FROM email_campaign_log WHERE campaign_code = :code AND status = :status",
            nativeQuery = true)
    long countByStatus(@Param("code") String code, @Param("status") String status);

    /**
     * Reserve le compte pour cet envoi et compte la tentative : ligne PENDING
     * creee, ou ligne FAILED / PENDING orpheline reprise sous le plafond. Une
     * ligne SENT ou SKIPPED n'est jamais reprise.
     *
     * @return 1 si le compte est reserve, 0 sinon
     */
    @Modifying
    @Query(value = """
            INSERT INTO email_campaign_log (id, campaign_code, user_id, status, attempt_count,
                                            created_at, updated_at)
            VALUES (:id, :code, :userId, 'PENDING', 1, :now, :now)
            ON CONFLICT (campaign_code, user_id) DO UPDATE
               SET status = 'PENDING', attempt_count = email_campaign_log.attempt_count + 1,
                   updated_at = :now
             WHERE email_campaign_log.status IN ('FAILED', 'PENDING')
               AND email_campaign_log.attempt_count < :maxAttempts
            """, nativeQuery = true)
    int claim(@Param("id") UUID id, @Param("code") String code, @Param("userId") UUID userId,
              @Param("now") Instant now, @Param("maxAttempts") int maxAttempts);

    @Modifying
    @Query(value = """
            UPDATE email_campaign_log
               SET status = :status, updated_at = :now,
                   sent_at = CASE WHEN :status = 'SENT' THEN CAST(:now AS timestamptz) ELSE sent_at END
             WHERE campaign_code = :code AND user_id = :userId
            """, nativeQuery = true)
    int mark(@Param("code") String code, @Param("userId") UUID userId, @Param("status") String status,
             @Param("now") Instant now);

    /** Arret systemique : la tentative n'est pas imputee au compte (il reste dans sa file). */
    @Modifying
    @Query(value = """
            UPDATE email_campaign_log
               SET status = 'FAILED', attempt_count = GREATEST(attempt_count - 1, 0), updated_at = :now
             WHERE campaign_code = :code AND user_id = :userId
            """, nativeQuery = true)
    int releaseAttempt(@Param("code") String code, @Param("userId") UUID userId, @Param("now") Instant now);
}
