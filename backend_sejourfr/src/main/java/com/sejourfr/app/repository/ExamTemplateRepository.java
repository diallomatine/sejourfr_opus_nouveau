package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ExamTemplateRepository extends JpaRepository<ExamTemplate, UUID> {

    Optional<ExamTemplate> findBySlug(String slug);

    List<ExamTemplate> findByModuleAndPublishedTrueOrderByPositionAsc(Module module);

    List<ExamTemplate> findByPublishedTrueOrderByModuleAscPositionAsc();
}
