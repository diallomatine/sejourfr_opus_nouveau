package com.sejourfr.app.progression.repository;

import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

/**
 * Lecture de la vue {@code question_empirical_difficulty} (V045).
 *
 * <p>Rattachée à une entité déjà mappée faute de mieux : la vue n'a pas
 * d'entité propre, et lui en donner une la ferait ressembler à une table qu'on
 * pourrait écrire. Elle est en lecture seule, par construction.
 */
public interface QuestionEmpiricalDifficultyRepository
        extends JpaRepository<LearningEvidenceRecord, UUID> {

    @Query(value = """
            SELECT question_id, reponses, taux_reussite, difficulty_band_declaree
            FROM question_empirical_difficulty
            WHERE module = :module
              AND (:questionType IS NULL OR question_type = :questionType)
              AND (:difficulty IS NULL OR difficulty = :difficulty)
            ORDER BY reponses DESC
            """, nativeQuery = true)
    List<Object[]> lireDifficulteEmpirique(@Param("module") String module,
                                           @Param("questionType") String questionType,
                                           @Param("difficulty") String difficulty);

    /**
     * L'inventaire du catalogue par (domaine, palier, bande) — l'indicateur
     * d'avancement du tagging.
     *
     * <p>Les questions <b>non taguées</b> sortent avec {@code difficulty_band}
     * à {@code NULL} : c'est le chiffre qui compte au début, celui du travail
     * restant.
     */
    @Query(value = """
            SELECT q.question_type, q.difficulty, q.difficulty_band, COUNT(*)
            FROM questions q
            WHERE q.is_active = true
              AND q.module = 'TCF'
              AND q.question_type IN ('CO', 'CO_IMAGE', 'CE')
              AND q.difficulty IN ('A2', 'B1', 'B2')
            GROUP BY q.question_type, q.difficulty, q.difficulty_band
            """, nativeQuery = true)
    List<Object[]> inventaireParBande();
}
