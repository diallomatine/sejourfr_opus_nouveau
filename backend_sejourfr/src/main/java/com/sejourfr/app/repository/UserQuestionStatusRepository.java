package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserQuestionStatusRepository extends JpaRepository<UserQuestionStatus, UUID> {

    Optional<UserQuestionStatus> findByUserIdAndQuestionId(UUID userId, UUID questionId);

    /**
     * IDs des questions marquées en favori par l'utilisateur.
     * Si {@code module} est null, retourne les favoris de tous les modules
     * (utilise par la sidebar web pour un badge global).
     */
    @Query("""
        SELECT s.question.id FROM UserQuestionStatus s
        WHERE s.user.id = :userId
          AND s.favorite = true
          AND (:module IS NULL OR s.question.module = :module)
        """)
    List<UUID> findFavoriteQuestionIds(@Param("userId") UUID userId, @Param("module") Module module);
}
