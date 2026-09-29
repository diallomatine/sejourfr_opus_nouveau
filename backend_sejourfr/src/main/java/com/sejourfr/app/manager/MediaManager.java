package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Media;
import com.sejourfr.app.repository.MediaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Media}.
 * Minimaliste : n'expose que ce qui est consomme par les services migres.
 * Les services audioquestion/ continuent d'appeler le repo en direct pour
 * l'instant (sous-module historique, refacto reportee).
 */
@Component
@RequiredArgsConstructor
public class MediaManager {

    private final MediaRepository repository;

    public Optional<Media> findById(UUID id) {
        return repository.findById(id);
    }

    public Media save(Media media) {
        return repository.save(media);
    }

    public void delete(Media media) {
        repository.delete(media);
    }
}
