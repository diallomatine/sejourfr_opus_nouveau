package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.exception.RateLimitException;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.service.analytics.AnalyticsConfigLoader;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Brief §9 : l'ingestion en lot est limitee par IP ET par identifiant de
 * mesure. Seuils lus dans la config versionnee ({@code ingestion.rateLimit}),
 * appliques par le vrai {@link InMemoryRateLimiter}.
 */
class AnalyticsBatchRateLimitTest {

    private static final AnalyticsConfig CONFIG = AnalyticsConfigLoader.load(1);

    private static AnalyticsBatchRateLimit guard(boolean enabled) {
        RateLimitProperties props = new RateLimitProperties();
        props.setEnabled(enabled);
        return new AnalyticsBatchRateLimit(props, new InMemoryRateLimiter(), CONFIG);
    }

    @Test
    @DisplayName("Un même identifiant de mesure est coupé au-delà de son burst, même depuis des IP différentes")
    void limiteParIdentifiant() {
        AnalyticsBatchRateLimit guard = guard(true);
        UUID anon = UUID.randomUUID();
        int max = CONFIG.ingestion().rateLimit().perAnonymousIdBurst().max();
        for (int i = 0; i < max; i++) {
            guard.check("10.0.0." + (i % 250), anon);
        }
        assertThatThrownBy(() -> guard.check("10.9.9.9", anon)).isInstanceOf(RateLimitException.class);
    }

    @Test
    @DisplayName("Une même IP est coupée au-delà de son burst, même avec des identifiants tournants")
    void limiteParIp() {
        AnalyticsBatchRateLimit guard = guard(true);
        int max = CONFIG.ingestion().rateLimit().perIpBurst().max();
        for (int i = 0; i < max; i++) {
            guard.check("192.0.2.1", UUID.randomUUID());
        }
        assertThatThrownBy(() -> guard.check("192.0.2.1", UUID.randomUUID()))
                .isInstanceOf(RateLimitException.class);
    }

    @Test
    @DisplayName("L'interrupteur global éteint aussi ce garde-fou")
    void interrupteurGlobal() {
        AnalyticsBatchRateLimit guard = guard(false);
        UUID anon = UUID.randomUUID();
        assertThatCode(() -> {
            for (int i = 0; i < 1000; i++) guard.check("192.0.2.1", anon);
        }).doesNotThrowAnyException();
    }
}
