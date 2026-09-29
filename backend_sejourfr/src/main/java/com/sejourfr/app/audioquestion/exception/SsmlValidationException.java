package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** SSML retourne par Claude non parseable (XML invalide) ou semantiquement faux. */
public class SsmlValidationException extends AudioGenerationException {

    public SsmlValidationException(String message) {
        super(message);
    }

    public SsmlValidationException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "SSML_INVALID"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.UNPROCESSABLE_CONTENT; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_CONTENT_VALIDATION; }
}
