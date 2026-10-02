package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.enums.AccessOverrideType;
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
public interface AccessOverrideRepository extends JpaRepository<AccessOverride, UUID> {

    /** Les décisions COURANTES d'un compte (non remplacées) : la seule entrée du calcul d'accès. */
    List<AccessOverride> findByUserIdAndSupersededAtIsNull(UUID userId);

    /** Idem pour une page de comptes, en une requête. */
    List<AccessOverride> findByUserIdInAndSupersededAtIsNull(Collection<UUID> userIds);

    /** Comptes ayant un GRANT courant qui couvre {@code now} : sur-ensemble des « accès ouvert ». */
    @Query("""
            SELECT DISTINCT o.userId FROM AccessOverride o
             WHERE o.supersededAt IS NULL AND o.type = :type
               AND o.startsAt <= :now AND o.endsAt > :now
            """)
    List<UUID> findUserIdsWithCurrentOverrideCovering(@Param("type") AccessOverrideType type,
                                                      @Param("now") Instant now);

    /**
     * <b>Sérialise les écritures d'accès admin d'UN compte</b> — verrou consultatif
     * Postgres, libéré à la fin de la transaction (patron
     * {@code JourneyRepository.verrouillerLaCreation}). Deux admins qui agissent
     * sur le même compte passent l'un après l'autre ; le second relit l'état et
     * reçoit un 409 si celui-ci a changé (G-11).
     */
    @Query(value = "SELECT 1 FROM (SELECT pg_advisory_xact_lock(hashtextextended(:cle, 0))) verrou",
            nativeQuery = true)
    Integer verrouiller(@Param("cle") String cle);

    /**
     * Débit atomique d'UNE session EO temps réel sur un GRANT INTEGRAL COURANT,
     * conditionné au solde &gt; 0 (patron {@code UserSubscriptionRepository
     * .decrementRealtimeSessions}). 1 = débitée, 0 = ligne remplacée ou solde nul.
     */
    @Modifying(flushAutomatically = true)
    @Query("""
            UPDATE AccessOverride o
               SET o.realtimeEoSessionsRemaining = o.realtimeEoSessionsRemaining - 1
             WHERE o.id = :id AND o.supersededAt IS NULL AND o.realtimeEoSessionsRemaining > 0
            """)
    int decrementRealtimeSessions(@Param("id") UUID id);

    @Modifying
    @Query("DELETE FROM AccessOverride o WHERE o.userId = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
