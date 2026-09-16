package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiEvaluationRepository extends JpaRepository<AiEvaluation, UUID> {

    /** Derniere evaluation d'une submission (cf. index idx_ai_eval_submission_latest). */
    Optional<AiEvaluation> findFirstBySubmissionIdOrderByEvaluatedAtDesc(UUID submissionId);

    /**
     * Les evaluations de PLUSIEURS submissions en <b>une</b> requete, de la plus
     * ancienne a la plus recente : l'appelant garde la derniere de chaque
     * submission.
     *
     * <p>🛑 Existe pour le <b>cout</b> du profil TCF, qui evalue toutes les
     * epreuves completes d'un candidat a chaque lecture d'Accueil ou de Plan.
     * Une requete par soumission y faisait un N+1 qui grandissait avec
     * l'historique.
     *
     * <p>⚠️ {@code evaluatedAt ASC NULLS FIRST} : une date absente ne doit
     * jamais l'emporter sur une date connue — c'est la meme regle que
     * {@code findFirstBySubmissionIdOrderByEvaluatedAtDesc}, vue de l'autre
     * bout.
     */
    @Query("""
            SELECT e FROM AiEvaluation e
            WHERE e.submission.id IN :submissionIds
            ORDER BY e.evaluatedAt ASC NULLS FIRST
            """)
    List<AiEvaluation> findBySubmissionIds(@Param("submissionIds") Collection<UUID> submissionIds);

    /**
     * Toutes les évaluations IA du user pour une épreuve donnée (EE ou EO),
     * avec un niveau CECRL non null. Sert à calculer le niveau plafond
     * dans le résumé de progression TCF.
     */
    @Query("""
            SELECT e FROM AiEvaluation e
            WHERE e.submission.user.id = :userId
              AND e.submission.productionTask.epreuve = :epreuve
              AND e.niveauCecrl IS NOT NULL
            """)
    List<AiEvaluation> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve);

    /** Nombre d'evaluations ayant a la fois le niveau LLM et le niveau calcule (calibration). */
    @Query("""
            SELECT COUNT(e) FROM AiEvaluation e
            WHERE e.niveauCecrlIa IS NOT NULL AND e.niveauCecrl IS NOT NULL
            """)
    long countWithBothNiveaux();

    /** Nombre d'evaluations ou le niveau LLM diverge du niveau calcule (≥ 1 cran). */
    @Query("""
            SELECT COUNT(e) FROM AiEvaluation e
            WHERE e.niveauCecrlIa IS NOT NULL AND e.niveauCecrl IS NOT NULL
              AND e.niveauCecrlIa <> e.niveauCecrl
            """)
    long countNiveauDivergent();
}
