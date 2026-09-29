package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsEventRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface AnalyticsEventRepository extends JpaRepository<AnalyticsEventRecord, UUID> {

    /**
     * Insere l'evenement, ou ne fait rien si son {@code event_id} ou sa cle de
     * dedoublonnage est deja pose.
     *
     * <p>Native pour le {@code ON CONFLICT DO NOTHING} : l'idempotence est
     * <b>atomique</b> et ne leve jamais. Un « lire puis inserer » cote Java
     * laisserait passer deux insertions concurrentes (double-clic, retry
     * reseau, lot mobile rejoue), et la violation d'unicite empoisonnerait la
     * transaction en cours. <b>Sans cible de conflit</b> : {@code event_id}
     * (idempotence de transport) et {@code dedup_key} (idempotence metier) sont
     * deux contraintes uniques, et l'une OU l'autre suffit a ecarter un rejeu.
     *
     * <p>Le {@code cast} explicite en {@code jsonb} est necessaire : le
     * parametre arrive en {@code text}, et Postgres ne convertit pas
     * implicitement vers {@code jsonb} dans un {@code VALUES}.
     *
     * @return 1 si la ligne vient d'etre creee, 0 sur un rejeu. Les deux cas
     *         sont normaux.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO analytics_event (
                id, event, occurred_at, anonymous_id, session_id, user_id, path, properties, dedup_key,
                event_id, received_at, platform, app_version, diagnostic_type, diagnostic_run_id,
                journey_id, is_internal)
            VALUES (
                :id, :event, :occurredAt, :anonymousId, :sessionId, :userId, :path,
                CAST(:properties AS jsonb), :dedupKey,
                :eventId, :receivedAt, :platform, :appVersion, :diagnosticType, :diagnosticRunId,
                :journeyId, :internal)
            ON CONFLICT DO NOTHING
            """, nativeQuery = true)
    int insertIgnoringDuplicate(@Param("id") UUID id,
                                @Param("event") String event,
                                @Param("occurredAt") Instant occurredAt,
                                @Param("anonymousId") UUID anonymousId,
                                @Param("sessionId") UUID sessionId,
                                @Param("userId") UUID userId,
                                @Param("path") String path,
                                @Param("properties") String properties,
                                @Param("dedupKey") String dedupKey,
                                @Param("eventId") UUID eventId,
                                @Param("receivedAt") Instant receivedAt,
                                @Param("platform") String platform,
                                @Param("appVersion") String appVersion,
                                @Param("diagnosticType") String diagnosticType,
                                @Param("diagnosticRunId") UUID diagnosticRunId,
                                @Param("journeyId") UUID journeyId,
                                @Param("internal") Boolean internal);

    /**
     * Purge de retention : supprime au plus {@code limit} evenements dont la
     * date retenue precede {@code cutoff}. Par lots bornes, une transaction par
     * lot (patron {@code EmailDeliveryRepository.deleteOlderThan}).
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            DELETE FROM analytics_event
             WHERE id IN (SELECT id FROM analytics_event WHERE occurred_at < :cutoff LIMIT :limit)
            """, nativeQuery = true)
    int deleteOlderThan(@Param("cutoff") Instant cutoff, @Param("limit") int limit);

    Optional<AnalyticsEventRecord> findByEventId(UUID eventId);

    /**
     * Detache les evenements d'un compte supprime.
     *
     * <p>La suppression de compte est une <b>anonymisation</b> : la ligne
     * {@code users} survit, donc le {@code ON DELETE SET NULL} de la base ne se
     * declenche pas. Le detachement doit etre explicite, comme la purge de
     * {@code user_funnel_events}. Les evenements eux-memes restent : ce sont
     * des gestes anonymes, ils comptent dans l'audience et ne nomment plus
     * personne.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE AnalyticsEventRecord e SET e.userId = NULL WHERE e.userId = :userId")
    int detachUser(@Param("userId") UUID userId);

    long countByAnonymousId(UUID anonymousId);
}
