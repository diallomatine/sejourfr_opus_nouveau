package com.sejourfr.app.exception;

/**
 * Levee lorsqu'un appelant depasse une limite anti-abus (cf.
 * {@code RateLimitProperties}). Mappee en {@code 429 Too Many Requests} par
 * {@link GlobalExceptionHandler}, avec un header {@code Retry-After}.
 *
 * <p>Le message reste volontairement generique (« trop de tentatives ») pour
 * ne pas constituer un oracle (ex : reveler si un email existe). Distincte de
 * la {@code RateLimitExceededException} du sous-module {@code audioquestion}.
 */
public class RateLimitException extends RuntimeException {

    private final long retryAfterSeconds;

    public RateLimitException(String message, long retryAfterSeconds) {
        super(message);
        this.retryAfterSeconds = Math.max(1, retryAfterSeconds);
    }

    public long getRetryAfterSeconds() {
        return retryAfterSeconds;
    }
}
