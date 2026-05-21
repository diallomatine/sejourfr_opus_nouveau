package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.AnswerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Answer}.
 */
@Component
@RequiredArgsConstructor
public class AnswerManager {

    private final AnswerRepository repository;

    public Answer save(Answer answer) {
        return repository.save(answer);
    }

    // ------------------------------------------------------------------------
    // Stats / erreurs (consommees par MeService)
    // ------------------------------------------------------------------------

    public long countAnsweredByUserAndModule(UUID userId, Module module) {
        return repository.countAnsweredByUserAndModule(userId, module);
    }

    public long countCorrectByUserAndModule(UUID userId, Module module) {
        return repository.countCorrectByUserAndModule(userId, module);
    }

    /** Lignes brutes [themeId, themeName, totalDistinct, correctDistinct]. */
    public List<Object[]> aggregateByTheme(UUID userId, Module module) {
        return repository.aggregateByTheme(userId, module);
    }

    /** IDs des questions auxquelles l'utilisateur a deja repondu incorrectement. */
    public List<UUID> findWrongQuestionIds(UUID userId, Module module) {
        return repository.findWrongQuestionIds(userId, module);
    }

    public boolean hasUserAnsweredQuestion(UUID userId, UUID questionId) {
        return repository.hasUserAnsweredQuestion(userId, questionId);
    }

    /**
     * Choix sélectionnés par l'utilisateur lors de sa <b>dernière</b> tentative
     * sur cette question. Liste vide si jamais tentée. Sert au sheet review
     * pour marquer en rouge le choix incorrect choisi.
     */
    public List<UUID> findLatestSelectedChoiceIds(UUID userId, UUID questionId) {
        List<Answer> last = repository.findLatestByUserAndQuestion(
                userId, questionId, PageRequest.of(0, 1));
        if (last.isEmpty()) return List.of();
        return last.get(0).getSelectedChoiceIds();
    }
}
