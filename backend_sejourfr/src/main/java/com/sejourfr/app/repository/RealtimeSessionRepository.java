package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.UUID;

@Repository
public interface RealtimeSessionRepository extends JpaRepository<RealtimeSession, UUID> {

    /**
     * Sessions reellement consommees sur un pass : connexion etablie (ACTIVE) ou
     * terminee (COMPLETED). C'est la base du decompte de quota. Une session
     * PENDING jamais connectee ou FAILED ne compte pas.
     */
    @Query("""
            SELECT COUNT(s) FROM RealtimeSession s
            WHERE s.subscription.id = :subscriptionId
              AND s.status IN (com.sejourfr.app.enums.RealtimeSessionStatus.ACTIVE,
                               com.sejourfr.app.enums.RealtimeSessionStatus.COMPLETED)
            """)
    long countConsumed(@Param("subscriptionId") UUID subscriptionId);

    /**
     * Sessions PENDING recentes (token encore valide) : elles "reservent" un
     * slot le temps que le client se connecte, pour eviter qu'un mint en rafale
     * depasse le cap avant que le debit (sur ACTIVE) ne s'applique.
     */
    @Query("""
            SELECT COUNT(s) FROM RealtimeSession s
            WHERE s.subscription.id = :subscriptionId
              AND s.status = com.sejourfr.app.enums.RealtimeSessionStatus.PENDING
              AND s.startedAt > :cutoff
            """)
    long countRecentPending(@Param("subscriptionId") UUID subscriptionId,
                            @Param("cutoff") Instant cutoff);

    long countByStatus(RealtimeSessionStatus status);
}
