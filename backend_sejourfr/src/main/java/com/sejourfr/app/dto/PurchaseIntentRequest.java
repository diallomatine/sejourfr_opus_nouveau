package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Corps de {@code POST /api/billing/purchase-intents} : le mobile declare
 * l'intention AVANT d'ouvrir la feuille d'achat Apple / Google (Q12).
 *
 * @param productId   code du pass ({@code plans.code}) ou SKU du store
 *                    ({@code apple_product_id} / {@code google_product_id})
 * @param ctaLocation valeur de {@code AnalyticsCtaLocation} du bouton touche
 * @param journeyId   parcours affiche ({@code plan_id} = {@code journey.id}, Q8),
 *                    facultatif. Ignore s'il n'appartient pas au compte. La run
 *                    fondatrice est resolue serveur, jamais recue.
 */
public record PurchaseIntentRequest(
        @NotBlank @Size(max = 128) String productId,
        @NotBlank @Size(max = 32) String ctaLocation,
        @Size(max = 64) String journeyId
) {}
