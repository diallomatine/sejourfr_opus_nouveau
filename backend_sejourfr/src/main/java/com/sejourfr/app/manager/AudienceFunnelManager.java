package com.sejourfr.app.manager;

import com.sejourfr.app.repository.AudienceFunnelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Seule couche autorisee a toucher {@link AudienceFunnelRepository}. Lecture
 * seule : le funnel s'observe, il ne s'ecrit pas ici.
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AudienceFunnelManager {

    private final AudienceFunnelRepository repository;

    public List<AudienceFunnelRepository.CohortCell> signups(Instant from, Instant to) {
        return repository.signupsByCell(from, to);
    }

    public List<AudienceFunnelRepository.DiagnosticCell> diagnostics(Instant from, Instant to) {
        return repository.diagnosticsByCell(from, to);
    }

    public List<AudienceFunnelRepository.EventCell> funnelEvents(Instant from, Instant to) {
        return repository.funnelEventsByCell(from, to);
    }

    public List<AudienceFunnelRepository.CohortCell> purchases(Instant from, Instant to) {
        return repository.purchasesByCell(from, to);
    }

    public List<AudienceFunnelRepository.DailyCell> daily(Instant from, Instant to) {
        return repository.dailyCounts(from, to);
    }

    public AudienceFunnelRepository.IntegrityRow integrity() {
        return repository.diagnosticIntegrity();
    }
}
