package com.sejourfr.app.support;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

/**
 * L'horloge des tests d'integration du systeme d'emails : l'heure systeme par
 * defaut, figee par {@link #set(Instant)}. Partagee par tout le contexte de
 * test : {@link #reset()} en {@code @AfterEach}.
 */
public class MutableClock extends Clock {

    private volatile Instant fixed;

    public void set(Instant instant) {
        this.fixed = instant;
    }

    public void reset() {
        this.fixed = null;
    }

    @Override
    public ZoneId getZone() {
        return ZoneOffset.UTC;
    }

    @Override
    public Clock withZone(ZoneId zone) {
        MutableClock self = this;
        return new Clock() {
            @Override
            public ZoneId getZone() {
                return zone;
            }

            @Override
            public Clock withZone(ZoneId z) {
                return self.withZone(z);
            }

            @Override
            public Instant instant() {
                return self.instant();
            }
        };
    }

    @Override
    public Instant instant() {
        Instant f = fixed;
        return f != null ? f : Instant.now();
    }
}
