package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

import java.util.Map;

/**
 * Le contenu renvoye par Claude passe la validation Jakarta mais ne respecte pas
 * une regle metier : voix hors whitelist, durees hors fourchette, 2 reponses
 * correctes, displayOrder mal forme, transcript et SSML incoherents, etc.
 */
public class ContentValidationException extends AudioGenerationException {

    public ContentValidationException(String message) {
        super(message);
    }

    public ContentValidationException(String message, Map<String, Object> details) {
        super(message, details);
    }

    @Override public String getCode() { return "CONTENT_VALIDATION_FAILED"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.UNPROCESSABLE_CONTENT; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_CONTENT_VALIDATION; }
}
