package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductionSubmissionRepository extends JpaRepository<ProductionSubmission, UUID> {

    /** Toutes les submissions d'un attempt (utile pour assembler le score d'un examen complet). */
    List<ProductionSubmission> findByAttemptIdOrderBySubmittedAtAsc(UUID attemptId);

    /**
     * Submission + sa {@code productionTask} eager-loadée. Utilisé par le retry :
     * {@link com.sejourfr.app.service.ProductionEvaluationService#retry} n'est pas
     * {@code @Transactional}, donc accéder à la task en lazy hors session lève une
     * {@code LazyInitializationException} (bug relancé après échec d'éval).
     */
    @Query("SELECT s FROM ProductionSubmission s JOIN FETCH s.productionTask "
        + "JOIN FETCH s.attempt WHERE s.id = :id")
    Optional<ProductionSubmission> findByIdWithTask(@Param("id") UUID id);

    /**
     * Submission + sa {@code productionTask} + son {@code user} eager-loadés.
     * Utilisé par la « version au niveau visé », qui a besoin du
     * {@code TargetLevel} du candidat SANS ouvrir de transaction autour d'un
     * appel HTTP au LLM — un accès lazy hors session y lèverait une
     * {@code LazyInitializationException}.
     */
    @Query("SELECT s FROM ProductionSubmission s JOIN FETCH s.productionTask JOIN FETCH s.attempt "
        + "JOIN FETCH s.user "
        + "WHERE s.id = :id")
    Optional<ProductionSubmission> findByIdWithTaskAndUser(@Param("id") UUID id);

    /** Historique standard : le diagnostic possède son écran agrégé dédié. */
    @Query("""
            SELECT s FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.diagnosticCode IS NULL
            ORDER BY s.submittedAt DESC
            """)
    List<ProductionSubmission> findStandardByUser(
            @Param("userId") UUID userId, Pageable pageable);

    /** Quota freemium / anti-abus : compteur cumulatif (a vie) par epreuve. */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
              AND s.productionTask.diagnosticCode IS NULL
            """)
    long countByUserAndEpreuve(@Param("userId") UUID userId, @Param("epreuve") EpreuveType epreuve);

    /**
     * Variante "entrainement seul" : exclut les soumissions faites dans une
     * session d'examen blanc production ({@code attempt.slotNumber} non null)
     * ou dans un examen blanc TCF complet ({@code attempt.parentAttempt} non
     * null). Sert au quota freemium : 1 essai d'entrainement par epreuve.
     */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
              AND s.productionTask.diagnosticCode IS NULL
              AND s.attempt.slotNumber IS NULL
              AND s.attempt.parentAttempt IS NULL
            """)
    long countTrainingByUserAndEpreuve(@Param("userId") UUID userId, @Param("epreuve") EpreuveType epreuve);

    /**
     * Nombre de tâches EE/EO déjà soumises par l'utilisateur DANS un examen
     * blanc TCF complet (sous-attempt rattaché à un parent {@code TCF_COMPLET}).
     * Sert au freebie « EE/EO offerts une fois dans l'examen complet » des
     * comptes gratuits : dès qu'une tâche a réellement été soumise (> 0), les
     * examens complets suivants verrouillent EE/EO. Un examen complet lancé puis
     * abandonné sans rien soumettre ne consomme pas le freebie.
     */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.attempt.parentAttempt.epreuve = :parentEpreuve
            """)
    long countByUserAndParentEpreuve(@Param("userId") UUID userId,
                                     @Param("parentEpreuve") EpreuveType parentEpreuve);

    /**
     * Nombre de soumissions déjà faites sur une tâche précise d'une session.
     * Sert au plafond « un examen = 3 tâches, une fois chacune » : sans lui,
     * une session d'examen accepte autant de productions (donc d'évaluations
     * IA payantes) que le client en envoie.
     */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.attempt.id = :attemptId
              AND s.productionTask.tacheNumero = :tacheNumero
            """)
    long countByAttemptAndTache(@Param("attemptId") UUID attemptId,
                                @Param("tacheNumero") short tacheNumero);

    long countByAttemptId(UUID attemptId);

    /**
     * Pour chaque sujet de production deja rendu par ce candidat, la date de sa
     * <b>derniere</b> soumission. Sert a la verification en situation du Plan
     * ({@code ReassessmentExerciseSelector}) : elle cherche un sujet
     * <b>jamais joue</b>, et a defaut evite de resservir celui qui vient de
     * l'etre.
     *
     * <p>Une seule requete quel que soit le nombre de competences a resoudre —
     * l'historique d'un candidat se compte en dizaines de lignes, pas en
     * milliers. Les sujets de diagnostic sont exclus : ils ne sont jamais
     * rejoues, donc jamais proposes.
     */
    @Query("""
            SELECT s.productionTask.id, MAX(s.submittedAt) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.diagnosticCode IS NULL
            GROUP BY s.productionTask.id
            """)
    List<Object[]> findLastSubmittedAtByTask(@Param("userId") UUID userId);

    /**
     * Nombre de TÂCHES DISTINCTES soumises dans un attempt, restreint à
     * l'épreuve de cet attempt. Sert à l'auto-finalisation d'une sous-épreuve
     * d'examen complet : compter les lignes brutes finalisait la mauvaise
     * épreuve dès que 3 soumissions (mêmes tâches, ou tâches d'une autre
     * épreuve) étaient rattachées à l'attempt.
     */
    @Query("""
            SELECT COUNT(DISTINCT s.productionTask.tacheNumero) FROM ProductionSubmission s
            WHERE s.attempt.id = :attemptId
              AND s.productionTask.epreuve = :epreuve
            """)
    long countDistinctTachesByAttemptAndEpreuve(@Param("attemptId") UUID attemptId,
                                                @Param("epreuve") EpreuveType epreuve);

    /** Historique filtre par epreuve (jointure sur la task). */
    @Query("""
            SELECT s FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
              AND s.productionTask.diagnosticCode IS NULL
            ORDER BY s.submittedAt DESC
            """)
    List<ProductionSubmission> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable
    );

    /** Calibration standard uniquement : le profil diagnostic n'a pas de /20. */
    @Query("""
            SELECT s FROM ProductionSubmission s
            WHERE s.statut = :statut
              AND s.diagnostic = false
              AND s.productionTask.diagnosticCode IS NULL
            ORDER BY s.submittedAt ASC
            """)
    List<ProductionSubmission> findStandardByStatut(
            @Param("statut") SubmissionStatut statut);

    /**
     * Pour le hub d'entrainement : derniere submission par numero de tache
     * (1..3) pour un (user, epreuve, niveau) donne. Renvoie 0 a 3 lignes
     * tries par tacheNumero asc. Utilise DISTINCT ON (Postgres) pour ne garder
     * que la plus recente de chaque groupe.
     */
    @Query(value = """
            SELECT ps.*
            FROM production_submissions ps
            JOIN production_tasks pt ON pt.id = ps.production_task_id
            WHERE ps.id IN (
              SELECT DISTINCT ON (pt2.tache_numero) ps2.id
              FROM production_submissions ps2
              JOIN production_tasks pt2 ON pt2.id = ps2.production_task_id
              WHERE ps2.user_id = :userId
                AND pt2.epreuve = CAST(:epreuve AS varchar)
                AND pt2.niveau_cible = :niveau
                AND pt2.diagnostic_code IS NULL
              ORDER BY pt2.tache_numero, ps2.submitted_at DESC
            )
            ORDER BY pt.tache_numero ASC
            """, nativeQuery = true)
    List<ProductionSubmission> findLatestPerTask(
            @Param("userId") UUID userId,
            @Param("epreuve") String epreuve,
            @Param("niveau") String niveau
    );
}
