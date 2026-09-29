package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.AnswerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.Collection;
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

    /**
     * Rattache a {@code user} les reponses sans porteur d'un attempt joue en
     * visiteur (adoption d'un diagnostic civique invite, V053).
     *
     * @return le nombre de lignes rattachees
     */
    public int rattacherAuCompte(User user, UUID attemptId) {
        return repository.rattacherAuCompte(user, attemptId);
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

    public boolean hasUserAnsweredQuestion(UUID userId, UUID questionId) {
        return repository.hasUserAnsweredQuestion(userId, questionId);
    }

    /**
     * Parmi ces sessions QCM, celles qui portent au moins une réponse. « Zéro
     * réponse » = rien n'a été rendu — même définition que
     * {@code AttemptManager.findQcmEpreuvesPassees}. Une requête pour toutes ;
     * aucun accès base sur une liste vide.
     */
    public java.util.Set<UUID> attemptIdsAvecReponse(Collection<UUID> attemptIds) {
        if (attemptIds == null || attemptIds.isEmpty()) return java.util.Set.of();
        return new java.util.HashSet<>(repository.findAttemptIdsWithAnswer(attemptIds));
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
