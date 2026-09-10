package com.sejourfr.app.manager;

import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.repository.CivicNotionRepository;
import com.sejourfr.app.repository.QuestionNotionSuggestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seule couche autorisee a toucher les depots de notions civiques (L8). */
@Component
@RequiredArgsConstructor
public class CivicNotionManager {

    private final CivicNotionRepository repository;
    private final QuestionNotionSuggestionRepository suggestionRepository;

    public List<CivicNotion> findAllOrdonnees() {
        return repository.findAllOrdonnees();
    }

    public Optional<CivicNotion> findByCode(String code) {
        return repository.findByCode(code);
    }

    public Optional<CivicNotion> findById(UUID id) {
        return repository.findById(id);
    }

    public List<Object[]> couvertureParNotionEtMention() {
        return repository.couvertureParNotionEtMention();
    }

    public List<Object[]> suggestionsParNotion() {
        return repository.suggestionsParNotion();
    }

    public List<Object[]> suggestionsParQuestions(Collection<UUID> questionIds) {
        return questionIds.isEmpty() ? List.of() : suggestionRepository.parQuestions(questionIds);
    }

    public List<Object[]> fileDeTagging(String theme, Boolean tagged, int limit, int offset) {
        return repository.fileDeTagging(theme, tagged, limit, offset);
    }

    public long resteATaguer() {
        return repository.resteATaguer();
    }

    /** {@code notion} nul efface le tag : se tromper doit rester rattrapable. */
    public int poserNotion(UUID questionId, CivicNotion notion) {
        return repository.poserNotion(questionId, notion);
    }
}
