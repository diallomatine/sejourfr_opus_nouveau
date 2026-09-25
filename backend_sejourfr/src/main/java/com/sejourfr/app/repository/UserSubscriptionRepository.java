package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
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

    /** Les acces d'une page de candidats, plan charge : une requete pour toute la page. */
    @EntityGraph(attributePaths = {"plan"})
    List<UserSubscription> findByUserIdIn(java.util.Collection<UUID> userIds);

    /**
     * Liste admin paginée : user et plan chargés dans la même requête que la
     * page (le mapper admin lit les deux). Sans ce graphe, une page de 100
     * lignes coûtait jusqu'à 201 requêtes. Deux {@code @ManyToOne} seulement,
     * donc aucune pagination en mémoire ; la requête de comptage n'en hérite pas.
     */
    @Override
    @EntityGraph(attributePaths = {"user", "plan"})
    Page<UserSubscription> findAll(Specification<UserSubscription> spec, Pageable pageable);

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
     * Débit atomique d'UNE session EO temps réel sur le pass, conditionné au
     * solde > 0 (évite tout passage sous zéro sur des connexions concurrentes).
     * Renvoie le nombre de lignes affectées (1 = débitée, 0 = solde déjà nul).
     */
    @Modifying(flushAutomatically = true)
    @Query("""
            UPDATE UserSubscription s
            SET s.realtimeEoSessionsRemaining = s.realtimeEoSessionsRemaining - 1
            WHERE s.id = :id AND s.realtimeEoSessionsRemaining > 0
            """)
    int decrementRealtimeSessions(@Param("id") UUID id);
}
