package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ThemeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Theme}.
 */
@Component
@RequiredArgsConstructor
public class ThemeManager {

    private final ThemeRepository repository;

    public Optional<Theme> findById(UUID id) {
        return repository.findById(id);
    }

    /** Tous les themes, tries par displayOrder asc. */
    public List<Theme> findAllOrderedByDisplayOrder() {
        return repository.findAll().stream()
                .sorted(Comparator.comparingInt(Theme::getDisplayOrder))
                .toList();
    }

    public List<Theme> findByModuleOrderedByDisplayOrder(Module module) {
        return repository.findByModuleOrderByDisplayOrderAsc(module);
    }

    public boolean existsByCode(String code) {
        return repository.existsByCode(code);
    }

    public Theme save(Theme theme) {
        return repository.save(theme);
    }

    public void delete(Theme theme) {
        repository.delete(theme);
    }
}
