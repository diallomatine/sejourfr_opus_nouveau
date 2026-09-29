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
 * ({@code REQUIRES_NEW}). L'orchestrateur async n'a plus de transaction
 * englobante, mais cette isolation reste volontaire : une transaction interne
 * d'evaluation ou de transcription en echec ne doit jamais annuler le statut
 * FAILED ni laisser la submission bloquee en EVALUATING.
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
