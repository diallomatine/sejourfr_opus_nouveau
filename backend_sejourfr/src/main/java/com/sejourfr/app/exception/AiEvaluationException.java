package com.sejourfr.app.exception;

/**
 * Echec definitif de l'evaluation LLM (apres retries auto, ou reponse
 * invalide cote schema). Convertie en submission FAILED par l'orchestrateur.
 */
public class AiEvaluationException extends ProductionEvaluationException {
    public AiEvaluationException(String message) {
        super(message);
    }

    public AiEvaluationException(String message, Throwable cause) {
        super(message, cause);
    }
}
