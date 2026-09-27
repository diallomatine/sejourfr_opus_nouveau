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
 * Destinataires et journal des campagnes de service ({@code email_campaign_log}, V080).
 *
 * <p>🛑 Destinataires : compte actif, non supprime, role USER, adresse non
 * anonymisee. Pas de filtre de preference : c'est une information de service
 * (REQUIRED). Un compte deja servi ({@code SENT} / {@code SKIPPED}) est exclu.
 */
public interface EmailCampaignRepository extends Repository<User, UUID> {

    interface Recipient {
        UUID getUserId();
        String getEmail();
    }

    String ELIGIBLE = """
              FROM users u
             WHERE u.deleted_at IS NULL AND u.is_active AND u.role = 'USER'
               AND u.email NOT LIKE '%@anon.sejourfr'
               AND NOT EXISTS (SELECT 1 FROM email_campaign_log l
                                WHERE l.campaign_code = :code AND l.user_id = u.id
                                  AND l.status IN ('SENT', 'SKIPPED'))
            """;

    @Query(value = "SELECT count(*) " + ELIGIBLE, nativeQuery = true)
    long countEligible(@Param("code") String code);

    @Query(value = "SELECT u.id AS userId, u.email AS email " + ELIGIBLE + " ORDER BY u.id LIMIT :limit",
            nativeQuery = true)
    List<Recipient> findEligible(@Param("code") String code, @Param("limit") int limit);

    @Query(value = "SELECT count(*) FROM email_campaign_log WHERE campaign_code = :code AND status = :status",
            nativeQuery = true)
    long countByStatus(@Param("code") String code, @Param("status") String status);

    /**
     * Reserve le compte pour cette vague : ligne PENDING creee, ou ligne FAILED /
     * PENDING orpheline reprise. Une ligne SENT ou SKIPPED n'est jamais reprise.
     *
     * @return 1 si le compte est reserve, 0 s'il est deja servi
     */
    @Modifying
    @Query(value = """
            INSERT INTO email_campaign_log (id, campaign_code, user_id, status, created_at, updated_at)
            VALUES (:id, :code, :userId, 'PENDING', :now, :now)
            ON CONFLICT (campaign_code, user_id) DO UPDATE
               SET status = 'PENDING', updated_at = :now
             WHERE email_campaign_log.status IN ('FAILED', 'PENDING')
            """, nativeQuery = true)
    int claim(@Param("id") UUID id, @Param("code") String code, @Param("userId") UUID userId,
              @Param("now") Instant now);

    @Modifying
    @Query(value = """
            UPDATE email_campaign_log
               SET status = :status, updated_at = :now,
                   sent_at = CASE WHEN :status = 'SENT' THEN CAST(:now AS timestamptz) ELSE sent_at END
             WHERE campaign_code = :code AND user_id = :userId
            """, nativeQuery = true)
    int mark(@Param("code") String code, @Param("userId") UUID userId, @Param("status") String status,
             @Param("now") Instant now);
}
