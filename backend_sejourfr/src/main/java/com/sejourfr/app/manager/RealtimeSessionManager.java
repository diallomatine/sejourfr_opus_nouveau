package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.repository.RealtimeSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link RealtimeSession}.
 * Seule classe autorisee a appeler {@link RealtimeSessionRepository}.
 */
@Component
@RequiredArgsConstructor
public class RealtimeSessionManager {

    private final RealtimeSessionRepository repository;

    public RealtimeSession save(RealtimeSession session) {
        return repository.save(session);
    }

    public Optional<RealtimeSession> findById(UUID id) {
        return repository.findById(id);
    }

    /** Sessions consommees (ACTIVE + COMPLETED) sur un pass. */
    public long countConsumed(UUID subscriptionId) {
        return repository.countConsumed(subscriptionId);
    }

    /** Sessions PENDING recentes (slots reserves) sur un pass. */
    public long countRecentPending(UUID subscriptionId, Instant cutoff) {
        return repository.countRecentPending(subscriptionId, cutoff);
    }
}
