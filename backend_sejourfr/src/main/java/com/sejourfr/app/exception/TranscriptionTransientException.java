package com.sejourfr.app.exception;

/**
 * Erreur transitoire Whisper (429 / 5xx / timeout). Declenche un retry via
 * Spring Retry. Si tous les retries echouent, la methode @Recover convertit
 * en {@link TranscriptionException} (definitive).
 */
public class TranscriptionTransientException extends RuntimeException {
    public TranscriptionTransientException(String message) {
        super(message);
    }

    public TranscriptionTransientException(String message, Throwable cause) {
        super(message, cause);
    }
}
