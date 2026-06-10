package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.enums.Module;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AnswerRepository extends JpaRepository<Answer, UUID> {

    // ------------------------------------------------------------------------
    // Stats globales utilisateur
    // ------------------------------------------------------------------------

    // Questions DISTINCTES répondues (et non lignes de réponses brutes) : refaire
    // 2× la même question ne doit pas gonfler le compteur. Cohérent avec
    // aggregateByTheme — la somme des `answered`/`correct` par thème égale ces
    // totaux globaux.
    @Query("""
        SELECT COUNT(DISTINCT a.attemptQuestion.question.id) FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND a.attemptQuestion.attempt.module = :module
        """)
    long countAnsweredByUserAndModule(@Param("userId") UUID userId, @Param("module") Module module);

    // Question comptée "correcte" si réussie au moins une fois dans le module
    // (même sémantique distincte que aggregateByTheme).
    @Query("""
        SELECT COUNT(DISTINCT a.attemptQuestion.question.id) FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND a.attemptQuestion.attempt.module = :module
          AND a.correct = true
        """)
    long countCorrectByUserAndModule(@Param("userId") UUID userId, @Param("module") Module module);

    // ------------------------------------------------------------------------
    // Stats par thème
    // ------------------------------------------------------------------------

    // On compte les questions DISTINCTES (et non les réponses brutes), pour que
    // refaire 2× la même question ne gonfle pas artificiellement les compteurs
    // et que le score de maîtrise (correct/total) reste plafonné par le pool du
    // thème. Une question est considérée "correcte" si l'utilisateur l'a réussie
    // au moins une fois dans le module.
    @Query("""
        SELECT a.attemptQuestion.question.theme.id,
               a.attemptQuestion.question.theme.code,
               a.attemptQuestion.question.theme.name,
               COUNT(DISTINCT a.attemptQuestion.question.id),
               COUNT(DISTINCT CASE WHEN a.correct = true THEN a.attemptQuestion.question.id END)
        FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND a.attemptQuestion.attempt.module = :module
        GROUP BY a.attemptQuestion.question.theme.id,
                 a.attemptQuestion.question.theme.code,
                 a.attemptQuestion.question.theme.name
        """)
    List<Object[]> aggregateByTheme(@Param("userId") UUID userId, @Param("module") Module module);

    // ------------------------------------------------------------------------
    // Erreurs récentes
    // ------------------------------------------------------------------------

    /**
     * IDs des questions auxquelles l'utilisateur a deja repondu incorrectement,
     * triees par erreur la plus recente d'abord (MAX answeredAt). Le {@link Pageable}
     * plafonne le nombre renvoye — la revision n'expose que les N erreurs les plus
     * recentes par module (cf. {@code MeService.MAX_WRONG_PER_MODULE}). Au-dela, les
     * plus anciennes sortent naturellement de la liste : aucune ligne {@code answers}
     * n'est supprimee, donc les stats de progression restent intactes.
     * Si {@code module} est null, agrege tous les modules.
     */
    @Query("""
        SELECT a.attemptQuestion.question.id FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND (:module IS NULL OR a.attemptQuestion.attempt.module = :module)
          AND a.correct = false
        GROUP BY a.attemptQuestion.question.id
        ORDER BY MAX(a.answeredAt) DESC
        """)
    List<UUID> findRecentWrongQuestionIds(@Param("userId") UUID userId,
                                          @Param("module") Module module,
                                          Pageable pageable);

    @Query("""
        SELECT COUNT(a) > 0 FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND a.attemptQuestion.question.id = :questionId
        """)
    boolean hasUserAnsweredQuestion(@Param("userId") UUID userId, @Param("questionId") UUID questionId);

    /**
     * Dernière réponse de l'utilisateur sur une question, triée par
     * {@code answeredAt DESC}. Le caller prend {@code List.first()} (vide
     * si jamais répondu). Sert au sheet de révision pour afficher en rouge
     * le choix incorrect que l'utilisateur avait sélectionné.
     */
    @Query("""
        SELECT a FROM Answer a
        WHERE a.attemptQuestion.attempt.user.id = :userId
          AND a.attemptQuestion.question.id = :questionId
        ORDER BY a.answeredAt DESC
        """)
    List<Answer> findLatestByUserAndQuestion(
            @Param("userId") UUID userId,
            @Param("questionId") UUID questionId,
            org.springframework.data.domain.Pageable pageable
    );
}
