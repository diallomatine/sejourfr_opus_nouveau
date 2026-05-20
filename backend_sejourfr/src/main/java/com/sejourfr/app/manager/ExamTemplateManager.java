package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ExamTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link ExamTemplate}.
 */
@Component
@RequiredArgsConstructor
public class ExamTemplateManager {

    private final ExamTemplateRepository repository;

    public Optional<ExamTemplate> findById(UUID id) {
        return repository.findById(id);
    }

    public Optional<ExamTemplate> findBySlug(String slug) {
        return repository.findBySlug(slug);
    }

    /** Templates publies par module, tries par position asc. */
    public List<ExamTemplate> findPublishedByModule(Module module) {
        return repository.findByModuleAndPublishedTrueOrderByPositionAsc(module);
    }

    /** Tous les templates publies (tri module puis position). */
    public List<ExamTemplate> findAllPublished() {
        return repository.findByPublishedTrueOrderByModuleAscPositionAsc();
    }

    /**
     * Tous les templates (admin), tries par module puis position. Filtre
     * optionnel par module en memoire (la table reste petite, pas besoin
     * d'index dedie).
     */
    public List<ExamTemplate> findAllOrdered(Module module) {
        return repository.findAll().stream()
                .filter(t -> module == null || t.getModule() == module)
                .sorted(Comparator
                        .comparing(ExamTemplate::getModule)
                        .thenComparingInt(ExamTemplate::getPosition))
                .toList();
    }

    public ExamTemplate save(ExamTemplate template) {
        return repository.save(template);
    }

    public void delete(ExamTemplate template) {
        repository.delete(template);
    }
}
