package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Garde-fous des routes publiques de {@code diagnostic_run} (creation et
 * « soumis », lot 2a) : par IP et par identifiant de mesure, seuils dans la
 * configuration versionnee d'analytics ({@code diagnosticRunRateLimit}).
 *
 * <p>Hors {@link RateLimitGuard} a dessein, sur le meme patron que
 * {@link AnalyticsBatchRateLimit} : les bornes de la mesure vivent avec la
 * mesure. Chaque route a ses propres compteurs — un visiteur qui cree sa run
 * ne consomme pas le quota de sa soumission. L'interrupteur global
 * {@code sejourfr.rate-limit.enabled} est respecte.
 */
@Component
@RequiredArgsConstructor
public class DiagnosticRunRateLimit {

    private final RateLimitProperties props;
    private final InMemoryRateLimiter limiter;
    private final AnalyticsConfig config;

    public void checkCreate(String ip, UUID anonymousId) {
        check("diagnostic-run:create", ip, anonymousId);
    }

    public void checkSubmit(String ip, UUID anonymousId) {
        check("diagnostic-run:submit", ip, anonymousId);
    }

    private void check(String portee, String ip, UUID anonymousId) {
        if (!props.isEnabled()) return;
        IpEtIdentifiantLimites.verifier(limiter, portee, config.diagnosticRunRateLimit(), ip, anonymousId);
    }
}
