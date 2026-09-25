package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.service.analytics.AnalyticsConfig;

import java.util.UUID;

/**
 * Les quatre fenetres d'une route publique de mesure : burst et plafond
 * journalier, par <b>IP</b> et par <b>identifiant de mesure</b>. Une seule
 * ecriture, partagee par l'ingestion en lot et par {@code diagnostic_run}.
 *
 * <p>Un {@code anonymousId} n'est pas un secret : le limiter seul, un bot le
 * changerait a chaque appel. C'est l'IP qui coupe la boucle ; la limite par
 * identifiant empeche un seul visiteur d'occuper le quota de toute une IP
 * partagee. Un identifiant absent n'est pas limite par identifiant.
 */
final class IpEtIdentifiantLimites {

    private IpEtIdentifiantLimites() {
    }

    static void verifier(InMemoryRateLimiter limiter, String portee, AnalyticsConfig.RateLimit rl,
                         String ip, UUID anonymousId) {
        limiter.check(portee + ":ip:burst", ip, limite(rl.perIpBurst()));
        limiter.check(portee + ":ip:daily", ip, limite(rl.perIpDaily()));
        String anon = anonymousId == null ? null : anonymousId.toString();
        limiter.check(portee + ":anon:burst", anon, limite(rl.perAnonymousIdBurst()));
        limiter.check(portee + ":anon:daily", anon, limite(rl.perAnonymousIdDaily()));
    }

    private static RateLimitProperties.Limit limite(AnalyticsConfig.Window w) {
        return new RateLimitProperties.Limit(w.max(), w.windowSeconds());
    }
}
