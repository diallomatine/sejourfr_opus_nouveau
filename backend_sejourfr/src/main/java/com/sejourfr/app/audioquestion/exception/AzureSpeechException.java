package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/** Echec definitif de la synthese vocale Azure Speech. */
public class AzureSpeechException extends AudioGenerationException {

    public AzureSpeechException(String message) {
        super(message);
    }

    public AzureSpeechException(String message, Throwable cause) {
        super(message, cause);
    }

    @Override public String getCode() { return "AZURE_SPEECH_API_ERROR"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.BAD_GATEWAY; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_AZURE_SPEECH; }
}
