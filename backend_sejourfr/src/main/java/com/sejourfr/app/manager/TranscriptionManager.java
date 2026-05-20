package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.repository.TranscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Transcription}.
 */
@Component
@RequiredArgsConstructor
public class TranscriptionManager {

    private final TranscriptionRepository repository;

    /** En MVP, une seule transcription par submission ; on prend la plus recente. */
    public Optional<Transcription> findLatestBySubmissionId(UUID submissionId) {
        return repository.findFirstBySubmissionIdOrderByCreatedAtDesc(submissionId);
    }

    public Transcription save(Transcription transcription) {
        return repository.save(transcription);
    }
}
