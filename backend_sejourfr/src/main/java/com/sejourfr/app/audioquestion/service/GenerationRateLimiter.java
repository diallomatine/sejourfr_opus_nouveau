package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AudioGenerationProperties;
import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import com.sejourfr.app.audioquestion.exception.RateLimitExceededException;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Verifie qu'un admin n'a pas depasse son quota de generations SUCCESS sur la derniere minute.
 * Le quota est configurable via {@code sejourfr.audio-generation.rate-limit-per-minute}.
 * Les echecs (FAILED_*) ne sont pas comptes : l'admin peut retenter sans penalite.
 */
@Service
public class GenerationRateLimiter {

    private final AudioQuestionGenerationLogRepository logRepository;
    private final AudioGenerationProperties props;
    private final Clock clock;

    public GenerationRateLimiter(
            AudioQuestionGenerationLogRepository logRepository,
            AudioGenerationProperties props) {
        this.logRepository = logRepository;
        this.props = props;
        this.clock = Clock.systemUTC();
    }

    public void checkAllowed(UUID adminUserId) {
        int max = props.getRateLimitPerMinute();
        if (max <= 0) return;

        Instant now = Instant.now(clock);
        Instant oneMinuteAgo = now.minus(Duration.ofMinutes(1));
        long recent = logRepository.countByAdminUserIdAndStatusAndCreatedAtAfter(
            adminUserId, GenerationStatus.SUCCESS, oneMinuteAgo
        );

        if (recent < max) return;

        Instant oldest = logRepository.findOldestRecentSuccessAt(adminUserId, oneMinuteAgo)
            .orElse(oneMinuteAgo);
        long retryAfter = 60 - Duration.between(oldest, now).getSeconds();
        if (retryAfter < 1) retryAfter = 1;

        throw new RateLimitExceededException(
            "Quota de " + max + " generations par minute atteint. Reessayez dans " + retryAfter + "s.",
            retryAfter
        );
    }
}
