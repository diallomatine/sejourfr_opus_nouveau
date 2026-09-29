package com.sejourfr.app.service.email.event;

import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/** Mode abonnement recurrent DORMANT : resiliation enregistree (conserve pour la reversibilite). */
public record PremiumSubscriptionCanceledEvent(UUID userId, String email, UUID accessId) {

    @Override
    public String toString() {
        return "PremiumSubscriptionCanceledEvent[user=" + userId + ", email=" + LogMask.email(email)
                + ", access=" + accessId + "]";
    }
}
