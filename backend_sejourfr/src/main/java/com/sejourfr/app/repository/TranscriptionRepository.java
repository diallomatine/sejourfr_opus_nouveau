package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Transcription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TranscriptionRepository extends JpaRepository<Transcription, UUID> {

    /** En MVP, une seule transcription par submission : on prend la plus recente si re-transcription. */
    Optional<Transcription> findFirstBySubmissionIdOrderByCreatedAtDesc(UUID submissionId);
}
