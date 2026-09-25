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

/** Routes publiques de diagnostic_run : par IP et par identifiant, seuils de la config versionnée. */
class DiagnosticRunRateLimitTest {

    private static final AnalyticsConfig CONFIG = AnalyticsConfigLoader.load(1);

    private static DiagnosticRunRateLimit guard(boolean enabled) {
        RateLimitProperties props = new RateLimitProperties();
        props.setEnabled(enabled);
        return new DiagnosticRunRateLimit(props, new InMemoryRateLimiter(), CONFIG);
    }

    @Test
    @DisplayName("Une IP est coupée au-delà de son burst, même avec des identifiants tournants")
    void limiteParIp() {
        DiagnosticRunRateLimit guard = guard(true);
        int max = CONFIG.diagnosticRunRateLimit().perIpBurst().max();
        for (int i = 0; i < max; i++) guard.checkCreate("192.0.2.1", UUID.randomUUID());
        assertThatThrownBy(() -> guard.checkCreate("192.0.2.1", UUID.randomUUID()))
                .isInstanceOf(RateLimitException.class);
    }

    @Test
    @DisplayName("Un identifiant est coupé au-delà de son burst, même depuis des IP différentes")
    void limiteParIdentifiant() {
        DiagnosticRunRateLimit guard = guard(true);
        UUID anon = UUID.randomUUID();
        int max = CONFIG.diagnosticRunRateLimit().perAnonymousIdBurst().max();
        for (int i = 0; i < max; i++) guard.checkSubmit("10.0.0." + i, anon);
        assertThatThrownBy(() -> guard.checkSubmit("10.9.9.9", anon)).isInstanceOf(RateLimitException.class);
    }

    @Test
    @DisplayName("Créer et soumettre ont des compteurs séparés ; l'interrupteur global éteint tout")
    void compteursSeparesEtInterrupteur() {
        DiagnosticRunRateLimit guard = guard(true);
        UUID anon = UUID.randomUUID();
        int max = CONFIG.diagnosticRunRateLimit().perAnonymousIdBurst().max();
        for (int i = 0; i < max; i++) guard.checkCreate("10.1.0." + i, anon);
        assertThatCode(() -> guard.checkSubmit("10.2.0.1", anon)).doesNotThrowAnyException();

        DiagnosticRunRateLimit eteint = guard(false);
        assertThatCode(() -> {
            for (int i = 0; i < 1000; i++) eteint.checkCreate("192.0.2.1", anon);
        }).doesNotThrowAnyException();
    }
}
