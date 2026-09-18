package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
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

    /**
     * <b>Ce candidat a-t-il deja fait traiter cette evaluation, par N'IMPORTE
     * LEQUEL de ses cycles ?</b>
     *
     * <p>🛑 <b>La cle d'unicite porte le {@code journey_id}, mais la QUESTION est
     * posee au candidat</b> — et c'est un choix, pas un raccourci. Depuis D-13 un
     * candidat porte plusieurs cycles : une evaluation traitee pendant le cycle
     * A peut etre rejouee apres que le cycle B a ete promu, et une lecture bornee
     * a B l'aurait retraitee — donc refabrique des lots deja honores. La question
     * « l'a-t-on deja traitee ? » ne depend pas du cycle qui a ecrit.
     *
     * <p>La contrainte en base reste {@code UNIQUE (journey_id,
     * source_assessment_id)} : deux cycles du meme candidat peuvent
     * legitimement journaliser la meme evaluation — celui qui a cloture une
     * etape, et celui qui a recu les priorites.
     */
    @Query("""
            SELECT COUNT(e) > 0 FROM JourneyAssessmentEvent e
            WHERE e.journey.user.id = :userId
              AND e.journey.module = :module
              AND e.sourceAssessmentId = :sourceAssessmentId
            """)
    boolean dejaTraiteeParUnCycle(
            @Param("userId") UUID userId,
            @Param("module") Module module,
            @Param("sourceAssessmentId") UUID sourceAssessmentId);

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
     * <p>⚠️ <b>Portee au CANDIDAT, pas au cycle</b> (D-13) : la chronologie de ce
     * qu'un parcours sait deja ne se remet pas a zero parce qu'un cycle a ete
     * historise. Sans cela, la premiere synchronisation tardive apres une
     * actualisation aurait pu defaire le cycle promu.
     *
     * <p>{@code Optional.empty()} = aucune evaluation de cette epreuve n'a encore
     * ete traitee pour ce candidat. 🛑 <b>Ce n'est pas « epreuve non mesuree »</b> :
     * cette question a une seule autorite dans le depot, et ce n'est pas cette
     * table (arbitrage du 2026-09-16, « il n'existe qu'UNE notion de mesuree »).
     */
    @Query("SELECT MAX(e.completedAt) FROM JourneyAssessmentEvent e "
            + "WHERE e.journey.user.id = :userId AND e.journey.module = :module "
            + "AND e.examType = :examType")
    Optional<Instant> findDerniereMesureDeLEpreuve(
            @Param("userId") UUID userId,
            @Param("module") Module module,
            @Param("examType") EpreuveType examType);
}
