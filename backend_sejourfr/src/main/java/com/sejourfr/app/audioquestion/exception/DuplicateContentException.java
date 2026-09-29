package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** Le transcript genere est trop similaire a un transcript existant en base (anti-doublon pg_trgm). */
public class DuplicateContentException extends AudioGenerationException {

    public DuplicateContentException(String message) {
        super(message);
    }

    @Override public String getCode() { return "DUPLICATE_CONTENT"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.CONFLICT; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_DUPLICATE; }
}
