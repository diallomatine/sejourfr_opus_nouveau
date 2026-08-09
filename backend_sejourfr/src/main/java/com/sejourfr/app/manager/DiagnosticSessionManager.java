package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.repository.DiagnosticSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

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

    public boolean existsByAttemptId(UUID attemptId) { return repository.existsByAttemptId(attemptId); }

    public DiagnosticSession save(DiagnosticSession session) { return repository.save(session); }

    public DiagnosticSession saveAndFlush(DiagnosticSession session) {
        return repository.saveAndFlush(session);
    }

    public int deleteByUserId(UUID userId) { return repository.deleteByUserId(userId); }
}
