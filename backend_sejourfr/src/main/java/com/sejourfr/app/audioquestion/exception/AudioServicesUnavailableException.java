package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/**
 * L'un des services externes n'est pas configure (cle API absente).
 * On le detecte au demarrage de l'appel pour eviter un 502 confus.
 */
public class AudioServicesUnavailableException extends AudioGenerationException {

    public AudioServicesUnavailableException(String message) {
        super(message);
    }

    @Override public String getCode() { return "AUDIO_SERVICES_UNAVAILABLE"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.SERVICE_UNAVAILABLE; }
    @Override public GenerationStatus getGenerationStatus() { return GenerationStatus.FAILED_VALIDATION; }
}
