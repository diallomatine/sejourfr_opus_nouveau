package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AttemptService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/** Transaction isolée de création, afin qu'une course d'unicité soit rejouable. */
@Service
@RequiredArgsConstructor
public class DiagnosticSessionCreator {

    private final UserManager userManager;
    private final ProductionTaskManager taskManager;
    private final AttemptService attemptService;
    private final DiagnosticSessionManager sessionManager;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public DiagnosticSession create(UUID userId, String code, int version) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        ProductionTask writtenTask = taskManager.findActiveDiagnostic(code, version, EpreuveType.TCF_EE)
                .orElseThrow(() -> new IllegalStateException("Sujet diagnostic EE actif introuvable"));
        ProductionTask oralTask = taskManager.findActiveDiagnostic(code, version, EpreuveType.TCF_EO)
                .orElseThrow(() -> new IllegalStateException("Sujet diagnostic EO actif introuvable"));
        Attempt writtenAttempt = attemptService.createDiagnosticProductionAttempt(userId, EpreuveType.TCF_EE);
        Attempt oralAttempt = attemptService.createDiagnosticProductionAttempt(userId, EpreuveType.TCF_EO);

        DiagnosticSession session = new DiagnosticSession();
        session.setUser(user);
        session.setDiagnosticCode(code);
        session.setDiagnosticVersion(version);
        session.setWrittenTask(writtenTask);
        session.setOralTask(oralTask);
        session.setWrittenAttempt(writtenAttempt);
        session.setOralAttempt(oralAttempt);
        session.setStatus(DiagnosticSessionStatus.IN_PROGRESS);
        session.setStartedAt(Instant.now());
        return sessionManager.saveAndFlush(session);
    }
}
