package com.sejourfr.app.service.activity;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.UserActivityManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.util.FenetreMesure;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Enregistre l'<b>activite</b> d'un compte connecte ({@code user_activity_day},
 * V087) : toute requete authentifiee, heartbeat compris (D1).
 *
 * <p><b>Au plus une ecriture par intervalle</b>
 * ({@code activity.writeIntervalSeconds}, 60 s) et par (compte, plateforme,
 * jour de Paris) : un cache en memoire retient le dernier instant ecrit. Un
 * nouveau jour force une ecriture (la cle change). Mono-instance : en
 * multi-instance, au pire une ecriture par instance et par minute.
 *
 * <p><b>Best-effort</b> : ne leve jamais. Une mesure d'activite n'a pas le droit
 * de faire echouer la requete qui la porte.
 */
@Service
@Slf4j
public class UserActivityService {

    private final UserActivityManager manager;
    private final Clock clock;
    private final Duration writeInterval;
    private final Cache<Key, Instant> lastWrites;

    private record Key(UUID userId, ClientPlatform platform, LocalDate day) {
    }

    public UserActivityService(UserActivityManager manager, AnalyticsConfig config, Clock clock) {
        this.manager = manager;
        this.clock = clock;
        this.writeInterval = config.activity().writeInterval();
        this.lastWrites = Caffeine.newBuilder()
                .expireAfterAccess(writeInterval.multipliedBy(2))
                .maximumSize(100_000)
                .build();
    }

    /** @return vrai si une ligne a ete ecrite (faux : limitee, ou echec avale) */
    public boolean touch(UUID userId, ClientPlatform platform) {
        if (userId == null) return false;
        Instant now = clock.instant();
        ClientPlatform p = platform == null ? ClientPlatform.UNKNOWN : platform;
        Key key = new Key(userId, p, LocalDate.ofInstant(now, FenetreMesure.PARIS));
        boolean[] due = {false};
        lastWrites.asMap().compute(key, (k, last) -> {
            if (last == null || !now.isBefore(last.plus(writeInterval))) {
                due[0] = true;
                return now;
            }
            return last;
        });
        if (!due[0]) return false;
        try {
            manager.touch(userId, key.day(), p, now);
            return true;
        } catch (RuntimeException e) {
            lastWrites.invalidate(key);
            log.warn("Activite non enregistree : {}", e.toString());
            return false;
        }
    }

    /** Oublie les dernieres ecritures (tests a horloge fixee). */
    public void resetThrottle() {
        lastWrites.invalidateAll();
    }
}
