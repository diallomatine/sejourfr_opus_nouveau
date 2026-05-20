package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.UserQuestionStatusRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link UserQuestionStatus} (favoris / etat
 * par-question d'un utilisateur).
 */
@Component
@RequiredArgsConstructor
public class UserQuestionStatusManager {

    private final UserQuestionStatusRepository repository;

    public Optional<UserQuestionStatus> findByUserIdAndQuestionId(UUID userId, UUID questionId) {
        return repository.findByUserIdAndQuestionId(userId, questionId);
    }

    /**
     * IDs des questions marquees en favori. {@code module == null} agrege tous
     * les modules (badge global sidebar web).
     */
    public List<UUID> findFavoriteQuestionIds(UUID userId, Module module) {
        return repository.findFavoriteQuestionIds(userId, module);
    }

    public UserQuestionStatus save(UserQuestionStatus status) {
        return repository.save(status);
    }
}
