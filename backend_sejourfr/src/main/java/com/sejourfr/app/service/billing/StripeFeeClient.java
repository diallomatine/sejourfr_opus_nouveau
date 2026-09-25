package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.StripeProperties;
import com.stripe.model.BalanceTransaction;
import com.stripe.model.Charge;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentRetrieveParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * Lit le frais REEL d'un paiement Stripe : {@code payment_intent →
 * latest_charge → balance_transaction.fee}. Seul point du code qui fait cet
 * appel (mocke en test ; aucun test n'appelle Stripe).
 *
 * <p><b>Best-effort</b> : Stripe non configure, erreur reseau, balance
 * transaction pas encore disponible ou tenue dans une autre devise que l'euro
 * ⇒ vide, et {@link RevenueCalculator} retombe sur la formule
 * ({@code fee_source = ESTIMATED}). Un frais inconnu ne bloque jamais un octroi.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class StripeFeeClient {

    private final StripeProperties stripeProperties;

    public Optional<Integer> fraisReelEurCents(String paymentIntentId) {
        if (paymentIntentId == null || paymentIntentId.isBlank() || !stripeProperties.isConfigured()) {
            return Optional.empty();
        }
        try {
            PaymentIntent intent = PaymentIntent.retrieve(paymentIntentId,
                    PaymentIntentRetrieveParams.builder()
                            .addExpand("latest_charge.balance_transaction")
                            .build(),
                    null);
            Charge charge = intent.getLatestChargeObject();
            BalanceTransaction bt = charge != null ? charge.getBalanceTransactionObject() : null;
            if (bt == null || bt.getFee() == null || !"eur".equalsIgnoreCase(bt.getCurrency())
                    || bt.getFee() < 0 || bt.getFee() > Integer.MAX_VALUE) {
                return Optional.empty();
            }
            return Optional.of(bt.getFee().intValue());
        } catch (Exception e) {
            log.info("Frais reel Stripe indisponible (pi={}) : formule de repli. {}",
                    paymentIntentId, e.getMessage());
            return Optional.empty();
        }
    }
}
