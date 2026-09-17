package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyStep;
import org.springframework.data.domain.Pageable;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.entity.Skill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface JourneyStepRepository extends JpaRepository<JourneyStep, UUID> {

    /**
     * <b>Toutes</b> les etapes du parcours, dans l'ordre de la file, competence
     * chargee.
     *
     * <p>🛑 <b>Tout, et en UNE requete.</b> La lecture a besoin de l'historique
     * entier : le statut de rendu d'une etape close depend de <b>l'ordre de
     * cloture</b> des etapes de position inferieure (une etape close hors de son
     * tour est {@code SKIPPED}), et le filtrage d'affichage a besoin des N
     * dernieres closes. Charger « les ouvertes » puis « les recentes »
     * separement aurait fait deux requetes pour un parcours qui tient dans une
     * page.
     *
     * <p>{@code LEFT JOIN FETCH} sur la competence : c'est elle qui porte le
     * code, le titre, le domaine et la tache — jamais recopies sur l'etape. Sans
     * ce fetch, un parcours de vingt etapes coutait vingt requetes.
     */
    @Query("""
            SELECT s FROM JourneyStep s
            LEFT JOIN FETCH s.skill
            LEFT JOIN FETCH s.lot
            WHERE s.journey.id = :journeyId
            ORDER BY s.position ASC
            """)
    List<JourneyStep> findAllByJourney(@Param("journeyId") UUID journeyId);

    /**
     * Les etapes <b>ouvertes</b> d'un lot. Sert R7 : « tous les entrainements de
     * ce lot sont-ils faits ? » decide si son checkpoint est satisfait ou
     * remplace.
     */
    @Query("""
            SELECT s FROM JourneyStep s
            LEFT JOIN FETCH s.skill
            WHERE s.lot.id = :lotId AND s.closedAt IS NULL
            ORDER BY s.position ASC
            """)
    List<JourneyStep> findOuvertesByLot(@Param("lotId") UUID lotId);

    /**
     * <b>Les competences des etapes d'entrainement encore ouvertes</b> d'un
     * candidat, <b>dans l'ordre de la file</b>.
     *
     * <p>C'est la « premiere place » que le freemium ouvre d'office
     * ({@code PlanFocusResolver}). 🛑 <b>UNE seule requete</b>, jointure
     * comprise : le Plan verrouille son cout par une <b>egalite</b>, et deux
     * lectures (le parcours, puis ses etapes) l'auraient fait grimper de deux a
     * chaque ouverture de l'ecran.
     *
     * <p>🛑 <b>Verrous ignores</b>, volontairement : c'est l'etape que le
     * parcours designe, pas celle qu'il rend executable. Lui preferer une etape
     * deja deverrouillee rendrait l'exemption inutile.
     *
     * <p>🛑 <b>Plusieurs lignes, pas une seule</b> (correctif du 2026-09-17) :
     * l'appelant garde la premiere competence <b>presente dans son pool</b>, et
     * le pool ecarte les competences sans contenu publie. C'est exactement le
     * saut que fait {@code JourneyReadService.elire} ; ne lire qu'une ligne
     * faisait dire a l'un « c'est celle-la » et a l'autre « il n'y en a
     * pas », donc ouvrait au compte gratuit une competence que la carte
     * n'annoncait pas.
     */
    @Query("""
            SELECT s.skill FROM JourneyStep s
            WHERE s.journey.user.id = :userId
              AND s.journey.targetLevel = :targetLevel
              AND s.closedAt IS NULL
              AND s.type = com.sejourfr.app.enums.JourneyStepType.TRAIN_SKILL
              AND s.skill IS NOT NULL
            ORDER BY s.position ASC
            """)
    List<Skill> findCompetencesOuvertes(
            @Param("userId") UUID userId,
            @Param("targetLevel") TargetLevel targetLevel,
            Pageable pageable);
}
