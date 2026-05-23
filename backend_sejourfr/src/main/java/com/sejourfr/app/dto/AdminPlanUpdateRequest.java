package com.sejourfr.app.dto;

import jakarta.validation.constraints.DecimalMin;

import java.math.BigDecimal;

/**
 * Patch admin sur un Plan. Tous les champs sont optionnels (PATCH partiel) ;
 * seuls ceux non-null sont appliqués. Permet de modifier prix, prix d'origine,
 * activation, et les SKUs Stripe/Apple/Google sans toucher au code, name,
 * billingCycle ni moduleAccess (qui sont structurels et passent par
 * migration).
 *
 * <p>Pour effacer un champ optionnel (ex: retirer un Apple product ID), passer
 * une chaîne vide — le service la convertit en null. Pour
 * {@code originalPrice} 0 = pas de prix barré.
 */
public record AdminPlanUpdateRequest(
        @DecimalMin(value = "0.0", inclusive = true)
        BigDecimal price,

        @DecimalMin(value = "0.0", inclusive = true)
        BigDecimal originalPrice,

        Boolean active,

        String stripePriceId,
        String appleProductId,
        String googleProductId
) {
}
