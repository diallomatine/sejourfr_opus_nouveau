package com.sejourfr.app.exception;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;

/**
 * Levée par {@code PublicAttemptService.startDemo} quand un visiteur a déjà
 * consommé son quota gratuit (1 attempt par module / type / mois calendaire
 * par IP). Mappée en HTTP 429 dans {@link GlobalExceptionHandler}.
 */
public class DemoLimitReachedException extends RuntimeException {

    private final Module module;
    private final AttemptType attemptType;

    public DemoLimitReachedException(Module module, AttemptType attemptType) {
        super("Quota démo gratuit atteint pour ce module ce mois-ci");
        this.module = module;
        this.attemptType = attemptType;
    }

    public Module getModule() {
        return module;
    }

    public AttemptType getAttemptType() {
        return attemptType;
    }
}
