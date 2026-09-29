package com.sejourfr.app.service.competence;

/** Analyse ciblee d'une production de competence. Implementation reelle livree a part. */
public interface CompetenceAnalysisService {
    /** Analyse la tentative et persiste le resultat (criterion_status, analysis_json, cout). */
    void analyse(java.util.UUID attemptId);
}
