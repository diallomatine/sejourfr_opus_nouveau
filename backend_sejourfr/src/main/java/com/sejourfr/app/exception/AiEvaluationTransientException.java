package com.sejourfr.app.exception;

/**
 * Erreur transitoire Anthropic (429 / 5xx / timeout). Declenche un retry via
 * Spring Retry. Si tous les retries echouent, le @Recover convertit en
 * {@link AiEvaluationException}.
 */
public class AiEvaluationTransientException extends RuntimeException {
    public AiEvaluationTransientException(String message) {
        super(message);
    }

    public AiEvaluationTransientException(String message, Throwable cause) {
        super(message, cause);
    }
}
