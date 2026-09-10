package com.sejourfr.app.manager;

import com.sejourfr.app.repository.AiUsageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

/** Seule couche autorisee a toucher {@link AiUsageRepository}. */
@Component
@RequiredArgsConstructor
public class AiUsageManager {

    private final AiUsageRepository repository;

    public List<Object[]> total(Instant from, Instant to) {
        return repository.total(from, to);
    }

    public List<Object[]> parFamille(Instant from, Instant to) {
        return repository.parFamille(from, to);
    }

    public List<Object[]> parSource(Instant from, Instant to) {
        return repository.parSource(from, to);
    }

    public List<Object[]> parModele(Instant from, Instant to) {
        return repository.parModele(from, to);
    }

    public Long coutDiagnosticsMicroUsd(Instant from, Instant to) {
        return repository.coutDiagnosticsMicroUsd(from, to);
    }

    public long diagnosticsClos(Instant from, Instant to) {
        return repository.diagnosticsClos(from, to);
    }
}
