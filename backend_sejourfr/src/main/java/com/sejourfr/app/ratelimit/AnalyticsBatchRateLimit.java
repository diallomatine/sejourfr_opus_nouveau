package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Garde-fous de l'ingestion en lot ({@code POST /api/public/analytics/events/batch}) :
 * par <b>IP</b> ET par <b>identifiant de mesure</b> (brief §9), un burst court et
 * un plafond journalier chacun. Un lot compte pour un appel ; sa taille est
 * bornee a part ({@code ingestion.maxBatchSize}).
 *
 * <p>Separe de {@link RateLimitGuard} a dessein : les seuils vivent dans la
 * configuration versionnee d'analytics ({@code ingestion.rateLimit}), avec le
 * reste des bornes de l'ingestion, et le meme {@link InMemoryRateLimiter} les
 * applique. L'interrupteur global {@code sejourfr.rate-limit.enabled} est
 * respecte (il est eteint en test).
 *
 * <p>Un {@code anonymousId} n'est pas un secret : le limiter par lui seul, un
 * bot le changerait a chaque lot. C'est l'IP qui coupe la boucle ; la limite par
 * identifiant empeche un seul visiteur (ou un identifiant rejoue en masse)
 * d'occuper le quota de toute une IP partagee.
 */
@Component
@RequiredArgsConstructor
public class AnalyticsBatchRateLimit {

    private final RateLimitProperties props;
    private final InMemoryRateLimiter limiter;
    private final AnalyticsConfig config;

    public void check(String ip, UUID anonymousId) {
        if (!props.isEnabled()) return;
        AnalyticsConfig.RateLimit rl = config.ingestion().rateLimit();
        limiter.check("analytics-batch:ip:burst", ip, limit(rl.perIpBurst()));
        limiter.check("analytics-batch:ip:daily", ip, limit(rl.perIpDaily()));
        String anon = anonymousId == null ? null : anonymousId.toString();
        limiter.check("analytics-batch:anon:burst", anon, limit(rl.perAnonymousIdBurst()));
        limiter.check("analytics-batch:anon:daily", anon, limit(rl.perAnonymousIdDaily()));
    }

    private static RateLimitProperties.Limit limit(AnalyticsConfig.Window w) {
        return new RateLimitProperties.Limit(w.max(), w.windowSeconds());
    }
}
