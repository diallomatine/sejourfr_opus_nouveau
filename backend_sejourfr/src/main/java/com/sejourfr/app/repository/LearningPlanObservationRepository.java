package com.sejourfr.app.repository;

import com.sejourfr.app.entity.LearningPlanObservation;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearningPlanObservationRepository extends JpaRepository<LearningPlanObservation, UUID> {

    @Query("""
            SELECT o FROM LearningPlanObservation o
            JOIN FETCH o.skill
            WHERE o.user.id = :userId
            ORDER BY o.observedAt DESC
            """)
    List<LearningPlanObservation> findAllByUserWithSkill(@Param("userId") UUID userId);

    Optional<LearningPlanObservation> findByUserIdAndSkillIdAndSourceTypeAndSourceId(
            UUID userId, UUID skillId,
            com.sejourfr.app.enums.LearningPlanSourceType sourceType, UUID sourceId);

    /**
     * L'historique borne dans le temps de PLUSIEURS competences, en une seule
     * requete.
     *
     * <p>Un ecran de competences en demande 24 d'un coup, le Plan une dizaine :
     * une requete par competence y serait un N+1 pur. Le couple
     * {@code (user_id, skill_id, observed_at DESC)} est exactement l'index
     * {@code idx_learning_plan_user_skill_recent}, jusqu'ici pose et jamais
     * emprunte.
     */
    @Query("""
            SELECT o FROM LearningPlanObservation o
            JOIN FETCH o.skill
            WHERE o.user.id = :userId
              AND o.skill.id IN :skillIds
              AND o.observedAt >= :after
            ORDER BY o.observedAt DESC
            """)
    List<LearningPlanObservation> findByUserAndSkillsSince(
            @Param("userId") UUID userId,
            @Param("skillIds") Collection<UUID> skillIds,
            @Param("after") Instant after);

    /**
     * La trajectoire d'UNE competence : ses observations probantes, la plus
     * recente d'abord, bornees en nombre.
     *
     * <p>Les {@code NOT_OBSERVED} en sont exclus — c'est une frise de
     * progression, et « je n'ai pas pu observer » n'est pas une etape du
     * parcours du candidat.
     */
    @Query("""
            SELECT o FROM LearningPlanObservation o
            WHERE o.user.id = :userId
              AND o.skill.id = :skillId
              AND o.observed = true
            ORDER BY o.observedAt DESC
            """)
    List<LearningPlanObservation> findTrajectory(
            @Param("userId") UUID userId,
            @Param("skillId") UUID skillId,
            Pageable pageable);

    @Query("""
            SELECT COUNT(DISTINCT o.sourceId) FROM LearningPlanObservation o
            WHERE o.user.id = :userId AND o.observedAt >= :after AND o.baseline = false
            """)
    long countDistinctActivitiesSince(
            @Param("userId") UUID userId, @Param("after") Instant after);

    @Modifying
    @Query("DELETE FROM LearningPlanObservation o WHERE o.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
