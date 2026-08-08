package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Enregistre l'echec d'une analyse dans une transaction INDEPENDANTE
 * ({@code REQUIRES_NEW}).
 *
 * <p>L'orchestrateur asynchrone n'a volontairement pas de transaction
 * englobante, mais cette isolation reste necessaire : une transaction interne
 * (transcription, analyse) marquee rollback-only ne doit ni annuler le passage
 * en {@code FAILED}, ni laisser la tentative bloquee en {@code EVALUATING} —
 * auquel cas le candidat verrait tourner un indicateur qui ne s'arreterait
 * jamais, sans bouton pour relancer.
 */
@Service
@RequiredArgsConstructor
public class SkillAnalysisFailureRecorder {

    private static final int ERROR_MESSAGE_MAX_LENGTH = 1000;

    private final UserSkillAttemptManager attemptManager;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailed(UUID attemptId, String message) {
        attemptManager.findById(attemptId).ifPresent(attempt -> {
            attempt.setStatut(SkillAttemptStatut.FAILED);
            String msg = (message == null || message.isBlank())
                    ? "Erreur inconnue lors de l'analyse" : message;
            attempt.setErrorMessage(msg.length() > ERROR_MESSAGE_MAX_LENGTH
                    ? msg.substring(0, ERROR_MESSAGE_MAX_LENGTH) : msg);
            attemptManager.save(attempt);
        });
    }
}
