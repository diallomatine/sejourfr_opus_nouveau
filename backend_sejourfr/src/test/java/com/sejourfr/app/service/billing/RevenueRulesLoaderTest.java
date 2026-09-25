package com.sejourfr.app.service.billing;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/** Les regles de revenus se chargent, ou le demarrage echoue. */
class RevenueRulesLoaderTest {

    private static final String VALIDE = """
            {"revenueRulesVersion":1,"currency":"EUR","rounding":"HALF_UP",
             "seller":{"vatRegime":"FRANCHISE_293B","vatRateIfLiable":0.20},
             "stripe":{"percentFee":0.015,"fixedFeeCents":25,"preferActualFee":true},
             "stores":{"vatRate":0.20,"commissionMode":"MULTIPLY",
                       "commissionRates":{"APPLE":0.15,"GOOGLE":0.15}}}
            """;

    private static RevenueRules parse(String json) throws Exception {
        return RevenueRulesLoader.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)), 1, "test.json");
    }

    /** Arbitrage Q1 : franchise en base, TVA store 20 %, MULTIPLY, Stripe 1,5 % + 25 c. */
    @Test
    @DisplayName("La version livrée se charge et porte les arbitrages Q1")
    void laVersionLivreeSeCharge() {
        RevenueRules rules = RevenueRulesLoader.load(1);

        assertThat(rules.seller().vatRegime()).isEqualTo(RevenueRules.VatRegime.FRANCHISE_293B);
        assertThat(rules.stores().vatRate()).isEqualByComparingTo("0.20");
        assertThat(rules.stores().commissionMode()).isEqualTo(RevenueRules.CommissionMode.MULTIPLY);
        assertThat(rules.commissionRate(RevenueRules.Store.APPLE)).isEqualByComparingTo("0.15");
        assertThat(rules.commissionRate(RevenueRules.Store.GOOGLE)).isEqualByComparingTo("0.15");
        assertThat(rules.stripe().percentFee()).isEqualByComparingTo("0.015");
        assertThat(rules.stripe().fixedFeeCents()).isEqualTo(25);
        assertThat(rules.stripe().preferActualFee()).isTrue();
    }

    /** Sous franchise (art. 293 B), une vente directe ne porte aucune TVA. */
    @Test
    @DisplayName("Sous franchise, la TVA des ventes directes vaut 0 ; assujetti, le taux configuré")
    void tvaDesVentesDirectes() throws Exception {
        assertThat(parse(VALIDE).directSaleVatRate()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(parse(VALIDE.replace("FRANCHISE_293B", "ASSUJETTI")).directSaleVatRate())
                .isEqualByComparingTo("0.20");
    }

    @Test
    @DisplayName("Une version inconnue échoue au démarrage")
    void versionInconnue() {
        assertThatThrownBy(() -> RevenueRulesLoader.load(99)).isInstanceOf(IllegalStateException.class);
    }

    /** DIVIDE sous-estime la commission : il n'est pas un choix possible. */
    @Test
    @DisplayName("Un mode de commission autre que MULTIPLY est refusé")
    void modeDivideRefuse() {
        assertThatThrownBy(() -> parse(VALIDE.replace("MULTIPLY", "DIVIDE"))).isInstanceOf(Exception.class);
    }

    @Test
    @DisplayName("Un store sans taux de commission est refusé")
    void storeSansTaux() {
        assertThatThrownBy(() -> parse(VALIDE.replace(",\"GOOGLE\":0.15", "")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("GOOGLE");
    }

    @Test
    @DisplayName("Un taux hors [0, 1[ est refusé")
    void tauxHorsBornes() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"APPLE\":0.15", "\"APPLE\":15")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("APPLE");
    }

    @Test
    @DisplayName("Une devise autre qu'EUR, ou un arrondi autre que HALF_UP, est refusé")
    void deviseEtArrondiImposes() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"EUR\"", "\"USD\"")))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("currency");
        assertThatThrownBy(() -> parse(VALIDE.replace("HALF_UP", "HALF_EVEN")))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("rounding");
    }

    @Test
    @DisplayName("Une clé inconnue est refusée")
    void cleInconnue() {
        assertThatThrownBy(() -> parse(VALIDE.replace("\"rounding\":\"HALF_UP\",",
                "\"rounding\":\"HALF_UP\",\"vat_rate\":0.2,"))).isInstanceOf(Exception.class);
    }
}
