package com.sejourfr.app.repository;

import com.sejourfr.app.entity.LearningPlanObservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
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
