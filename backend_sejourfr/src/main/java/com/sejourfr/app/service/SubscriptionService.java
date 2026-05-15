package com.sejourfr.app.service;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.UserSubscriptionRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Service
public class SubscriptionService {

    // Code en base du plan gratuit (cf. V2__seed_reference.sql). Toute
    // souscription rattachée à ce plan est ignorée pour le calcul Premium,
    // même si son statut est ACTIVE.
    private static final String FREE_PLAN_CODE = "FREE";

    private final UserSubscriptionRepository userSubscriptionRepository;

    public SubscriptionService(UserSubscriptionRepository userSubscriptionRepository) {
        this.userSubscriptionRepository = userSubscriptionRepository;
    }

    /**
     * Renvoie true si l'utilisateur a au moins un abonnement payant ACTIVE
     * ou TRIAL non expiré. Les souscriptions au plan FREE, ou les statuts
     * CANCELED / EXPIRED, ne donnent pas accès aux contenus Premium.
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
        Plan plan = s.getPlan();
        if (plan == null || FREE_PLAN_CODE.equalsIgnoreCase(plan.getCode())) {
            return false;
        }
        return s.getEndsAt() == null || s.getEndsAt().isAfter(now);
    }
}
