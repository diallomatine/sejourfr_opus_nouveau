package com.sejourfr.app.dto;

import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Vue admin d'un Plan : expose tous les champs éditables (prix, store IDs,
 * activation). Différent de {@link PlanPublicResponse} qui masque l'id
 * interne et les SKU stores.
 */
public record AdminPlanDto(
        UUID id,
        String code,
        String name,
        BillingCycle billingCycle,
        BigDecimal price,
        BigDecimal originalPrice,
        ModuleAccess moduleAccess,
        int durationDays,
        boolean active,
        String stripePriceId,
        String appleProductId,
        String googleProductId
) {
}
