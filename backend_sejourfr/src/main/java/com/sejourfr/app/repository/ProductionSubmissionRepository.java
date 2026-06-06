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
import java.util.UUID;

@Repository
public interface ProductionSubmissionRepository extends JpaRepository<ProductionSubmission, UUID> {

    /** Toutes les submissions d'un attempt (utile pour assembler le score d'un examen complet). */
    List<ProductionSubmission> findByAttemptIdOrderBySubmittedAtAsc(UUID attemptId);

    /** Historique d'un utilisateur (timeline descendante). */
    List<ProductionSubmission> findByUserIdOrderBySubmittedAtDesc(UUID userId, Pageable pageable);

    /** Quota freemium / anti-abus : compteur cumulatif (a vie) par epreuve. */
    @Query("""
            SELECT COUNT(s) FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
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
              AND s.attempt.slotNumber IS NULL
              AND s.attempt.parentAttempt IS NULL
            """)
    long countTrainingByUserAndEpreuve(@Param("userId") UUID userId, @Param("epreuve") EpreuveType epreuve);

    /** Historique filtre par epreuve (jointure sur la task). */
    @Query("""
            SELECT s FROM ProductionSubmission s
            WHERE s.user.id = :userId
              AND s.productionTask.epreuve = :epreuve
            ORDER BY s.submittedAt DESC
            """)
    List<ProductionSubmission> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable
    );

    /** Submissions non-finalisees (pour reprise / monitoring). */
    List<ProductionSubmission> findByStatutOrderBySubmittedAtAsc(SubmissionStatut statut);

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
