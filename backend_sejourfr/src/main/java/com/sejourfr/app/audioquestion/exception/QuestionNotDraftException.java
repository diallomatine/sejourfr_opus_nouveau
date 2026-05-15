package com.sejourfr.app.audioquestion.exception;

import com.sejourfr.app.audioquestion.entity.GenerationStatus;
import org.springframework.http.HttpStatus;

/**
 * Tentative de valider ou rejeter une question qui n'est plus au statut DRAFT
 * (par ex. deja ACTIVE ou ARCHIVED).
 */
public class QuestionNotDraftException extends AudioGenerationException {

    public QuestionNotDraftException(String message) {
        super(message);
    }

    @Override public String getCode() { return "QUESTION_NOT_DRAFT"; }
    @Override public HttpStatus getHttpStatus() { return HttpStatus.CONFLICT; }
    // Pas de generation associee : ne sera pas log dans la table d'audit.
    @Override public GenerationStatus getGenerationStatus() { return null; }
}
