package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionExample;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ProductionExampleRepository extends JpaRepository<ProductionExample, UUID> {

    /** Modèles d'une tâche (indépendants du sujet choisi). */
    List<ProductionExample> findByTaskIdOrderByDisplayOrderAsc(UUID taskId);
}
