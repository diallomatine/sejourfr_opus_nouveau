package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

import java.util.Optional;

@Repository
public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, UUID> {
    List<UserSubscription> findByUserId(UUID userId);

    Optional<UserSubscription> findByStripeSubscriptionId(String stripeSubscriptionId);
}
