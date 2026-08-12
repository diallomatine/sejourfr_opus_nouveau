package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.entity.DiagnosticTaskSkillId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DiagnosticTaskSkillRepository
        extends JpaRepository<DiagnosticTaskSkill, DiagnosticTaskSkillId> {

    @Query("""
            SELECT d FROM DiagnosticTaskSkill d
            JOIN FETCH d.skill
            WHERE d.productionTask.id = :taskId
              AND d.skill.active = true
            ORDER BY d.displayOrder ASC
            """)
    List<DiagnosticTaskSkill> findActiveByTaskId(@Param("taskId") UUID taskId);
}
