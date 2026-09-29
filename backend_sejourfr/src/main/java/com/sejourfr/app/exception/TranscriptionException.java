package com.sejourfr.app.exception;

/**
 * Echec definitif de la transcription Whisper (apres retries auto).
 * Sera convertie par l'orchestrateur en submission FAILED.
 */
public class TranscriptionException extends ProductionEvaluationException {
    public TranscriptionException(String message) {
        super(message);
    }

    public TranscriptionException(String message, Throwable cause) {
        super(message, cause);
    }
}
