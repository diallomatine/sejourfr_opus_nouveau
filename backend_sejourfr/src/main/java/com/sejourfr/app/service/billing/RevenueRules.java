package com.sejourfr.app.service.billing;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.util.Map;

/**
 * <b>Les regles de revenus versionnees</b> — image en memoire de
 * {@code billing/revenue-rules-vN.json} (chantier Suivi, brief §6 et §8,
 * arbitrage Q1).
 *
 * <p>Chaque achat fige le numero de version qui l'a decompose
 * ({@code user_subscriptions.revenue_rules_version}) : changer une regle n'a
 * aucun effet retroactif. Une version livree ne se reecrit pas ; on en ajoute
 * une.
 *
 * <p>🛑 Aucune valeur en Java, aucun defaut : une cle absente ou incoherente
 * est une erreur de demarrage ({@link RevenueRulesLoader}).
 *
 * @param currency devise de la decomposition : EUR seulement
 * @param rounding mode d'arrondi : HALF_UP seulement (brief §1.6)
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record RevenueRules(
        int revenueRulesVersion,
        String currency,
        String rounding,
        Seller seller,
        Stripe stripe,
        Stores stores
) {

    /** Regime de TVA du vendeur (SejourFR). */
    public enum VatRegime {
        /**
         * Franchise en base, art. 293 B du CGI : aucune TVA facturee sur les
         * ventes directes (Stripe). C'est la mention portee par la facture.
         */
        FRANCHISE_293B,
        /** Assujetti : la TVA s'applique aux ventes directes au taux {@code vatRateIfLiable}. */
        ASSUJETTI
    }

    /** Calcul de la commission store sur le HT (arbitrage : MULTIPLY). */
    public enum CommissionMode {
        /** {@code fee = round(HT × taux)}, le developpeur recoit {@code HT × (1 − taux)}. */
        MULTIPLY
    }

    /** Les stores dont la commission est configuree. */
    public enum Store { APPLE, GOOGLE }

    /**
     * @param vatRegime       regime du vendeur, qui decide de la TVA Stripe
     * @param vatRateIfLiable taux applique aux ventes directes si
     *                        {@link VatRegime#ASSUJETTI} ; sans effet sous franchise
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Seller(VatRegime vatRegime, BigDecimal vatRateIfLiable) {
    }

    /**
     * @param percentFee      part variable des frais Stripe (formule de repli)
     * @param fixedFeeCents   part fixe des frais Stripe, en centimes
     * @param preferActualFee frais reel de la {@code balance_transaction} en
     *                        priorite ({@code fee_source = ACTUAL}), la formule
     *                        n'est qu'un repli ({@code ESTIMATED})
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Stripe(BigDecimal percentFee, int fixedFeeCents, boolean preferActualFee) {
    }

    /**
     * @param vatRate         TVA retenue et reversee par le store (20 % FR) —
     *                        elle s'applique QUEL QUE SOIT le regime du vendeur
     * @param commissionMode  toujours {@link CommissionMode#MULTIPLY}
     * @param commissionRates taux par store, sur le HT
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Stores(BigDecimal vatRate, CommissionMode commissionMode,
                         Map<Store, BigDecimal> commissionRates) {
    }

    /** Taux de TVA des ventes directes (Stripe) : 0 sous franchise. */
    public BigDecimal directSaleVatRate() {
        return seller.vatRegime() == VatRegime.FRANCHISE_293B ? BigDecimal.ZERO : seller.vatRateIfLiable();
    }

    public BigDecimal commissionRate(Store store) {
        return stores.commissionRates().get(store);
    }
}
