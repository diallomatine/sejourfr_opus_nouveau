package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Media;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MediaRepository extends JpaRepository<Media, UUID> {

    /**
     * Anti-doublons pipeline audio : cherche un transcript existant
     * dont la similarite pg_trgm avec :transcript depasse :threshold,
     * parmi les medias attaches a une question TCF/CO active du meme niveau.
     */
    @Query(value = """
        SELECT m.transcript
        FROM medias m
        JOIN questions q ON q.media_id = m.id
        WHERE m.type = 'AUDIO'
          AND m.transcript IS NOT NULL
          AND q.module = 'TCF'
          AND q.question_type = 'CO'
          AND q.difficulty = :difficulty
          AND q.status IN ('DRAFT', 'ACTIVE')
          AND similarity(m.transcript, :transcript) > :threshold
        ORDER BY similarity(m.transcript, :transcript) DESC
        LIMIT 1
        """, nativeQuery = true)
    Optional<String> findSimilarTranscript(
        @Param("difficulty") String difficulty,
        @Param("transcript") String transcript,
        @Param("threshold") double threshold
    );
}
