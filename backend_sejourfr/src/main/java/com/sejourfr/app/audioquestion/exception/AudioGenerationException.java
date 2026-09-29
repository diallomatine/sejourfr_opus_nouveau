package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

import java.util.Map;

/**
 * Exception de base pour la pipeline de generation audio.
 * Chaque sous-classe porte :
 *   - un code applicatif (consomme par le front pour afficher un message)
 *   - un statut HTTP cible
 *   - le statut metier {@link GenerationStatus} a logger dans audio_question_generation_logs
 */
public abstract class AudioGenerationException extends RuntimeException {

    private final Map<String, Object> details;

    protected AudioGenerationException(String message) {
        super(message);
        this.details = null;
    }

    protected AudioGenerationException(String message, Throwable cause) {
        super(message, cause);
        this.details = null;
    }

    protected AudioGenerationException(String message, Map<String, Object> details) {
        super(message);
        this.details = details;
    }

    protected AudioGenerationException(String message, Map<String, Object> details, Throwable cause) {
        super(message, cause);
        this.details = details;
    }

    public abstract String getCode();

    public abstract HttpStatus getHttpStatus();

    public abstract GenerationStatus getGenerationStatus();

    public Map<String, Object> getDetails() {
        return details;
    }
}
