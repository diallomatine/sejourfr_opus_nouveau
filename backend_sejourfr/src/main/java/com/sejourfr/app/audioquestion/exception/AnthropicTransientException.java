package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/**
 * Erreur transitoire Anthropic (timeout, 429, 5xx) : declenche les @Retryable
 * du client. Si tous les retries echouent, le client convertit en
 * {@link AnthropicGenerationException} (non transient).
 */
public class AnthropicTransientException extends AudioGenerationException {

    public AnthropicTransientException(String message) {
        super(message);
    }

    public AnthropicTransientException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "ANTHROPIC_API_ERROR"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.BAD_GATEWAY; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_ANTHROPIC; }
}
