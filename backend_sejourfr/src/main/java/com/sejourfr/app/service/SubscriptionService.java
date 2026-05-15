package com.sejourfr.app.service;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Service
public class SubscriptionService {

    private final UserSubscriptionRepository userSubscriptionRepository;

    public SubscriptionService(UserSubscriptionRepository userSubscriptionRepository) {
        this.userSubscriptionRepository = userSubscriptionRepository;
    }

    /**
     * Renvoie true si l'utilisateur a au moins un abonnement ACTIVE ou TRIAL
     * non expiré. Les statuts CANCELED ou EXPIRED ne donnent pas accès.
     */
    public boolean isPremium(UUID userId) {
        Instant now = Instant.now();
        return userSubscriptionRepository.findByUserId(userId).stream()
                .anyMatch(s -> isCovering(s, now));
    }

    private boolean isCovering(UserSubscription s, Instant now) {
        if (s.getStatus() != SubscriptionStatus.ACTIVE && s.getStatus() != SubscriptionStatus.TRIAL) {
            return false;
        }
        return s.getEndsAt() == null || s.getEndsAt().isAfter(now);
    }
}
