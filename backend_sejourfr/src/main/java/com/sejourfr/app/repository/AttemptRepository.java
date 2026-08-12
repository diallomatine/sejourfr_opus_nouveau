package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * IMPORTANT : recopier uniquement les méthodes manquantes si tu as déjà
 * un AttemptRepository.
 */
@Repository
public interface AttemptRepository extends JpaRepository<Attempt, UUID> {

    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            """)
    long countStandardByUserId(@Param("userId") UUID userId);

    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId AND a.module = :module
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            """)
    long countStandardByUserIdAndModule(
            @Param("userId") UUID userId, @Param("module") Module module);

    long countByExamTemplateId(UUID examTemplateId);

    List<Attempt> findByUserIdOrderByStartedAtDesc(UUID userId);

    /**
     * Purge de tous les attempts d'un user (suppression de compte). Le DELETE
     * SQL déclenche les FK cascade base : {@code attempt_questions} → {@code
     * answers}, {@code production_submissions} → {@code transcriptions} /
     * {@code ai_evaluations}, et les sous-attempts ({@code parent_attempt_id}).
     */
    @Modifying
    @Query("DELETE FROM Attempt a WHERE a.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);


    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND (:type IS NULL OR a.type = :type)
              AND (:module IS NULL OR a.module = :module)
              AND (:moduleExamQuestionType IS NULL OR a.moduleExamQuestionType = :moduleExamQuestionType)
              AND (:themeId IS NULL OR a.lotThemeId = :themeId)
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            ORDER BY a.startedAt DESC
            """)
    List<Attempt> findByUserFiltered(
            @Param("userId") UUID userId,
            @Param("type") AttemptType type,
            @Param("module") Module module,
            @Param("moduleExamQuestionType") QuestionType moduleExamQuestionType,
            @Param("themeId") UUID themeId,
            Pageable pageable
    );

    // Quota guest (countByClientIp...AndStartedAtAfter) supprimé 2026-05-17 :
    // la démo est désormais illimitée. L'index partiel idx_attempts_demo_quota
    // est laissé en base (cf. V092) au cas où on rétablit un quota plus tard.

    /**
     * Lookup sécurisé d'un attempt guest : exige que l'attempt soit bien
     * démo (user IS NULL) ET appartienne à la même IP que le caller.
     */
    Optional<Attempt> findByIdAndClientIpAndUserIsNull(UUID id, String clientIp);

    /**
     * Pour chaque lot d'un (module, questionType, difficulty) que l'utilisateur
     * a déjà terminé, renvoie son <b>dernier attempt fini</b> trié par lot
     * croissant. Sert à enrichir `GET /api/lots` avec le score précédent affiché
     * sur les cards des lots déjà faits.
     *
     * <p>Plusieurs attempts pour un même lot → on prend le plus récent via
     * {@code DISTINCT ON (lot_numero)} simulé en JPQL par un sous-ordre +
     * une déduplication côté service. La query renvoie ici tous les attempts
     * finis triés (date desc, puis numero asc) — `LotService` filtre le premier
     * de chaque lot.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.module = :module
              AND a.lotQuestionType = :questionType
              AND a.lotDifficulty = :difficulty
              AND a.lotNumero IS NOT NULL
              AND a.finishedAt IS NOT NULL
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findFinishedByUserAndLot(
            @Param("userId") UUID userId,
            @Param("module") Module module,
            @Param("questionType") QuestionType questionType,
            @Param("difficulty") Difficulty difficulty
    );

    /**
     * Variante Civique de {@link #findFinishedByUserAndLot} : filtre par
     * {@code lotThemeId} au lieu de difficulty/questionType. Sert à enrichir
     * `GET /api/lots?module=CIVIQUE&themeId=...` avec le dernier score du user
     * sur chaque lot.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.module = com.sejourfr.app.enums.Module.CIVIQUE
              AND a.lotThemeId = :themeId
              AND a.lotNumero IS NOT NULL
              AND a.finishedAt IS NOT NULL
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findFinishedByUserAndLotCivique(
            @Param("userId") UUID userId,
            @Param("themeId") UUID themeId
    );

    /**
     * Liste les sous-attempts d'un examen blanc TCF complet (parent
     * {@code TCF_COMPLET}). Ordonnés par {@code startedAt asc} — l'ordre de
     * création correspond à l'ordre des épreuves (CO, CE, EE, EO).
     */
    List<Attempt> findByParentAttemptIdOrderByStartedAtAsc(UUID parentAttemptId);

    /**
     * Lookup d'un attempt avec son parent eager-loaded (LEFT JOIN FETCH).
     * Utilisé hors transaction longue (ex: {@code ProductionEvaluationService})
     * pour pouvoir lire {@code parentAttempt.epreuve} sans déclencher de
     * {@code LazyInitializationException}.
     */
    @Query("SELECT a FROM Attempt a LEFT JOIN FETCH a.parentAttempt WHERE a.id = :id")
    Optional<Attempt> findByIdWithParent(@Param("id") UUID id);

    /**
     * Historique des examens blancs TCF complets d'un utilisateur (parent
     * uniquement, tri descendant). Utilisé par {@code GET /api/me/full-tcf-exams}.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.epreuve = :epreuve
            ORDER BY a.startedAt DESC
            """)
    List<Attempt> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable
    );

    /**
     * Jours d'activité distincts du user (date locale Europe/Paris du
     * {@code started_at} de chaque attempt), triés du plus récent au plus
     * ancien. Sert au calcul de la série de jours consécutifs (streak) du
     * dashboard — le calcul de la série elle-même vit côté service.
     */
    @Query(value = """
            SELECT DISTINCT CAST(a.started_at AT TIME ZONE 'Europe/Paris' AS date)
            FROM attempts a
            WHERE a.user_id = :userId
            ORDER BY 1 DESC
            """, nativeQuery = true)
    List<LocalDate> findDistinctActivityDates(@Param("userId") UUID userId);

    long countByUserIdAndTypeAndFinishedAtIsNotNull(UUID userId, AttemptType type);

    /**
     * Sessions d'examen blanc production (EE/EO) d'un user — attempts marqués
     * {@code slotNumber} non null à la création, en ne comptant que celles où
     * au moins une tâche a été soumise (un start abandonné sans soumission ne
     * consomme rien : le coût réel est l'évaluation IA). Sert au budget
     * freemium : 1 examen gratuit, le 2ᵉ consomme les essais d'entraînement
     * restants, ensuite 403.
     */
    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId
              AND a.epreuve IN :epreuves
              AND a.slotNumber IS NOT NULL
              AND EXISTS (SELECT 1 FROM ProductionSubmission s WHERE s.attempt = a)
            """)
    long countProductionExamSessions(
            @Param("userId") UUID userId,
            @Param("epreuves") java.util.Collection<EpreuveType> epreuves);

    /**
     * Épreuves QCM TCF (CO ou CE) <b>réellement passées</b> par le user :
     * examen blanc fini portant <b>au moins une réponse enregistrée</b>, du
     * plus récent au plus ancien.
     *
     * <p><b>Définition d'une épreuve « abandonnée sans rien rendre » : zéro
     * réponse.</b> Elle est exclue d'office par le {@code EXISTS} — au niveau
     * d'un candidat, « aucune preuve » n'est pas « mauvaise preuve ». (À ne pas
     * confondre avec le résultat d'UN examen donné, où une épreuve abandonnée
     * sans verrou reste comptée {@code A1_NON_ATTEINT} : c'est le résultat de
     * cet examen-là.)
     *
     * <p>Le filtre porte sur {@code epreuve}, pas sur
     * {@code moduleExamQuestionType} : il couvre ainsi les examens module
     * standalone, les sous-attempts d'un examen blanc complet et les anciens
     * diagnostics où cette colonne est nulle.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.type = com.sejourfr.app.enums.AttemptType.MOCK_EXAM
              AND a.epreuve = :epreuve
              AND a.finishedAt IS NOT NULL
              AND EXISTS (SELECT 1 FROM Answer an WHERE an.attemptQuestion.attempt = a)
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findQcmEpreuvesPassees(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable);
}
