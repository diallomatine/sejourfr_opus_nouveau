package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsAnnotation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface AnalyticsAnnotationRepository extends JpaRepository<AnalyticsAnnotation, UUID> {

    /** Les reperes d'une fenetre, bornes incluses, du plus ancien au plus recent. */
    List<AnalyticsAnnotation> findByOccurredOnBetweenOrderByOccurredOnAsc(LocalDate from, LocalDate to);
}
