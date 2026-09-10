package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.repository.AttemptQuestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link AttemptQuestion}.
 */
@Component
@RequiredArgsConstructor
public class AttemptQuestionManager {

    private final AttemptQuestionRepository repository;

    public AttemptQuestion save(AttemptQuestion aq) {
        return repository.save(aq);
    }

    public Optional<AttemptQuestion> findById(UUID id) {
        return repository.findById(id);
    }
    /**
     * Items poses et reussis d'un attempt, ventiles par palier
     * ({@code [Difficulty, posés, réussis]}). Sert au calcul de niveau du
     * diagnostic TCF, qui lit un taux PAR PALIER et jamais sur le total.
     */
    public java.util.List<Object[]> aggregateByDifficulty(UUID attemptId) {
        return repository.aggregateByDifficulty(attemptId);
    }

    /** {@code [themeId, QuestionType, poses, reussis]} — diagnostic civique (L9). */
    public java.util.List<Object[]> aggregateByThemeAndType(UUID attemptId) {
        return repository.aggregateByThemeAndType(attemptId);
    }


    public List<AttemptQuestion> findByAttemptOrderedByPosition(UUID attemptId) {
        return repository.findByAttemptIdOrderByPositionAsc(attemptId);
    }
}
