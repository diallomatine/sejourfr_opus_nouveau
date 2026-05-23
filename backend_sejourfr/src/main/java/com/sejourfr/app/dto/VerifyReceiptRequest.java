package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SubscriptionSource;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Reçu remonté par l'app mobile après un achat StoreKit (Apple) ou Play
 * Billing (Google). Validation effective auprès du store dans {@code lots 2/3}.
 *
 * <ul>
 *   <li>{@code source} : APPLE ou GOOGLE (jamais STRIPE — Stripe ne passe pas par cet endpoint).</li>
 *   <li>{@code receipt} : pour Apple, le {@code signedTransactionInfo} (JWS).
 *       Pour Google, le {@code purchaseToken}.</li>
 *   <li>{@code productId} : le SKU du store (ex: "integral_monthly").
 *       Sert au front à savoir quel plan a été acheté ; le backend re-vérifie
 *       côté store et ne fait pas confiance au client.</li>
 * </ul>
 */
public record VerifyReceiptRequest(
        @NotNull SubscriptionSource source,
        @NotBlank String receipt,
        @NotBlank String productId
) {}
