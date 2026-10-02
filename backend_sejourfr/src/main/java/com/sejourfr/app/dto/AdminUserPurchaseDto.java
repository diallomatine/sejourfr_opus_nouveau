package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Un achat réel (spec §5.3), lecture seule. {@code externalReference} est
 * TRONQUÉE : un identifiant de paiement complet (purchaseToken Google, id de
 * session Stripe) ne sort jamais vers l'admin. {@code recurring} : abonnement
 * auto-renouvelable, en lecture seule pour toute opération commerciale (G-12).
 */
public record AdminUserPurchaseDto(
        UUID id,
        ModuleAccess product,
        String productLabel,
        String planCode,
        String planName,
        SubscriptionSource source,
        String sourceLabel,
        SubscriptionStatus status,
        String statusLabel,
        PaymentStatus paymentStatus,
        String paymentStatusLabel,
        Integer amountCents,
        String currency,
        Instant purchasedAt,
        Instant startsAt,
        Instant endsAt,
        String endLabel,
        boolean recurring,
        String externalReference
) {}
