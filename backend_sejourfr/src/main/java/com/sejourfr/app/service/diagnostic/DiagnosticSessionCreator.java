package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.DiagnosticSessionManager;
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
    private final DiagnosticContentResolver content;
    private final AttemptService attemptService;
    private final DiagnosticSessionManager sessionManager;

    /**
     * @param requestedWrittenTaskId le sujet que le candidat a réellement lu et
     *                               traité, quand le diagnostic tire dans un
     *                               pool (L3). {@code null} ⇒ tirage ici.
     *                               🛑 Il est <b>vérifié</b> contre le pool
     *                               actif : un identifiant reçu du client ne
     *                               désigne jamais une tâche arbitraire.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public DiagnosticSession create(UUID userId, String code, int version,
                                    ClientPlatform platform, UUID requestedWrittenTaskId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        // Mêmes sujets que ceux servis publiquement au visiteur sans compte
        // (cf. DiagnosticContentResolver) : ce qu'il a rédigé avant de
        // s'inscrire doit correspondre à la tâche de la session créée ici.
        ProductionTask writtenTask =
                content.writtenTaskOrDraw(code, version, requestedWrittenTaskId);
        // 🛑 L'étape orale n'existe que si le CONTENU en porte une. Le
        // diagnostic rapide (L3) n'en a pas, et créer un attempt orphelin
        // « au cas où » réclamerait au candidat une production dont le sujet
        // n'existe pas.
        ProductionTask oralTask = content.oralTask(code, version).orElse(null);
        Attempt writtenAttempt = attemptService.createDiagnosticProductionAttempt(userId, EpreuveType.TCF_EE);
        Attempt oralAttempt = oralTask == null ? null
                : attemptService.createDiagnosticProductionAttempt(userId, EpreuveType.TCF_EO);

        DiagnosticSession session = new DiagnosticSession();
        session.setUser(user);
        session.setDiagnosticCode(code);
        session.setDiagnosticVersion(version);
        session.setWrittenTask(writtenTask);
        session.setOralTask(oralTask);
        session.setWrittenAttempt(writtenAttempt);
        session.setOralAttempt(oralAttempt);
        session.setStatus(DiagnosticSessionStatus.IN_PROGRESS);
        // Plateforme du moment : on la pose ici parce que c'est le seul instant
        // où la requête du candidat est encore là. Une reprise cross-device ne
        // la réécrit pas — ce qu'on mesure, c'est où le diagnostic a commencé.
        session.setPlatform(platform == null ? ClientPlatform.UNKNOWN : platform);
        session.setStartedAt(Instant.now());
        return sessionManager.saveAndFlush(session);
    }
}
