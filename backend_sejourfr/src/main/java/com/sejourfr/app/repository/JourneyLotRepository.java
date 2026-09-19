package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface JourneyLotRepository extends JpaRepository<JourneyLot, UUID> {

    /**
     * Le lot ouvert d'une epreuve, s'il existe. R5 garantit qu'il n'y en a
     * jamais deux : c'est un index unique partiel qui le tient, pas une
     * convention.
     */
    Optional<JourneyLot> findByJourneyIdAndExamTypeAndStatus(
            UUID journeyId, EpreuveType examType, JourneyLotStatus status);

    /**
     * Le jumeau civique : le lot ouvert d'une <b>thematique</b>. R5 transposee —
     * {@code uq_journey_lot_open_par_theme} (V069) garantit qu'il n'y en a
     * jamais deux.
     */
    Optional<JourneyLot> findByJourneyIdAndThemeIdAndStatus(
            UUID journeyId, UUID themeId, JourneyLotStatus status);

    @Query("""
            SELECT l FROM JourneyLot l
            WHERE l.journey.id = :journeyId AND l.status = :status
            """)
    List<JourneyLot> findByJourneyIdAndStatus(
            @Param("journeyId") UUID journeyId, @Param("status") JourneyLotStatus status);
}
