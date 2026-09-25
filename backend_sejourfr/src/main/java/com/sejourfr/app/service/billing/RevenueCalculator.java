package com.sejourfr.app.service.billing;

import com.sejourfr.app.enums.FeeSource;
import com.sejourfr.app.enums.SubscriptionSource;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * <b>Autorite unique</b> du calcul de revenu (brief §6, arbitrage Q1). Pure :
 * aucune lecture, aucune ecriture, aucun horloge — seulement les regles
 * versionnees ({@link RevenueRules}) et des centimes d'euro. Arrondi HALF_UP.
 *
 * <h4>Stripe (vente directe)</h4>
 * {@code HT = round(gross / (1 + taux))} avec le taux du vendeur : 0 sous
 * {@code FRANCHISE_293B}, donc {@code vat = 0} et {@code HT = gross}. Frais =
 * le frais REEL de la {@code balance_transaction} quand il est connu
 * ({@code ACTUAL}), la formule {@code gross × % + fixe} sinon ({@code ESTIMATED}).
 * {@code net_after_fee = gross − fee}, {@code net_ex_vat = HT − fee}.
 *
 * <h4>Apple / Google</h4>
 * Le store retient et reverse la TVA (20 % FR), quel que soit le regime du
 * vendeur. {@code HT = round(gross / 1,2)}, commission {@code MULTIPLY} au taux
 * du store sur le HT, {@code net_after_fee = net_ex_vat = HT − fee},
 * toujours {@code ESTIMATED}.
 *
 * <h4>Remboursements (§6.4)</h4>
 * Stripe garde ses frais : le net perd le HT rembourse. Un store rend sa
 * commission : le net perd sa part au prorata.
 */
@Component
@RequiredArgsConstructor
public class RevenueCalculator {

    private final RevenueRules rules;

    public int rulesVersion() {
        return rules.revenueRulesVersion();
    }

    /**
     * Decomposition d'un achat selon son canal.
     *
     * @param actualFeeEurCents frais reel Stripe en centimes d'euro, ou
     *                          {@code null} (inconnu, ou canal store)
     */
    public RevenueBreakdown decomposer(SubscriptionSource source, int grossEurCents,
                                       Integer actualFeeEurCents) {
        return switch (source) {
            case STRIPE -> stripe(grossEurCents, actualFeeEurCents);
            case APPLE -> store(RevenueRules.Store.APPLE, grossEurCents);
            case GOOGLE -> store(RevenueRules.Store.GOOGLE, grossEurCents);
        };
    }

    public RevenueBreakdown stripe(int grossEurCents, Integer actualFeeEurCents) {
        int ht = horsTaxe(grossEurCents, rules.directSaleVatRate());
        int vat = grossEurCents - ht;
        boolean reel = rules.stripe().preferActualFee()
                && actualFeeEurCents != null
                && actualFeeEurCents >= 0
                && actualFeeEurCents <= grossEurCents;
        int fee = reel ? actualFeeEurCents : fraisStripeEstimes(grossEurCents);
        return new RevenueBreakdown(grossEurCents, vat, fee, grossEurCents - fee, ht - fee,
                reel ? FeeSource.ACTUAL : FeeSource.ESTIMATED, rules.revenueRulesVersion());
    }

    public RevenueBreakdown store(RevenueRules.Store store, int grossEurCents) {
        int ht = horsTaxe(grossEurCents, rules.stores().vatRate());
        int vat = grossEurCents - ht;
        int fee = arrondi(BigDecimal.valueOf(ht).multiply(rules.commissionRate(store)));
        int net = ht - fee;
        return new RevenueBreakdown(grossEurCents, vat, fee, net, net,
                FeeSource.ESTIMATED, rules.revenueRulesVersion());
    }

    /**
     * Ce qu'un remboursement Stripe retire au net HT : le HT du montant rendu,
     * frais NON rendus. Un remboursement total laisse donc l'achat a
     * {@code −fee}.
     */
    public int deltaRemboursementStripe(int refundedEurCents) {
        return -horsTaxe(refundedEurCents, rules.directSaleVatRate());
    }

    /**
     * Ce qu'un remboursement store retire au net HT : la part du net
     * correspondant au montant rendu. Total ⇒ exactement {@code −netExVat}.
     */
    public int deltaRemboursementStore(int netExVatCents, int grossEurCents, int refundedEurCents) {
        if (grossEurCents <= 0) return 0;
        int part = refundedEurCents >= grossEurCents
                ? netExVatCents
                : arrondi(BigDecimal.valueOf(netExVatCents)
                .multiply(BigDecimal.valueOf(refundedEurCents))
                .divide(BigDecimal.valueOf(grossEurCents), 6, RoundingMode.HALF_UP));
        return Math.min(0, -part);
    }

    private int fraisStripeEstimes(int grossEurCents) {
        return arrondi(BigDecimal.valueOf(grossEurCents)
                .multiply(rules.stripe().percentFee())
                .add(BigDecimal.valueOf(rules.stripe().fixedFeeCents())));
    }

    /** {@code round(gross / (1 + taux))}, HALF_UP ; taux nul ⇒ {@code gross}. */
    static int horsTaxe(int grossCents, BigDecimal taux) {
        if (taux == null || taux.signum() == 0) return grossCents;
        return BigDecimal.valueOf(grossCents)
                .divide(BigDecimal.ONE.add(taux), 0, RoundingMode.HALF_UP)
                .intValueExact();
    }

    private static int arrondi(BigDecimal valeur) {
        return valeur.setScale(0, RoundingMode.HALF_UP).intValueExact();
    }
}
