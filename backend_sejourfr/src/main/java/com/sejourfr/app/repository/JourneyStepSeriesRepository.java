package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyStepSeries;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface JourneyStepSeriesRepository extends JpaRepository<JourneyStepSeries, UUID> {

    /**
     * <b>Tous les essais de plusieurs etapes, en UNE requete</b>, l'attempt
     * <b>deja charge</b>.
     *
     * <p>🛑 <b>Le fetch n'est pas un confort</b> : le verdict d'une serie se lit
     * sur l'attempt ({@code score}, {@code finishedAt}). Sans lui, un cycle de
     * huit etapes de comprehension coutait seize requetes de plus a chaque
     * ouverture du Plan — et le cout du parcours est verrouille par une
     * <b>egalite</b>, pas par un {@code <=}.
     *
     * <p>L'ordre est celui de la <b>lecture</b> : carte par carte, puis du plus
     * ancien essai au plus recent. Le « dernier score » est donc le dernier
     * element de sa carte, sans tri cote Java.
     */
    @Query("""
            SELECT s FROM JourneyStepSeries s
            JOIN FETCH s.attempt
            WHERE s.step.id IN :stepIds
            ORDER BY s.seriesIndex ASC, s.createdAt ASC
            """)
    List<JourneyStepSeries> findDesEtapes(@Param("stepIds") Collection<UUID> stepIds);

    /**
     * Cette session a-t-elle ete lancee depuis une carte d'etape ?
     *
     * <p>C'est le fait qui fait d'un {@code TRAINING} une session <b>sans
     * correction pendant la passation</b> — le regime est pose a la creation
     * ({@code attempts.mode}), et cette lecture ne sert qu'aux verifications.
     */
    boolean existsByAttemptId(UUID attemptId);
}
