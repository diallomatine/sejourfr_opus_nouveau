package com.sejourfr.app.enums;

/** État exposé aux fronts ; NOT_STARTED représente l'absence de session. */
public enum DiagnosticJourneyStatus {
    NOT_STARTED,
    IN_PROGRESS,
    ANALYZING,
    COMPLETED,
    FAILED
}
