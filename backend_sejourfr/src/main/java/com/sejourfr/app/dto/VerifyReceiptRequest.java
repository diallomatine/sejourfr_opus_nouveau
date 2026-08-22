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
 *   <li>{@code rawPrice} + {@code currencyCode} : le prix RÉELLEMENT affiché à
 *       cet utilisateur, tel que le store le rend
 *       ({@code ProductDetails.rawPrice} / {@code currencyCode} côté
 *       {@code in_app_purchase}). <b>Les deux sont FACULTATIFS</b> : une version
 *       antérieure de l'application ne les envoie pas, et elle ne doit surtout
 *       pas cesser de fonctionner pour autant — on retombe alors sur le prix
 *       affiché du plan.</li>
 * </ul>
 *
 * <p><b>Pourquoi accepter un montant venu du client.</b> Ni
 * {@code purchases.products.get} (Google) ni le JWS de transaction (Apple, dont
 * le champ {@code price} est en milliunités et dépend de la version d'API) ne
 * nous donnent un prix exploitable de façon sûre. Or le store vend en monnaie
 * locale, à un prix qui n'est pas {@code plans.price}. Le seul risque est qu'un
 * utilisateur fausse <i>son propre</i> montant : le reçu, lui, reste vérifié
 * auprès du store et c'est lui qui ouvre l'accès. Le bénéfice — connaître le
 * chiffre d'affaires réel — est sans commune mesure.
 */
public record VerifyReceiptRequest(
        @NotNull SubscriptionSource source,
        @NotBlank String receipt,
        @NotBlank String productId,
        Double rawPrice,
        String currencyCode
) {}
