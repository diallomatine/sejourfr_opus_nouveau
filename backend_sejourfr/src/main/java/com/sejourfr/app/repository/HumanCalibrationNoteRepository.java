package com.sejourfr.app.repository;

import com.sejourfr.app.entity.HumanCalibrationNote;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HumanCalibrationNoteRepository extends JpaRepository<HumanCalibrationNote, UUID> {

    /** Derniere note humaine d'une submission (relecture cote console admin). */
    Optional<HumanCalibrationNote> findFirstBySubmissionIdOrderByCreatedAtDescIdDesc(UUID submissionId);

    /**
     * Ids des submissions portant AU MOINS une note humaine, parmi celles
     * passees en parametre. Une seule requete pour toute la page : evite le
     * N+1 d'un {@code findBySubmission(...)} par submission listee.
     */
    @Query("""
            SELECT DISTINCT h.submission.id FROM HumanCalibrationNote h
            WHERE h.submission.id IN :submissionIds
            """)
    List<UUID> findAnnotatedSubmissionIds(Collection<UUID> submissionIds);

    /**
     * Toutes les notes, la plus recente d'abord (id en second critere pour un
     * ordre total meme a {@code created_at} identique). Le dashboard s'en sert
     * pour ne retenir que la DERNIERE note de chaque submission.
     */
    List<HumanCalibrationNote> findAllByOrderByCreatedAtDescIdDesc();

    List<HumanCalibrationNote> findByEvaluatorIdOrderByCreatedAtDesc(UUID evaluatorId, Pageable pageable);

    /** Ecart moyen entre note humaine et IA (dashboard calibration). */
    @Query("SELECT AVG(h.ecartNote) FROM HumanCalibrationNote h WHERE h.ecartNote IS NOT NULL")
    BigDecimal averageEcart();

    /** Nombre de notes humaines avec un ecart absolu strictement superieur a {@code seuil}. */
    @Query("""
            SELECT COUNT(h) FROM HumanCalibrationNote h
            WHERE h.ecartNote IS NOT NULL
              AND ABS(h.ecartNote) > :seuil
            """)
    long countWithEcartAbove(BigDecimal seuil);

    long count();
}
