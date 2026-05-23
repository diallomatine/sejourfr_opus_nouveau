package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.repository.UserSubscriptionRepository;
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

    public List<UserSubscription> findByUserId(UUID userId) {
        return repository.findByUserId(userId);
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

    public UserSubscription save(UserSubscription subscription) {
        return repository.save(subscription);
    }

    /**
     * Recherche paginée par {@link Specification} — utilisée par l'admin pour
     * combiner filtres source/status/module/search.
     */
    public Page<UserSubscription> findAll(Specification<UserSubscription> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }
}
