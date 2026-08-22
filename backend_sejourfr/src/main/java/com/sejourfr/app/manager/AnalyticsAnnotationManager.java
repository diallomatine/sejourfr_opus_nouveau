package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AnalyticsAnnotation;
import com.sejourfr.app.repository.AnalyticsAnnotationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link AnalyticsAnnotationRepository}. */
@Component
@RequiredArgsConstructor
public class AnalyticsAnnotationManager {

    private final AnalyticsAnnotationRepository repository;

    @Transactional(readOnly = true)
    public List<AnalyticsAnnotation> between(LocalDate from, LocalDate to) {
        return repository.findByOccurredOnBetweenOrderByOccurredOnAsc(from, to);
    }

    @Transactional(readOnly = true)
    public Optional<AnalyticsAnnotation> findById(UUID id) {
        return repository.findById(id);
    }

    @Transactional
    public AnalyticsAnnotation save(AnalyticsAnnotation annotation) {
        return repository.save(annotation);
    }

    @Transactional
    public void delete(AnalyticsAnnotation annotation) {
        repository.delete(annotation);
    }
}
