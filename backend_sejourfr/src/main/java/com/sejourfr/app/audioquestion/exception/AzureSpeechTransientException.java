package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** Erreur transitoire Azure Speech (401, 429, 5xx, timeout) : declenche les @Retryable. */
public class AzureSpeechTransientException extends AudioGenerationException {

    public AzureSpeechTransientException(String message) {
        super(message);
    }

    public AzureSpeechTransientException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "AZURE_SPEECH_API_ERROR"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.BAD_GATEWAY; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_AZURE_SPEECH; }
}
