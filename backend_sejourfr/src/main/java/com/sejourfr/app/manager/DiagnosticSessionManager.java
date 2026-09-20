package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.repository.DiagnosticSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class DiagnosticSessionManager {

    private final DiagnosticSessionRepository repository;

    public Optional<DiagnosticSession> findById(UUID id) { return repository.findById(id); }

    public Optional<DiagnosticSession> findByUserAndVersionWithContent(
            UUID userId, String code, int version) {
        return repository.findByUserAndVersionWithContent(userId, code, version);
    }

    public Optional<DiagnosticSession> findOwnedWithContent(UUID id, UUID userId) {
        return repository.findOwnedWithContent(id, userId);
    }

    public Optional<DiagnosticSession> findByAttemptIdWithContent(UUID attemptId) {
        return repository.findByAttemptIdWithContent(attemptId);
    }

    public Optional<DiagnosticSession> findByIdForUpdate(UUID id) {
        return repository.findByIdForUpdate(id);
    }

    public Optional<DiagnosticSession> findLatestCompleted(UUID userId) {
        return repository.findFirstByUserIdAndStatusOrderByCompletedAtDesc(
                userId, DiagnosticSessionStatus.COMPLETED);
    }

    /**
     * Les attempts de cette session : l'ecrit, et l'oral quand il existe. Liste
     * vide si la session n'existe pas.
     */
    public List<UUID> findAttemptIdsBySessionId(UUID sessionId) {
        if (sessionId == null) return List.of();
        List<UUID> attempts = new ArrayList<>();
        for (Object[] ligne : repository.findAttemptIdsById(sessionId)) {
            for (Object valeur : ligne) {
                if (valeur != null) attempts.add((UUID) valeur);
            }
        }
        return attempts;
    }

    /**
     * La session de diagnostic rapide de chacun de ces attempts, en une
     * requete. Un attempt qui n'appartient a aucune session est absent du
     * resultat.
     */
    public Map<UUID, UUID> findSessionIdByAttemptIds(Collection<UUID> attemptIds) {
        if (attemptIds == null || attemptIds.isEmpty()) return Map.of();
        Map<UUID, UUID> parAttempt = new LinkedHashMap<>();
        for (Object[] ligne : repository.findIdsByAttemptIds(attemptIds)) {
            if (ligne.length < 3 || ligne[0] == null) continue;
            UUID session = (UUID) ligne[0];
            if (ligne[1] != null) parAttempt.put((UUID) ligne[1], session);
            if (ligne[2] != null) parAttempt.put((UUID) ligne[2], session);
        }
        return parAttempt;
    }

    public boolean existsByAttemptId(UUID attemptId) { return repository.existsByAttemptId(attemptId); }

    public DiagnosticSession save(DiagnosticSession session) { return repository.save(session); }

    public DiagnosticSession saveAndFlush(DiagnosticSession session) {
        return repository.saveAndFlush(session);
    }

    public int deleteByUserId(UUID userId) { return repository.deleteByUserId(userId); }
}
