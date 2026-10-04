package com.sejourfr.app.audioquestion.repository;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.enums.Difficulty;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface AudioQuestionDraftRepository extends JpaRepository<AudioQuestionDraft, UUID> {

    List<AudioQuestionDraft> findTop10ByStatusOrderByCreatedAtAsc(AudioDraftStatus status);

    List<AudioQuestionDraft> findTop10ByStatusAndDifficultyOrderByCreatedAtAsc(
            AudioDraftStatus status, Difficulty difficulty);

    Page<AudioQuestionDraft> findByStatus(AudioDraftStatus status, Pageable pageable);

    Page<AudioQuestionDraft> findByStatusAndDifficulty(
            AudioDraftStatus status, Difficulty difficulty, Pageable pageable);

    long countByStatus(AudioDraftStatus status);

    long countByStatusAndDifficulty(AudioDraftStatus status, Difficulty difficulty);

    /** Les identifiants externes deja connus parmi {@code externalIds}, tous statuts confondus. */
    @Query("SELECT d.externalId FROM AudioQuestionDraft d WHERE d.externalId IN :externalIds")
    List<String> findExistingExternalIds(@Param("externalIds") Collection<String> externalIds);
}
