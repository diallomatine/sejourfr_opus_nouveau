package com.sejourfr.app.manager;

import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Acces aux brouillons audio ({@code audio_question_draft}) depuis HORS du
 * sous-module {@code audioquestion/}. L'import CO image ecrit ses brouillons ici,
 * sans etendre l'exception d'architecture du sous-module (dont les services
 * gardent leur acces direct au repository).
 */
@Component
@RequiredArgsConstructor
public class AudioQuestionDraftManager {

    private final AudioQuestionDraftRepository repository;

    /** Parmi {@code externalIds}, ceux qu'un brouillon porte deja (tous statuts). */
    public Set<String> findExistingExternalIds(Collection<String> externalIds) {
        if (externalIds == null || externalIds.isEmpty()) return Set.of();
        return new HashSet<>(repository.findExistingExternalIds(externalIds));
    }

    /**
     * Rend un lot de brouillons NEUFS persistants, sans flush : leur id (tire par
     * Hibernate) est connu tout de suite, l'INSERT part au {@link #flush()}.
     * A appeler dans la transaction de l'appelant.
     */
    public List<AudioQuestionDraft> persistAll(List<AudioQuestionDraft> drafts) {
        return repository.saveAll(drafts);
    }

    /**
     * Ecrit en base ce qui est en attente dans la transaction courante. Une
     * violation de {@code uq_audio_draft_external_id} (import concurrent) leve
     * ici, et la transaction n'ecrit alors aucune ligne du lot.
     */
    public void flush() {
        repository.flush();
    }
}
