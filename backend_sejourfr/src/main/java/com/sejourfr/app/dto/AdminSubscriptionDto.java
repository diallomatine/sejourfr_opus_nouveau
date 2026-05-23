package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Vue admin enrichie d'une UserSubscription : agrège user (email, nom), Plan
 * (code, name, moduleAccess, price) et les champs de la souscription
 * (status, dates, source, ids store). Sert au tableau admin et au modal de
 * détail.
 */
public record AdminSubscriptionDto(
        UUID id,
        UUID userId,
        String userEmail,
        String userFirstName,
        String userLastName,
        SubscriptionSource source,
        SubscriptionStatus status,
        String externalTransactionId,
        String originalTransactionId,
        String productId,
        boolean autoRenew,
        Instant startsAt,
        Instant endsAt,
        Instant updatedAt,
        UUID planId,
        String planCode,
        String planName,
        ModuleAccess moduleAccess,
        BigDecimal planPrice
) {
}
