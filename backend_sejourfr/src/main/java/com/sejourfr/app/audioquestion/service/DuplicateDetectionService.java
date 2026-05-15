package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AudioGenerationProperties;
import com.sejourfr.app.audioquestion.exception.DuplicateContentException;
import com.sejourfr.app.repository.MediaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Detecte les doublons de transcript via pg_trgm sur les questions TCF/CO
 * deja en base (DRAFT ou ACTIVE). Seuil de similarite configurable.
 */
@Service
public class DuplicateDetectionService {

    private static final Logger log = LoggerFactory.getLogger(DuplicateDetectionService.class);

    private final MediaRepository mediaRepository;
    private final AudioGenerationProperties props;

    public DuplicateDetectionService(MediaRepository mediaRepository, AudioGenerationProperties props) {
        this.mediaRepository = mediaRepository;
        this.props = props;
    }

    public void checkNotDuplicate(String transcript, String difficulty) {
        double threshold = props.getDuplicateSimilarityThreshold().doubleValue();
        Optional<String> existing = mediaRepository.findSimilarTranscript(difficulty, transcript, threshold);
        if (existing.isPresent()) {
            String preview = existing.get();
            log.info(
                "Doublon detecte pour niveau {} (seuil={}). Existant : {}...",
                difficulty, threshold,
                preview.length() > 80 ? preview.substring(0, 80) : preview
            );
            throw new DuplicateContentException(
                "Un audio tres similaire existe deja au niveau " + difficulty + ". Cliquez sur Regenerer."
            );
        }
    }
}
