package com.sejourfr.app.repository;

import com.sejourfr.app.entity.PurchaseIntent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface PurchaseIntentRepository extends JpaRepository<PurchaseIntent, UUID> {

    /**
     * Consomme l'intention en une seule instruction : elle n'est marquee que si
     * elle appartient a ce compte, vise ce produit, n'est pas expiree a
     * {@code at} et n'a jamais servi. Deux achats concurrents ne peuvent donc
     * pas la consommer tous les deux (usage unique, Q12).
     *
     * @return 1 si l'intention est desormais consommee par l'appelant, 0 sinon
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE purchase_intent
               SET consumed_at = :now
             WHERE id = :id
               AND user_id = :userId
               AND product_id = :productId
               AND consumed_at IS NULL
               AND expires_at > :at
            """, nativeQuery = true)
    int consume(@Param("id") UUID id, @Param("userId") UUID userId,
                @Param("productId") String productId, @Param("at") Instant at,
                @Param("now") Instant now);

    /** Le parcours, s'il existe ET appartient a ce compte. */
    @Query(value = "SELECT j.id FROM journey j WHERE j.id = :journeyId AND j.user_id = :userId",
            nativeQuery = true)
    List<UUID> ownedJourney(@Param("journeyId") UUID journeyId, @Param("userId") UUID userId);
}
