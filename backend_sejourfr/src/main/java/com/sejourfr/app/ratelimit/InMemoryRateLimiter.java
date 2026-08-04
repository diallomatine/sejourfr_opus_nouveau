package com.sejourfr.app.ratelimit;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.exception.RateLimitException;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Rate-limiter en memoire a fenetre fixe, partage entre instances de cle
 * (« bucket:cle »). Backe par Caffeine (eviction des cles inactives), sans
 * etat persistant : un redemarrage remet les compteurs a zero — acceptable
 * pour un garde-fou anti-abus (pas un compteur de facturation).
 *
 * <p>Mono-instance : suffisant pour le deploiement actuel (un seul process
 * backend). Si l'app passe en multi-instance, migrer vers un store partage
 * (Redis) ou un rate-limit au niveau du reverse-proxy.
 */
@Component
public class InMemoryRateLimiter {

    private final Cache<String, Window> windows = Caffeine.newBuilder()
            .expireAfterAccess(Duration.ofHours(2))
            .maximumSize(200_000)
            .build();

    /**
     * Incremente le compteur de {@code key} dans {@code bucket} et leve une
     * {@link RateLimitException} si la limite est depassee sur la fenetre.
     * No-op si {@code limit.getMax() <= 0} (limite desactivee) ou {@code key}
     * nulle/vide (appelant non identifiable → on n'enferme pas un trafic
     * legitime non attribuable).
     */
    public void check(String bucket, String key, RateLimitProperties.Limit limit) {
        if (limit == null || limit.getMax() <= 0) return;
        if (key == null || key.isBlank()) return;

        long windowMs = Math.max(1L, (long) limit.getWindowSeconds() * 1000L);
        long now = System.currentTimeMillis();
        Window window = windows.get(bucket + ':' + key, k -> new Window());

        long retryAfterMs;
        boolean exceeded;
        synchronized (window) {
            if (now - window.startMs >= windowMs) {
                window.startMs = now;
                window.count = 0;
            }
            window.count++;
            exceeded = window.count > limit.getMax();
            retryAfterMs = windowMs - (now - window.startMs);
        }

        if (exceeded) {
            long retryAfter = Math.max(1L, (retryAfterMs + 999L) / 1000L);
            throw new RateLimitException(
                    "Trop de tentatives. Reessayez dans " + retryAfter + "s.", retryAfter);
        }
    }

    /**
     * Oublie le compteur de {@code key} dans {@code bucket}. Appele quand
     * l'action protegee a REUSSI (ex: authentification valide) : le garde-fou
     * ne doit compter que les echecs, sinon un usage legitime repete finit
     * lui-meme en 429.
     */
    public void reset(String bucket, String key) {
        if (key == null || key.isBlank()) return;
        windows.invalidate(bucket + ':' + key);
    }

    /** Compteur de fenetre. Acces synchronise sur l'instance (identite stable en cache). */
    private static final class Window {
        private long startMs = System.currentTimeMillis();
        private int count;
    }
}
