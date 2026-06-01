package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserSubscriptionRepository
        extends JpaRepository<UserSubscription, UUID>,
                JpaSpecificationExecutor<UserSubscription> {

    List<UserSubscription> findByUserId(UUID userId);

    /**
     * Lookup historique des souscriptions Stripe par session/subscription id.
     * Conservé pour le code Stripe existant — sera retiré au lot 4 (refonte
     * abonnements récurrents) au profit de {@link #findBySourceAndOriginalTransactionId}.
     */
    Optional<UserSubscription> findByStripeSubscriptionId(String stripeSubscriptionId);

    /**
     * Clé canonique de réconciliation des renouvellements. À utiliser dans
     * les handlers webhook : le store nous dit "événement sur originalTxId X",
     * on retrouve la ligne existante et on met à jour status / endsAt /
     * externalTxId au lieu d'en créer une nouvelle. Garanti unique par
     * l'index {@code ux_user_subscriptions_source_original} (V103).
     */
    Optional<UserSubscription> findBySourceAndOriginalTransactionId(
            SubscriptionSource source, String originalTransactionId);

    /**
     * Passes one-time ACTIVE dont l'accès expire dans la fenêtre [{@code now},
     * {@code threshold}] et qui n'ont pas encore reçu le rappel d'expiration.
     * Utilisé par le job de relance (lot 5). On cible bien les passes via
     * {@code plan.purchaseType = ONE_TIME}.
     */
    @Query("""
            SELECT s FROM UserSubscription s
            WHERE s.status = com.sejourfr.app.enums.SubscriptionStatus.ACTIVE
              AND s.plan.purchaseType = com.sejourfr.app.enums.PlanPurchaseType.ONE_TIME
              AND s.expiryRemindedAt IS NULL
              AND s.endsAt IS NOT NULL
              AND s.endsAt > :now
              AND s.endsAt <= :threshold
            """)
    List<UserSubscription> findOneTimeExpiringSoon(
            @Param("now") Instant now, @Param("threshold") Instant threshold);
}
