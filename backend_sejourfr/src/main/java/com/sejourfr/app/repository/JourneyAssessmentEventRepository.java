package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.enums.EpreuveType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface JourneyAssessmentEventRepository
        extends JpaRepository<JourneyAssessmentEvent, UUID> {

    boolean existsByJourneyIdAndSourceAssessmentId(UUID journeyId, UUID sourceAssessmentId);

    /**
     * La date de fin de la <b>derniere</b> evaluation deja traitee qui mesurait
     * cette epreuve — le repere exact de R14.
     *
     * <p>Une evaluation arrivee en retard mais <b>plus ancienne</b> que celle-la
     * est enregistree et <b>ne modifie pas</b> la structure de son epreuve : le
     * cas des synchronisations mobiles tardives. Sans ce repere, un examen de
     * mardi synchronise jeudi remplacerait le lot qu'un examen de mercredi
     * venait de creer.
     *
     * <p>Elle se lit sur les <b>evenements</b> et non sur les lots : une epreuve
     * mesuree <b>sans produire de priorite</b> (R9) ne cree aucun lot, et
     * laisserait donc un trou dans la chronologie.
     *
     * <p>{@code Optional.empty()} = aucune evaluation de cette epreuve n'a encore
     * ete traitee par ce parcours. 🛑 <b>Ce n'est pas « epreuve non mesuree »</b> :
     * cette question a une seule autorite dans le depot, et ce n'est pas cette
     * table (arbitrage du 2026-09-16, « il n'existe qu'UNE notion de mesuree »).
     */
    @Query("SELECT MAX(e.completedAt) FROM JourneyAssessmentEvent e "
            + "WHERE e.journey.id = :journeyId AND e.examType = :examType")
    Optional<Instant> findDerniereMesureDeLEpreuve(
            @Param("journeyId") UUID journeyId, @Param("examType") EpreuveType examType);
}
