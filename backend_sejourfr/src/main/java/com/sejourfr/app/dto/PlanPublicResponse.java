package com.sejourfr.app.dto;

import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;

import java.math.BigDecimal;

/**
 * Vue publique d'un plan d'abonnement pour la landing : prix actuel, prix
 * original barré (offre de lancement), durée en jours, modules débloqués.
 *
 * Pas d'identifiant interne ni de timestamp — c'est consommé par la section
 * Tarifs sans authentification.
 */
public record PlanPublicResponse(
        String code,
        String name,
        BillingCycle billingCycle,
        BigDecimal price,
        BigDecimal originalPrice,
        ModuleAccess moduleAccess,
        int durationDays
) {
}
