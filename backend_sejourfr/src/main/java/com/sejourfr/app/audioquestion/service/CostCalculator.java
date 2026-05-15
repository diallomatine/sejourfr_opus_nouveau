package com.sejourfr.app.audioquestion.service;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Convertit les compteurs d'usage (tokens, caracteres) en couts EUR
 * stockes dans audio_question_generation_logs.
 *
 * Tarifs (Sonnet 4.6 + Azure Speech Neural, USD/M unite) -- a tenir a jour.
 * Conversion USD-EUR via taux fixe : suffisant pour de l'audit interne,
 * pas besoin de service de taux temps reel.
 */
@Component
public class CostCalculator {

    private static final BigDecimal ANTHROPIC_INPUT_USD_PER_MTOK = new BigDecimal("3");
    private static final BigDecimal ANTHROPIC_OUTPUT_USD_PER_MTOK = new BigDecimal("15");
    private static final BigDecimal ANTHROPIC_CACHE_READ_USD_PER_MTOK = new BigDecimal("0.30");
    private static final BigDecimal AZURE_TTS_USD_PER_MCHAR = new BigDecimal("16");
    private static final BigDecimal USD_TO_EUR = new BigDecimal("0.92");
    private static final BigDecimal MILLION = new BigDecimal("1000000");
    private static final int SCALE = 5;

    public BigDecimal anthropicCostEur(Integer inputTokens, Integer outputTokens, Integer cacheReadTokens) {
        BigDecimal totalUsd = BigDecimal.ZERO;
        if (inputTokens != null && inputTokens > 0) {
            totalUsd = totalUsd.add(toUsd(inputTokens, ANTHROPIC_INPUT_USD_PER_MTOK));
        }
        if (outputTokens != null && outputTokens > 0) {
            totalUsd = totalUsd.add(toUsd(outputTokens, ANTHROPIC_OUTPUT_USD_PER_MTOK));
        }
        if (cacheReadTokens != null && cacheReadTokens > 0) {
            totalUsd = totalUsd.add(toUsd(cacheReadTokens, ANTHROPIC_CACHE_READ_USD_PER_MTOK));
        }
        return totalUsd.multiply(USD_TO_EUR).setScale(SCALE, RoundingMode.HALF_UP);
    }

    public BigDecimal azureCostEur(int charactersCount) {
        if (charactersCount <= 0) return BigDecimal.ZERO.setScale(SCALE);
        BigDecimal usd = toUsd(charactersCount, AZURE_TTS_USD_PER_MCHAR);
        return usd.multiply(USD_TO_EUR).setScale(SCALE, RoundingMode.HALF_UP);
    }

    private static BigDecimal toUsd(int units, BigDecimal usdPerMillion) {
        return BigDecimal.valueOf(units).multiply(usdPerMillion).divide(MILLION, 10, RoundingMode.HALF_UP);
    }
}
