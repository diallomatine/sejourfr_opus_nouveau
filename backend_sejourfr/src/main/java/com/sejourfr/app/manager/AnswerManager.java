package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.repository.AnswerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.EnumSet;
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

    /**
     * IDs des questions ratees par l'utilisateur, erreur la plus recente d'abord,
     * plafonne a {@code limit}. Le plafond s'applique APRES les filtres (module /
     * type / theme) : ce sont les N erreurs les plus recentes <em>correspondant a
     * la demande</em>, pas les N plus recentes tous criteres confondus.
     *
     * <p>Un filtre {@code CO} inclut {@code CO_IMAGE} — meme regle que partout
     * ailleurs (tirages, examens) : CO_IMAGE est un format de compréhension
     * orale, pas une epreuve a part.
     *
     * @param questionType null = tous types
     * @param themeId      null = tous themes
     */
    public List<UUID> findRecentWrongQuestionIds(
            UUID userId, Module module, QuestionType questionType, UUID themeId, int limit) {
        return repository.findRecentWrongQuestionIds(
                userId, module, expandQuestionTypes(questionType), themeId, PageRequest.of(0, limit));
    }

    /**
     * Types acceptes par le filtre. Aucun filtre → tous les types (la requete
     * garde un {@code IN} toujours non vide, plus simple et plus sur qu'un
     * {@code IS NULL OR} sur une collection).
     */
    static Collection<QuestionType> expandQuestionTypes(QuestionType requested) {
        if (requested == null) return EnumSet.allOf(QuestionType.class);
        if (requested == QuestionType.CO) return EnumSet.of(QuestionType.CO, QuestionType.CO_IMAGE);
        return EnumSet.of(requested);
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
