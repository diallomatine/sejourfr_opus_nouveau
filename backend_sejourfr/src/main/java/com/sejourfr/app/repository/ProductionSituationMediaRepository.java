package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionSituationMedia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface ProductionSituationMediaRepository extends JpaRepository<ProductionSituationMedia, UUID> {

    List<ProductionSituationMedia> findBySituationIdOrderByDisplayOrderAsc(UUID situationId);

    /** Chargement groupe pour eviter le N+1 quand on liste les situations d'une tache. */
    List<ProductionSituationMedia> findBySituationIdInOrderByDisplayOrderAsc(Collection<UUID> situationIds);
}
