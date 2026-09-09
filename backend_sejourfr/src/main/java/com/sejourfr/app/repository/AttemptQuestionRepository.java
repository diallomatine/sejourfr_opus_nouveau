package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AttemptQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AttemptQuestionRepository extends JpaRepository<AttemptQuestion, UUID> {

    List<AttemptQuestion> findByAttemptIdOrderByPositionAsc(UUID attemptId);

    /**
     * Items poses et items reussis d'un attempt, <b>ventiles par palier</b>
     * ({@code questions.difficulty}). Une ligne par palier :
     * {@code [Difficulty, posés, réussis]}.
     *
     * <p>C'est le denominateur reel du calcul de niveau du diagnostic
     * ({@code TcfDiagnosticLevelResolver}) : le taux se lit palier par palier,
     * jamais sur le total — 10 bonnes reponses sur 15 ne disent rien tant qu'on
     * ignore lesquelles.
     *
     * <p>Une question sans reponse compte comme <b>posee et non reussie</b> :
     * dans une section chronometree qu'on termine d'une traite, ne pas repondre
     * est une reponse.
     */
    @Query("""
            SELECT aq.question.difficulty,
                   COUNT(aq),
                   SUM(CASE WHEN aq.correct = true THEN 1 ELSE 0 END)
            FROM AttemptQuestion aq
            WHERE aq.attempt.id = :attemptId
            GROUP BY aq.question.difficulty
            """)
    List<Object[]> aggregateByDifficulty(@Param("attemptId") UUID attemptId);
}
