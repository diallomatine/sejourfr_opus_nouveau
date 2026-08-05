package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import com.sejourfr.app.exception.RateLimitException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class InMemoryRateLimiterTest {

    private final InMemoryRateLimiter limiter = new InMemoryRateLimiter();

    private RateLimitProperties.Limit limit(int max, int windowSeconds) {
        return new RateLimitProperties.Limit(max, windowSeconds);
    }

    @Test
    void allowsUpToMax_thenBlocks() {
        RateLimitProperties.Limit limit = limit(3, 600);
        for (int i = 0; i < 3; i++) {
            limiter.check("login", "1.2.3.4", limit);
        }
        assertThatThrownBy(() -> limiter.check("login", "1.2.3.4", limit))
                .isInstanceOf(RateLimitException.class);
    }

    @Test
    void blockedException_carriesRetryAfter() {
        RateLimitProperties.Limit limit = limit(1, 600);
        limiter.check("demo", "k", limit);
        assertThatThrownBy(() -> limiter.check("demo", "k", limit))
                .isInstanceOfSatisfying(RateLimitException.class,
                        ex -> assertThat(ex.getRetryAfterSeconds()).isGreaterThanOrEqualTo(1L));
    }

    @Test
    void distinctKeys_haveIndependentCounters() {
        RateLimitProperties.Limit limit = limit(1, 600);
        limiter.check("login", "ip-a", limit);
        assertThatCode(() -> limiter.check("login", "ip-b", limit)).doesNotThrowAnyException();
    }

    @Test
    void distinctBuckets_haveIndependentCounters() {
        RateLimitProperties.Limit limit = limit(1, 600);
        limiter.check("login", "k", limit);
        assertThatCode(() -> limiter.check("register", "k", limit)).doesNotThrowAnyException();
    }

    @Test
    void zeroMax_disablesLimit() {
        RateLimitProperties.Limit limit = limit(0, 600);
        assertThatCode(() -> {
            for (int i = 0; i < 100; i++) limiter.check("b", "k", limit);
        }).doesNotThrowAnyException();
    }

    @Test
    void nullLimit_isNoOp() {
        assertThatCode(() -> limiter.check("b", "k", null)).doesNotThrowAnyException();
    }

    @Test
    void reset_clearsTheWindowAndAllowsMaxAgain() {
        RateLimitProperties.Limit limit = limit(2, 600);
        limiter.check("login:ip", "1.2.3.4", limit);
        limiter.check("login:ip", "1.2.3.4", limit);

        limiter.reset("login:ip", "1.2.3.4");

        assertThatCode(() -> {
            limiter.check("login:ip", "1.2.3.4", limit);
            limiter.check("login:ip", "1.2.3.4", limit);
        }).doesNotThrowAnyException();
    }

    @Test
    void reset_leavesOtherKeysUntouched() {
        RateLimitProperties.Limit limit = limit(1, 600);
        limiter.check("login:ip", "ip-a", limit);
        limiter.check("login:ip", "ip-b", limit);

        limiter.reset("login:ip", "ip-a");

        assertThatCode(() -> limiter.check("login:ip", "ip-a", limit)).doesNotThrowAnyException();
        assertThatThrownBy(() -> limiter.check("login:ip", "ip-b", limit))
                .isInstanceOf(RateLimitException.class);
    }

    @Test
    void reset_nullOrBlankKey_isNoOp() {
        assertThatCode(() -> {
            limiter.reset("b", null);
            limiter.reset("b", "  ");
        }).doesNotThrowAnyException();
    }

    @Test
    void nullOrBlankKey_isNoOp() {
        RateLimitProperties.Limit limit = limit(1, 600);
        assertThatCode(() -> {
            for (int i = 0; i < 50; i++) limiter.check("b", null, limit);
            for (int i = 0; i < 50; i++) limiter.check("b", "  ", limit);
        }).doesNotThrowAnyException();
    }
}
