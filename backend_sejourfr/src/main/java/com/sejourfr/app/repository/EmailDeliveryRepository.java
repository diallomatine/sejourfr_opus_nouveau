package com.sejourfr.app.repository;

import com.sejourfr.app.entity.EmailDelivery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface EmailDeliveryRepository extends JpaRepository<EmailDelivery, UUID> {

    /**
     * 🛑 L'anti-doublon du brief : « INSERT PENDING d'abord, jamais SELECT puis
     * INSERT ». {@code ON CONFLICT DO NOTHING} sur l'index unique partiel
     * {@code ux_email_deliveries_dedup} : la ligne perdante n'est pas une erreur,
     * elle rend 0. Deux appels concurrents sur une meme cle => une seule ligne.
     *
     * @return 1 si cette ligne a ete ecrite, 0 si la cle etait deja occupee
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            INSERT INTO email_deliveries (id, user_id, email_type, category, recipient,
                                          status, provider, deduplication_key, reference_id,
                                          occurred_at, skip_reason, attempt_count, created_at)
            VALUES (:id, CAST(:userId AS uuid), :type, :category, :recipient,
                    :status, :provider, :dedupKey, CAST(:referenceId AS uuid),
                    CAST(:occurredAt AS timestamptz), :skipReason, 0, :createdAt)
            ON CONFLICT (deduplication_key) WHERE status IN ('PENDING', 'SENT', 'SKIPPED')
            DO NOTHING
            """, nativeQuery = true)
    int insertIfKeyFree(@Param("id") UUID id,
                        @Param("userId") String userId,
                        @Param("type") String type,
                        @Param("category") String category,
                        @Param("recipient") String recipient,
                        @Param("status") String status,
                        @Param("provider") String provider,
                        @Param("dedupKey") String dedupKey,
                        @Param("referenceId") String referenceId,
                        @Param("occurredAt") String occurredAt,
                        @Param("skipReason") String skipReason,
                        @Param("createdAt") Instant createdAt);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE EmailDelivery d
               SET d.status = com.sejourfr.app.enums.EmailDeliveryStatus.SENT,
                   d.sentAt = :sentAt, d.providerMessageId = :providerMessageId,
                   d.attemptCount = :attempts, d.errorMessage = NULL
             WHERE d.id = :id
            """)
    int markSent(@Param("id") UUID id, @Param("sentAt") Instant sentAt,
                 @Param("providerMessageId") String providerMessageId,
                 @Param("attempts") short attempts);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE EmailDelivery d
               SET d.status = com.sejourfr.app.enums.EmailDeliveryStatus.FAILED,
                   d.failedAt = :failedAt, d.errorMessage = :error, d.attemptCount = :attempts
             WHERE d.id = :id
            """)
    int markFailed(@Param("id") UUID id, @Param("failedAt") Instant failedAt,
                   @Param("error") String error, @Param("attempts") short attempts);

    /** PENDING bloques : passent FAILED avec l'erreur « stale ». */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE EmailDelivery d
               SET d.status = com.sejourfr.app.enums.EmailDeliveryStatus.FAILED,
                   d.failedAt = :now, d.errorMessage = 'stale'
             WHERE d.status = com.sejourfr.app.enums.EmailDeliveryStatus.PENDING
               AND d.createdAt < :before
            """)
    int markStalePending(@Param("before") Instant before, @Param("now") Instant now);

    /**
     * Mails ENGAGEMENT deja partis (ou en cours) pour ce compte depuis
     * {@code since} — la base du plafond du jour. FAILED et SKIPPED ne comptent
     * pas : ils ne sont pas arrives.
     */
    @Query("""
            SELECT count(d) FROM EmailDelivery d
             WHERE d.userId = :userId
               AND d.category = com.sejourfr.app.enums.EmailCategory.ENGAGEMENT
               AND d.status IN (com.sejourfr.app.enums.EmailDeliveryStatus.PENDING,
                                com.sejourfr.app.enums.EmailDeliveryStatus.SENT)
               AND d.createdAt >= :since
            """)
    long countEngagementSince(@Param("userId") UUID userId, @Param("since") Instant since);

    @Query("""
            SELECT count(d) FROM EmailDelivery d
             WHERE d.deduplicationKey = :key
               AND d.status = com.sejourfr.app.enums.EmailDeliveryStatus.FAILED
            """)
    long countFailedByKey(@Param("key") String key);

    /**
     * Les cles d'un mail EVENEMENTIEL a relancer : dont toutes les lignes sont
     * FAILED, dont la PREMIERE ligne est dans la fenetre, et qui n'ont pas epuise
     * leurs tentatives. Une ligne par cle (la plus recente).
     */
    @Query(value = """
            SELECT DISTINCT ON (d.deduplication_key) d.*
              FROM email_deliveries d
             WHERE d.status = 'FAILED'
               AND d.email_type IN (:types)
               AND d.deduplication_key IS NOT NULL
               AND NOT EXISTS (SELECT 1 FROM email_deliveries o
                                WHERE o.deduplication_key = d.deduplication_key
                                  AND o.status IN ('PENDING', 'SENT', 'SKIPPED'))
               AND (SELECT min(f.created_at) FROM email_deliveries f
                     WHERE f.deduplication_key = d.deduplication_key) >= :since
               AND (SELECT count(*) FROM email_deliveries c
                     WHERE c.deduplication_key = d.deduplication_key) < :maxRows
             ORDER BY d.deduplication_key, d.created_at DESC
             LIMIT :limit
            """, nativeQuery = true)
    List<EmailDelivery> findEventRetryCandidates(@Param("types") Collection<String> types,
                                                 @Param("since") Instant since,
                                                 @Param("maxRows") int maxRows,
                                                 @Param("limit") int limit);

    /** Purge de retention, par lots bornes (jamais toute la table d'un coup). */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            DELETE FROM email_deliveries
             WHERE id IN (SELECT id FROM email_deliveries
                           WHERE created_at < :cutoff
                           LIMIT :limit)
            """, nativeQuery = true)
    int deleteOlderThan(@Param("cutoff") Instant cutoff, @Param("limit") int limit);

    /**
     * Suppression du compte : ses lignes, ET celles envoyees a son adresse sans
     * compte rattache (accuse de contact, reponse du support).
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            DELETE FROM email_deliveries
             WHERE user_id = :userId
                OR (user_id IS NULL AND lower(recipient) = lower(:email))
            """, nativeQuery = true)
    int deleteForAccount(@Param("userId") UUID userId, @Param("email") String email);

    List<EmailDelivery> findByDeduplicationKeyOrderByCreatedAtAsc(String deduplicationKey);

    List<EmailDelivery> findByUserIdOrderByCreatedAtAsc(UUID userId);
}
