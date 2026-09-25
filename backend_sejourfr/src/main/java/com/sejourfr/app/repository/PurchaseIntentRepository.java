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

    /**
     * La run FONDATRICE d'un parcours, lue uniquement par les cles etrangeres :
     * la premiere evaluation de diagnostic journalisee sur ce parcours
     * ({@code journey_assessment_event}), et la run rattachee a la session de ce
     * diagnostic et au meme compte. Aucune heuristique (pas de « run la plus
     * recente », pas d'{@code anonymous_id}).
     *
     * <p>Origine de {@code source_assessment_id} selon la nature (cf.
     * {@code JourneyObservationSources.origineAttendue}) : diagnostic rapide =
     * {@code diagnostic_sessions.id}, civique = {@code civic_diagnostic_sessions.id},
     * complet = {@code attempts.id} d'une section (d'ou le passage par
     * {@code attempts.tcf_diagnostic_id}).
     */
    @Query(value = """
            SELECT r.id
              FROM journey_assessment_event e
              JOIN journey j ON j.id = e.journey_id
              LEFT JOIN attempts a
                     ON e.assessment_kind = 'FULL_DIAGNOSTIC' AND a.id = e.source_assessment_id
              JOIN diagnostic_run r
                ON r.user_id = j.user_id
               AND (   (e.assessment_kind = 'QUICK_DIAGNOSTIC'
                        AND r.diagnostic_session_id = e.source_assessment_id)
                    OR (e.assessment_kind = 'CIVIC_DIAGNOSTIC'
                        AND r.civic_diagnostic_session_id = e.source_assessment_id)
                    OR (e.assessment_kind = 'FULL_DIAGNOSTIC'
                        AND r.tcf_diagnostic_session_id = a.tcf_diagnostic_id))
             WHERE e.journey_id = :journeyId
               AND e.assessment_kind IN ('QUICK_DIAGNOSTIC', 'CIVIC_DIAGNOSTIC', 'FULL_DIAGNOSTIC')
             ORDER BY e.completed_at ASC, e.processed_at ASC, e.id ASC
             LIMIT 1
            """, nativeQuery = true)
    List<UUID> foundingRunOf(@Param("journeyId") UUID journeyId);
}
