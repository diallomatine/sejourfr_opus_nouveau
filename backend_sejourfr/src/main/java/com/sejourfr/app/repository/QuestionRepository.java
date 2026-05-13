package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QuestionRepository
        extends JpaRepository<Question, UUID>, JpaSpecificationExecutor<Question> {

    // ------------------------------------------------------------------------
    // Sélection aléatoire pour le runner
    // ------------------------------------------------------------------------

    /**
     * Tire des questions actives au hasard pour un module, avec filtres
     * optionnels (themeId / difficulty / questionType : null = pas de filtre).
     * <p>
     * On utilise JPQL (et non du natif + SpEL) pour deux raisons :
     *   - Hibernate convertit proprement les enums @Enumerated(STRING) et les
     *     UUID null, là où PostgreSQL en natif réclame des CAST explicites.
     *   - Pas de SpEL : la lisibilité est meilleure et il n'y a plus de
     *     parameter binding qui dépend d'une expression dynamique.
     * <p>
     * La limite est portée par le {@link Pageable} (passer
     * {@code PageRequest.of(0, size)} depuis le service).
     */
    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL OR q.questionType = :questionType)
            ORDER BY function('random')
            """)
    List<Question> findRandom(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType,
            Pageable pageable
    );

    // ------------------------------------------------------------------------
    // Stats / agrégations
    // ------------------------------------------------------------------------

    long countByModule(Module module);

    long countByModuleAndActive(Module module, boolean active);

    long countByThemeId(UUID themeId);

    long countByThemeIdAndActiveTrue(UUID themeId);
}
