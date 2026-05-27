package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ExampleAudioStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProductionExampleRepository extends JpaRepository<ProductionExample, UUID> {

    /** Modèles d'une tâche (indépendants du sujet choisi). */
    List<ProductionExample> findByTaskIdOrderByDisplayOrderAsc(UUID taskId);

    /**
     * Exemples d'une épreuve donnée (TCF_EO pour l'audio) sans audio encore
     * généré et dans un statut relançable, les plus anciens d'abord.
     */
    @Query("""
            SELECT e FROM ProductionExample e
            WHERE e.taskId IN (SELECT t.id FROM ProductionTask t WHERE t.epreuve = :epreuve)
              AND e.audioUrl IS NULL
              AND e.audioStatus IN :statuses
            ORDER BY e.createdAt ASC
            """)
    List<ProductionExample> findNeedingAudio(
            @Param("epreuve") EpreuveType epreuve,
            @Param("statuses") Collection<ExampleAudioStatus> statuses,
            Pageable pageable);

    @Query("""
            SELECT COUNT(e) FROM ProductionExample e
            WHERE e.taskId IN (SELECT t.id FROM ProductionTask t WHERE t.epreuve = :epreuve)
              AND e.audioUrl IS NULL
              AND e.audioStatus IN :statuses
            """)
    long countNeedingAudio(
            @Param("epreuve") EpreuveType epreuve,
            @Param("statuses") Collection<ExampleAudioStatus> statuses);

    @Query("""
            SELECT e FROM ProductionExample e
            WHERE e.taskId IN (SELECT t.id FROM ProductionTask t WHERE t.epreuve = :epreuve)
              AND e.audioStatus = :status
            ORDER BY e.audioGeneratedAt DESC NULLS LAST
            """)
    List<ProductionExample> findByEpreuveAndAudioStatus(
            @Param("epreuve") EpreuveType epreuve,
            @Param("status") ExampleAudioStatus status);
}
