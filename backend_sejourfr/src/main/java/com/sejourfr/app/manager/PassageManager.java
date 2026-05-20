package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.repository.PassageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Passage}.
 */
@Component
@RequiredArgsConstructor
public class PassageManager {

    private final PassageRepository repository;

    public Optional<Passage> findById(UUID id) {
        return repository.findById(id);
    }

    public List<Passage> findAll() {
        return repository.findAll();
    }

    public List<Passage> findByThemeOrdered(UUID themeId) {
        return repository.findByThemeIdOrderByIdAsc(themeId);
    }

    public Passage save(Passage passage) {
        return repository.save(passage);
    }

    public void delete(Passage passage) {
        repository.delete(passage);
    }
}
