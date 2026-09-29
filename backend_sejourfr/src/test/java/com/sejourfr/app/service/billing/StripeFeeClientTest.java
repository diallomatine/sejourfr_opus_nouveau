package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.StripeProperties;
import com.stripe.exception.StripeException;
import com.stripe.model.BalanceTransaction;
import com.stripe.model.Charge;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentRetrieveParams;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/** Le frais réel Stripe, sans réseau : l'appel statique du SDK est mocké. */
class StripeFeeClientTest {

    private StripeFeeClient client(boolean configure) {
        StripeProperties props = mock(StripeProperties.class);
        when(props.isConfigured()).thenReturn(configure);
        return new StripeFeeClient(props);
    }

    private static PaymentIntent intentAvecFrais(Long fee, String devise) {
        BalanceTransaction bt = mock(BalanceTransaction.class);
        when(bt.getFee()).thenReturn(fee);
        when(bt.getCurrency()).thenReturn(devise);
        Charge charge = mock(Charge.class);
        when(charge.getBalanceTransactionObject()).thenReturn(bt);
        PaymentIntent intent = mock(PaymentIntent.class);
        when(intent.getLatestChargeObject()).thenReturn(charge);
        return intent;
    }

    @Test
    void stripeNonConfigure_aucunAppel_vide() {
        try (MockedStatic<PaymentIntent> sdk = mockStatic(PaymentIntent.class)) {
            assertThat(client(false).fraisReelEurCents("pi_1")).isEmpty();
            sdk.verifyNoInteractions();
        }
    }

    @Test
    void fraisEnEuros_lu() {
        PaymentIntent intent = intentAvecFrais(39L, "eur");
        try (MockedStatic<PaymentIntent> sdk = mockStatic(PaymentIntent.class)) {
            sdk.when(() -> PaymentIntent.retrieve(eq("pi_1"), any(PaymentIntentRetrieveParams.class), isNull()))
                    .thenReturn(intent);
            assertThat(client(true).fraisReelEurCents("pi_1")).contains(39);
        }
    }

    @Test
    void fraisDansUneAutreDevise_vide() {
        PaymentIntent intent = intentAvecFrais(39L, "usd");
        try (MockedStatic<PaymentIntent> sdk = mockStatic(PaymentIntent.class)) {
            sdk.when(() -> PaymentIntent.retrieve(eq("pi_1"), any(PaymentIntentRetrieveParams.class), isNull()))
                    .thenReturn(intent);
            assertThat(client(true).fraisReelEurCents("pi_1")).isEmpty();
        }
    }

    @Test
    void erreurStripe_vide_jamaisBloquant() {
        try (MockedStatic<PaymentIntent> sdk = mockStatic(PaymentIntent.class)) {
            sdk.when(() -> PaymentIntent.retrieve(eq("pi_1"), any(PaymentIntentRetrieveParams.class), isNull()))
                    .thenThrow(mock(StripeException.class));
            assertThat(client(true).fraisReelEurCents("pi_1")).isEmpty();
        }
    }
}
