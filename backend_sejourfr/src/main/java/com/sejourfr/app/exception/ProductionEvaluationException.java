package com.sejourfr.app.exception;

/**
 * Erreur du pipeline d'evaluation des productions (EO/EE).
 * Cause typique : transcription Whisper ou evaluation Claude qui a echoue
 * malgre les retries. Materialisee dans {@code production_submissions.statut = FAILED}
 * avec le message dans {@code erreur_message}.
 */
public class ProductionEvaluationException extends RuntimeException {
    public ProductionEvaluationException(String message) {
        super(message);
    }

    public ProductionEvaluationException(String message, Throwable cause) {
        super(message, cause);
    }
}
