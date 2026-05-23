package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

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
}
