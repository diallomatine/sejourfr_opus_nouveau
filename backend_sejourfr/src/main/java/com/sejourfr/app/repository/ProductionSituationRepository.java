package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionSituation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductionSituationRepository extends JpaRepository<ProductionSituation, UUID> {

    List<ProductionSituation> findByTaskIdAndActiveTrueOrderByDisplayOrderAsc(UUID taskId);

    Optional<ProductionSituation> findByIdAndActiveTrue(UUID id);

    /** Inclut les inactives : reserve a l'admin. */
    List<ProductionSituation> findByTaskIdOrderByDisplayOrderAsc(UUID taskId);
}
