package com.sejourfr.app.manager;

import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.repository.TcfDiagnosticSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link TcfDiagnosticSessionRepository}. */
@Component
@RequiredArgsConstructor
public class TcfDiagnosticSessionManager {

    private final TcfDiagnosticSessionRepository repository;

    public TcfDiagnosticSession save(TcfDiagnosticSession session) {
        return repository.save(session);
    }

    public Optional<TcfDiagnosticSession> findById(UUID id) {
        return repository.findByIdWithParent(id);
    }

    /** Le diagnostic le plus recent, ou vide si le candidat n'en a jamais ouvert. */
    public Optional<TcfDiagnosticSession> findLatest(UUID userId) {
        List<TcfDiagnosticSession> all = repository.findByUserOrderByStartedAtDesc(userId);
        return all.isEmpty() ? Optional.empty() : Optional.of(all.get(0));
    }

    public List<TcfDiagnosticSession> findAllByUser(UUID userId) {
        return repository.findByUserOrderByStartedAtDesc(userId);
    }

    public long countByUser(UUID userId) {
        return repository.countByUserId(userId);
    }
}
