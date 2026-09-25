package com.sejourfr.app.service.billing;

import com.sejourfr.app.enums.FeeSource;
import com.sejourfr.app.enums.SubscriptionSource;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Scenario 12 du brief (montants au centime, invariant) et scenario 13
 * (remboursements), sur les regles livrees (v1) et sur des variantes ecrites
 * ici pour les cas que la v1 ne porte pas (store a 30 %, vendeur assujetti).
 */
class RevenueCalculatorTest {

    private final RevenueCalculator v1 = new RevenueCalculator(RevenueRulesLoader.load(1));

    private static RevenueCalculator avec(String vatRegime, String appleRate) throws Exception {
        String json = """
                {"revenueRulesVersion":1,"currency":"EUR","rounding":"HALF_UP",
                 "seller":{"vatRegime":"%s","vatRateIfLiable":0.20},
                 "stripe":{"percentFee":0.015,"fixedFeeCents":25,"preferActualFee":true},
                 "stores":{"vatRate":0.20,"commissionMode":"MULTIPLY",
                           "commissionRates":{"APPLE":%s,"GOOGLE":0.15}}}
                """.formatted(vatRegime, appleRate);
        return new RevenueCalculator(RevenueRulesLoader.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)), 1, "test.json"));
    }

    @Test
    @DisplayName("Q1 — Stripe 9,99 sous franchise : TVA 0, frais 0,40, net 9,59")
    void stripeFranchise() {
        RevenueBreakdown r = v1.decomposer(SubscriptionSource.STRIPE, 999, null);

        assertThat(r.vatCents()).isZero();
        assertThat(r.providerFeeCents()).isEqualTo(40);
        assertThat(r.netAfterFeeCents()).isEqualTo(959);
        assertThat(r.netExVatCents()).isEqualTo(959);
        assertThat(r.feeSource()).isEqualTo(FeeSource.ESTIMATED);
        assertThat(r.revenueRulesVersion()).isEqualTo(1);
    }

    @Test
    @DisplayName("Stripe : le frais réel de la balance_transaction prime sur la formule")
    void stripeFraisReel() {
        RevenueBreakdown r = v1.decomposer(SubscriptionSource.STRIPE, 999, 39);

        assertThat(r.providerFeeCents()).isEqualTo(39);
        assertThat(r.netExVatCents()).isEqualTo(960);
        assertThat(r.feeSource()).isEqualTo(FeeSource.ACTUAL);
    }

    @Test
    @DisplayName("Stripe : un frais réel incohérent (négatif, > brut) retombe sur la formule")
    void stripeFraisReelIncoherent() {
        assertThat(v1.stripe(999, -1).feeSource()).isEqualTo(FeeSource.ESTIMATED);
        assertThat(v1.stripe(999, 1000).feeSource()).isEqualTo(FeeSource.ESTIMATED);
        assertThat(v1.stripe(999, 1000).providerFeeCents()).isEqualTo(40);
    }

    @Test
    @DisplayName("Brief §6.3 — Stripe d'un vendeur assujetti : HT 8,33, TVA 1,66, net 7,93")
    void stripeAssujetti() throws Exception {
        RevenueBreakdown r = avec("ASSUJETTI", "0.15").stripe(999, null);

        assertThat(r.vatCents()).isEqualTo(166);
        assertThat(r.providerFeeCents()).isEqualTo(40);
        assertThat(r.netAfterFeeCents()).isEqualTo(959);
        assertThat(r.netExVatCents()).isEqualTo(793);
    }

    @Test
    @DisplayName("Q1 — Store à 15 % : HT 8,33, TVA 1,66, commission 1,25, net 7,08")
    void store15() {
        RevenueBreakdown r = v1.decomposer(SubscriptionSource.APPLE, 999, null);

        assertThat(r.vatCents()).isEqualTo(166);
        assertThat(r.providerFeeCents()).isEqualTo(125);
        assertThat(r.netAfterFeeCents()).isEqualTo(708);
        assertThat(r.netExVatCents()).isEqualTo(708);
        assertThat(r.feeSource()).isEqualTo(FeeSource.ESTIMATED);
        assertThat(v1.decomposer(SubscriptionSource.GOOGLE, 999, 1).netExVatCents()).isEqualTo(708);
    }

    @Test
    @DisplayName("Q1 — Store à 30 % : net 5,83")
    void store30() throws Exception {
        RevenueBreakdown r = avec("FRANCHISE_293B", "0.30").store(RevenueRules.Store.APPLE, 999);

        assertThat(r.providerFeeCents()).isEqualTo(250);
        assertThat(r.netExVatCents()).isEqualTo(583);
    }

    @Test
    @DisplayName("Invariant brut = TVA + frais + net HT, sur toute une plage de montants")
    void invariantSurUnePlage() {
        for (int gross = 50; gross <= 10_000; gross += 7) {
            for (SubscriptionSource s : SubscriptionSource.values()) {
                RevenueBreakdown r = v1.decomposer(s, gross, null);
                assertThat(r.vatCents() + r.providerFeeCents() + r.netExVatCents()).isEqualTo(gross);
            }
        }
    }

    @Test
    @DisplayName("Une décomposition qui viole l'invariant est refusée")
    void invariantAsserte() {
        assertThatThrownBy(() -> new RevenueBreakdown(999, 0, 40, 959, 958, FeeSource.ESTIMATED, 1))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("Scénario 13 — remboursement Stripe total : le net de l'achat finit à −0,40 €")
    void remboursementStripeTotal() {
        RevenueBreakdown achat = v1.stripe(999, null);
        int delta = v1.deltaRemboursementStripe(999);

        assertThat(delta).isEqualTo(-999);
        assertThat(achat.netExVatCents() + delta).isEqualTo(-40);
    }

    @Test
    @DisplayName("Scénario 13 — remboursement store total : le net de l'achat finit à 0")
    void remboursementStoreTotal() {
        RevenueBreakdown achat = v1.store(RevenueRules.Store.GOOGLE, 999);

        assertThat(achat.netExVatCents() + v1.deltaRemboursementStore(708, 999, 999)).isZero();
    }

    @Test
    @DisplayName("Remboursement store partiel : le net perd sa part au prorata")
    void remboursementStorePartiel() {
        // 708 × 500 / 999 = 354,35… → 354
        assertThat(v1.deltaRemboursementStore(708, 999, 500)).isEqualTo(-354);
    }
}
