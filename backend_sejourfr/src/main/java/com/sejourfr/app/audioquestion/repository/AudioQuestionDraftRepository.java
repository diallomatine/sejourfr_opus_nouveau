package com.sejourfr.app.audioquestion.repository;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AudioQuestionDraftRepository extends JpaRepository<AudioQuestionDraft, UUID> {

    List<AudioQuestionDraft> findTop10ByStatusOrderByCreatedAtAsc(AudioDraftStatus status);

    Page<AudioQuestionDraft> findByStatus(AudioDraftStatus status, Pageable pageable);

    long countByStatus(AudioDraftStatus status);
}
