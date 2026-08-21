package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserFunnelEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface UserFunnelEventRepository extends JpaRepository<UserFunnelEvent, UUID> {

    /**
     * Pose la PREMIERE occurrence de l'evenement pour ce compte, ou ne fait
     * rien.
     *
     * <p>Requete native pour le {@code ON CONFLICT DO NOTHING} de Postgres :
     * l'idempotence est ainsi <strong>atomique</strong> et ne leve jamais. Un
     * « lire puis inserer » cote Java aurait laisse passer deux insertions
     * concurrentes (double-clic, retry client), et la violation d'unicite
     * aurait alors empoisonne la transaction en cours — ici, le paiement.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO user_funnel_events (id, user_id, event, platform, source, occurred_at)
            VALUES (:id, :userId, :event, :platform, :source, now())
            ON CONFLICT ON CONSTRAINT uq_user_funnel_event DO NOTHING
            """, nativeQuery = true)
    int recordFirstOccurrence(@Param("id") UUID id,
                              @Param("userId") UUID userId,
                              @Param("event") String event,
                              @Param("platform") String platform,
                              @Param("source") String source);

    /**
     * Purge les evenements d'un compte. La suppression de compte est une
     * ANONYMISATION (la ligne {@code users} survit), donc la cascade base ne
     * se declenche pas : la purge doit etre explicite, comme celle des
     * observations du Plan et des sessions de diagnostic.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM UserFunnelEvent e WHERE e.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);

    long countByUserId(UUID userId);
}
