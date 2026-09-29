package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SubscriptionSource;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Reçu remonté par l'app mobile après un achat StoreKit (Apple) ou Play
 * Billing (Google).
 *
 * <ul>
 *   <li>{@code source} : APPLE ou GOOGLE (jamais STRIPE — Stripe ne passe pas par cet endpoint).</li>
 *   <li>{@code receipt} : pour Apple, le {@code signedTransactionInfo} (JWS).
 *       Pour Google, le {@code purchaseToken}.</li>
 *   <li>{@code productId} : le SKU du store. Le backend re-vérifie côté store
 *       et ne fait pas confiance au client.</li>
 *   <li>{@code amountCents} + {@code currency} : le prix affiché, en unités
 *       mineures — <b>c'est ce que le mobile envoie réellement</b>
 *       ({@code billing_models.dart}).</li>
 *   <li>{@code rawPrice} + {@code currencyCode} : l'ancienne forme (décimal),
 *       toujours acceptée ; {@code amountCents} gagne si les deux sont là.
 *       Bug Q11 : le backend n'attendait que {@code rawPrice}, Jackson ignorait
 *       {@code amountCents} en silence, et tout achat store valait
 *       {@code plans.price}.</li>
 *   <li>{@code purchaseIntentId} : l'intention créée par
 *       {@code POST /api/billing/purchase-intents} avant la feuille d'achat
 *       (Q12). Facultatif : absent ou invalide ⇒ origine {@code UNKNOWN}.</li>
 * </ul>
 *
 * <p>Tous les champs de montant et d'intention sont <b>FACULTATIFS</b> : une
 * version antérieure de l'application ne les envoie pas et doit continuer de
 * fonctionner. 🛑 Apple : le montant déclaré n'est plus lu du tout, le prix
 * vient du JWS signé. Google : il est borné par le catalogue (aucune API Play
 * ne rend le prix d'un produit consommable).
 */
public record VerifyReceiptRequest(
        @NotNull SubscriptionSource source,
        @NotBlank String receipt,
        @NotBlank String productId,
        Double rawPrice,
        String currencyCode,
        Long amountCents,
        @Size(max = 8) String currency,
        @Size(max = 64) String purchaseIntentId
) {

    /** Forme historique (avant {@code amountCents} et l'intention d'achat). */
    public VerifyReceiptRequest(SubscriptionSource source, String receipt, String productId,
                                Double rawPrice, String currencyCode) {
        this(source, receipt, productId, rawPrice, currencyCode, null, null, null);
    }
}
