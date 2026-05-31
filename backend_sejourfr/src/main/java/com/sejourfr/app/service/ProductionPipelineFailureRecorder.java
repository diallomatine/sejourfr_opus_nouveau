package com.sejourfr.app.service;

import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Enregistre l'echec d'une submission dans une transaction INDEPENDANTE
 * ({@code REQUIRES_NEW}). Indispensable : quand {@code AiEvaluationService.evaluate}
 * (ou Whisper) leve une exception, la transaction du pipeline est marquee
 * rollback-only ; ecrire {@code FAILED} dedans serait annule au commit (la
 * submission resterait bloquee en EVALUATING). En passant par une transaction
 * neuve, le statut FAILED + le message d'erreur reel persistent quoi qu'il arrive.
 */
@Service
@RequiredArgsConstructor
public class ProductionPipelineFailureRecorder {

    private static final int ERREUR_MESSAGE_MAX_LENGTH = 1000;

    private final ProductionSubmissionManager submissionManager;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(UUID submissionId, String message) {
        submissionManager.findById(submissionId).ifPresent(sub -> {
            sub.setStatut(SubmissionStatut.FAILED);
            String msg = (message == null || message.isBlank())
                    ? "Erreur inconnue lors de l'évaluation" : message;
            sub.setErreurMessage(msg.length() > ERREUR_MESSAGE_MAX_LENGTH
                    ? msg.substring(0, ERREUR_MESSAGE_MAX_LENGTH) : msg);
            submissionManager.save(sub);
        });
    }
}
