package com.sejourfr.app.audioquestion.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class CostCalculatorTest {

    private final CostCalculator calculator = new CostCalculator();

    @Test
    void anthropicCostEur_input_only_applique_taux_et_conversion_eur() {
        // 1M tokens input * 15 USD/Mtok = 15 USD ; 15 * 0.92 = 13.80000 EUR
        BigDecimal cost = calculator.anthropicCostEur(1_000_000, null, null);
        assertThat(cost).isEqualTo(new BigDecimal("13.80000"));
    }

    @Test
    void anthropicCostEur_somme_les_trois_tiers() {
        // input 1000*15 + output 500*75 + cache 2000*1.5 = 0.0555 USD ; *0.92 = 0.05106 EUR
        BigDecimal cost = calculator.anthropicCostEur(1000, 500, 2000);
        assertThat(cost).isEqualTo(new BigDecimal("0.05106"));
    }

    @Test
    void anthropicCostEur_tous_nuls_renvoie_zero_scale_5() {
        BigDecimal cost = calculator.anthropicCostEur(null, null, null);
        assertThat(cost).isEqualTo(new BigDecimal("0.00000"));
    }

    @Test
    void anthropicCostEur_ignore_les_compteurs_non_positifs() {
        BigDecimal cost = calculator.anthropicCostEur(0, -10, null);
        assertThat(cost).isEqualTo(new BigDecimal("0.00000"));
    }

    @Test
    void anthropicCostEur_cache_read_au_taux_reduit() {
        // 1M cacheRead * 1.50 = 1.5 USD ; *0.92 = 1.38000 EUR
        BigDecimal cost = calculator.anthropicCostEur(null, null, 1_000_000);
        assertThat(cost).isEqualTo(new BigDecimal("1.38000"));
    }

    @Test
    void azureCostEur_million_de_caracteres() {
        // 1M chars * 16 USD/Mchar = 16 USD ; *0.92 = 14.72000 EUR
        BigDecimal cost = calculator.azureCostEur(1_000_000);
        assertThat(cost).isEqualTo(new BigDecimal("14.72000"));
    }

    @Test
    void azureCostEur_arrondit_half_up_a_5_decimales() {
        // 1234 * 16 / 1e6 = 0.0197440000 USD ; *0.92 = 0.01816448 ; setScale(5) = 0.01816
        BigDecimal cost = calculator.azureCostEur(1234);
        assertThat(cost).isEqualTo(new BigDecimal("0.01816"));
    }

    @Test
    void azureCostEur_zero_caractere_renvoie_zero() {
        assertThat(calculator.azureCostEur(0)).isEqualTo(new BigDecimal("0.00000"));
    }

    @Test
    void azureCostEur_compteur_negatif_renvoie_zero() {
        assertThat(calculator.azureCostEur(-5)).isEqualTo(new BigDecimal("0.00000"));
    }
}
