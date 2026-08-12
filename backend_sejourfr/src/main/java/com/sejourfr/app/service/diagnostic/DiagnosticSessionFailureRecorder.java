package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Rend l'échec de l'agrégat durable, dans une transaction neuve. */
@Service
@RequiredArgsConstructor
public class DiagnosticSessionFailureRecorder {

    private final DiagnosticSessionManager sessionManager;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void markFailedByAttempt(UUID attemptId, String message) {
        sessionManager.findByAttemptIdWithContent(attemptId).ifPresent(found ->
                sessionManager.findByIdForUpdate(found.getId()).ifPresent(session -> {
                    // Deux pipelines peuvent finir presque simultanément. Un
                    // recorder tardif ne doit jamais rétrograder un agrégat
                    // que l'autre worker vient de compléter sous le verrou.
                    if (session.getStatus() == DiagnosticSessionStatus.COMPLETED) return;
                    session.setStatus(DiagnosticSessionStatus.FAILED);
                    session.setErrorMessage(truncate(message, 1000));
                    sessionManager.save(session);
                }));
    }

    private static String truncate(String value, int max) {
        if (value == null || value.isBlank()) return "L'analyse n'a pas pu aboutir.";
        return value.length() <= max ? value : value.substring(0, max);
    }
}
