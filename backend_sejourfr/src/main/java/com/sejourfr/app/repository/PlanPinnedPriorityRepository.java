package com.sejourfr.app.repository;

import com.sejourfr.app.entity.PlanPinnedPriority;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PlanPinnedPriorityRepository extends JpaRepository<PlanPinnedPriority, UUID> {

    /**
     * La competence epinglee, <b>avec elle</b> : le Plan compare son
     * identifiant, mais {@code SkillAccessService} et les cartes en lisent le
     * code et la section. Sans le {@code JOIN FETCH}, chaque lecture du Plan
     * paierait un aller-retour de plus sur une entite paresseuse.
     */
    @Query("""
            SELECT p FROM PlanPinnedPriority p
            JOIN FETCH p.skill
            WHERE p.userId = :userId
            """)
    Optional<PlanPinnedPriority> findByUserIdWithSkill(@Param("userId") UUID userId);

    @Modifying
    @Query("DELETE FROM PlanPinnedPriority p WHERE p.userId = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
