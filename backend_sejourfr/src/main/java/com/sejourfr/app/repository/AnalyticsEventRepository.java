package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsEventRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

public interface AnalyticsEventRepository extends JpaRepository<AnalyticsEventRecord, UUID> {

    /**
     * Insere l'evenement, ou ne fait rien si sa cle de dedoublonnage est deja
     * posee.
     *
     * <p>Native pour le {@code ON CONFLICT DO NOTHING} : l'idempotence est
     * <b>atomique</b> et ne leve jamais. Un « lire puis inserer » cote Java
     * laisserait passer deux insertions concurrentes (double-clic, retry
     * reseau), et la violation d'unicite empoisonnerait la transaction en
     * cours.
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
                id, event, occurred_at, anonymous_id, session_id, user_id, path, properties, dedup_key)
            VALUES (
                :id, :event, :occurredAt, :anonymousId, :sessionId, :userId, :path,
                CAST(:properties AS jsonb), :dedupKey)
            ON CONFLICT (dedup_key) DO NOTHING
            """, nativeQuery = true)
    int insertIgnoringDuplicate(@Param("id") UUID id,
                                @Param("event") String event,
                                @Param("occurredAt") Instant occurredAt,
                                @Param("anonymousId") UUID anonymousId,
                                @Param("sessionId") UUID sessionId,
                                @Param("userId") UUID userId,
                                @Param("path") String path,
                                @Param("properties") String properties,
                                @Param("dedupKey") String dedupKey);

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
