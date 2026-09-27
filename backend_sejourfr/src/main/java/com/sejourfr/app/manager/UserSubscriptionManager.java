package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link UserSubscription}.
 */
@Component
@RequiredArgsConstructor
public class UserSubscriptionManager {

    private final UserSubscriptionRepository repository;
    private final EntityManager entityManager;

    public List<UserSubscription> findByUserId(UUID userId) {
        return repository.findByUserId(userId);
    }

    public List<UserSubscription> findByUserIds(java.util.Collection<UUID> userIds) {
        return userIds.isEmpty() ? List.of() : repository.findByUserIdIn(userIds);
    }

    public Optional<UserSubscription> findById(UUID id) {
        return repository.findById(id);
    }

    public Optional<UserSubscription> findByStripeSubscriptionId(String stripeSubscriptionId) {
        return repository.findByStripeSubscriptionId(stripeSubscriptionId);
    }

    /**
     * Retrouve une souscription par sa clé canonique de réconciliation. À
     * utiliser dans les handlers webhook avant de décider create vs update.
     */
    public Optional<UserSubscription> findBySourceAndOriginalTransactionId(
            SubscriptionSource source, String originalTransactionId) {
        return repository.findBySourceAndOriginalTransactionId(source, originalTransactionId);
    }

    /**
     * Verrou de ligne ({@code SELECT … FOR UPDATE}) sur l'achat, pris AVANT de
     * lire ce qui est deja rembourse et de poser un nouvel etat (controle A).
     * Deux webhooks concurrents sur le meme achat s'executent alors l'un apres
     * l'autre : le second relit l'etat et le cumul commites par le premier.
     *
     * <p>L'entite est RECHARGEE depuis la base sous verrou : un etat lu avant
     * le verrou pourrait etre perime, et le sauvegarder ecraserait ce que la
     * transaction concurrente vient d'ecrire. A appeler dans une transaction,
     * avant toute modification de l'entite (un rechargement les effacerait).
     */
    public void verrouiller(UserSubscription subscription) {
        if (subscription == null || subscription.getId() == null) return;
        if (entityManager.contains(subscription)) {
            entityManager.refresh(subscription, LockModeType.PESSIMISTIC_WRITE);
        } else {
            entityManager.find(UserSubscription.class, subscription.getId(), LockModeType.PESSIMISTIC_WRITE);
        }
    }

    public UserSubscription save(UserSubscription subscription) {
        return repository.save(subscription);
    }

    /**
     * Débit atomique d'une session EO temps réel (conditionné au solde &gt; 0).
     * Renvoie {@code true} si une session a bien été débitée.
     */
    public boolean decrementRealtimeSessions(UUID subscriptionId) {
        return repository.decrementRealtimeSessions(subscriptionId) > 0;
    }

    /**
     * Pose le solde EO temps réel sans faire avancer {@code updated_at} (cf.
     * repository). Renvoie {@code false} si la souscription n'existe pas.
     */
    public boolean setRealtimeSessions(UUID subscriptionId, int remaining) {
        return repository.setRealtimeSessions(subscriptionId, remaining) > 0;
    }

    /**
     * Recherche paginée par {@link Specification} — utilisée par l'admin pour
     * combiner filtres source/status/module/search.
     */
    public Page<UserSubscription> findAll(Specification<UserSubscription> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }
}
