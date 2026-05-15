package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/**
 * L'admin a depasse son quota de generations par minute.
 * {@link #getRetryAfterSeconds()} indique le delai a respecter avant un nouvel essai
 * (utilise pour poser le header HTTP Retry-After).
 */
public class RateLimitExceededException extends AudioGenerationException {

    private final long retryAfterSeconds;

    public RateLimitExceededException(String message, long retryAfterSeconds) {
        super(message);
        this.retryAfterSeconds = Math.max(1, retryAfterSeconds);
    }

    public long getRetryAfterSeconds() { return retryAfterSeconds; }

    @Override public String getCode() { return "RATE_LIMIT_EXCEEDED"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.TOO_MANY_REQUESTS; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_RATE_LIMIT; }
}
