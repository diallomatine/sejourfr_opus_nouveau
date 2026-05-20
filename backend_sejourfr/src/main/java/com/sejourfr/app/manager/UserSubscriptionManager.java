package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import lombok.RequiredArgsConstructor;
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

    public UserSubscription save(UserSubscription subscription) {
        return repository.save(subscription);
    }
}
