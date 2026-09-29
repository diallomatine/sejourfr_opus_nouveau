package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.FeeSource;

/**
 * Decomposition d'un achat en centimes d'euro (brief §6.1), produite par
 * {@link RevenueCalculator} et figee sur la ligne a l'ecriture.
 *
 * <p>🛑 Invariant {@code gross = vat + fee + netExVat}, verifie ici (le
 * constructeur refuse une decomposition fausse) ET par la base
 * ({@code chk_user_subscriptions_revenue_invariant}, V074).
 *
 * @param grossCents       brut paye (= {@code amount_eur_cents})
 * @param vatCents         TVA incluse ({@code gross − HT})
 * @param providerFeeCents frais Stripe ou commission store
 * @param netAfterFeeCents ce qui arrive sur le compte bancaire
 * @param netExVatCents    revenu HT apres frais — KPI principal
 */
public record RevenueBreakdown(int grossCents, int vatCents, int providerFeeCents,
                               int netAfterFeeCents, int netExVatCents,
                               FeeSource feeSource, int revenueRulesVersion) {

    public RevenueBreakdown {
        if (grossCents != vatCents + providerFeeCents + netExVatCents) {
            throw new IllegalStateException("Invariant de revenu viole : " + grossCents + " != "
                    + vatCents + " + " + providerFeeCents + " + " + netExVatCents);
        }
        if (feeSource == null) {
            throw new IllegalStateException("fee_source obligatoire");
        }
    }

    /** Ecrit les six colonnes de revenu, ensemble (CHECK tout-ou-rien de V074). */
    public void appliquerA(UserSubscription sub) {
        sub.setVatCents(vatCents);
        sub.setProviderFeeCents(providerFeeCents);
        sub.setNetAfterFeeCents(netAfterFeeCents);
        sub.setNetExVatCents(netExVatCents);
        sub.setFeeSource(feeSource);
        sub.setRevenueRulesVersion(revenueRulesVersion);
    }
}
