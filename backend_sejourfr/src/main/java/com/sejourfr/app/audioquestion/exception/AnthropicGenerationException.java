package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** Echec definitif de l'appel a l'API Anthropic (4xx hors 429, 5xx apres tous les retries). */
public class AnthropicGenerationException extends AudioGenerationException {

    public AnthropicGenerationException(String message) {
        super(message);
    }

    public AnthropicGenerationException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "ANTHROPIC_API_ERROR"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.BAD_GATEWAY; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_ANTHROPIC; }
}
