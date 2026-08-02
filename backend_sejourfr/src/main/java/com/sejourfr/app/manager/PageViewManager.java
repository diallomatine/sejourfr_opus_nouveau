package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PageView;
import com.sejourfr.app.enums.PageViewEvent;
import com.sejourfr.app.repository.PageViewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Seule couche autorisée à toucher {@link PageViewRepository}. */
@Component
@RequiredArgsConstructor
public class PageViewManager {

    private final PageViewRepository repository;

    @Transactional
    public void increment(String path, String source, PageViewEvent event, LocalDate day) {
        repository.increment(UUID.randomUUID(), path, source, event.name(), day);
    }

    /** Tous les buckets d'une page depuis {@code from} inclus. */
    @Transactional(readOnly = true)
    public List<PageView> since(String path, LocalDate from) {
        return repository.findByPathAndDayGreaterThanEqual(path, from);
    }
}
