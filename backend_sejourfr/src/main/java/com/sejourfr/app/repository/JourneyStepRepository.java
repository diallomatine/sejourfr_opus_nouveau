package com.sejourfr.app.repository;

import com.sejourfr.app.entity.JourneyStep;
import org.springframework.data.domain.Pageable;
import com.sejourfr.app.entity.Skill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
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
     * <b>Les etapes CLOTUREES de plusieurs cycles, en UNE requete.</b>
     *
     * <p>C'est la lecture de la page Progression : elle raconte plusieurs cycles
     * d'un coup, donc elle les charge <b>en lot</b> — patron des lots existants
     * du Plan. 🛑 Une requete par cycle aurait fait grimper le cout avec
     * l'anciennete du compte : un candidat de six mois aurait paye sept requetes
     * la ou un nouveau en paie deux, et la regression serait passee inapercue en
     * unitaire.
     *
     * <p>🛑 <b>Filtre en base, pas apres coup</b> :
     * <ul>
     *   <li>{@code closed_at IS NOT NULL} — une etape <b>ouverte</b> n'est jamais
     *       « travaillee » ; un cycle historise peut tres bien en porter (il a
     *       ete ferme par un geste, pas par l'achevement de tout) ;</li>
     *   <li>{@code resolution <> SUPERSEDED} — une etape rendue caduque par une
     *       evaluation plus recente est {@code OBSOLETE}, donc invisible partout
     *       ailleurs ({@code JourneyCycleDto.etapesTerminees} l'exclut deja). La
     *       compter feliciterait le candidat pour du travail qu'il n'a pas
     *       fait ;</li>
     *   <li>le type {@code DIAGNOSTIC} remonte aussi : l'appelant compte par
     *       type, et une seconde requete pour l'ecarter ne servirait a rien.</li>
     * </ul>
     *
     * <p>{@code LEFT JOIN FETCH} sur la competence : c'est elle qui porte le
     * <b>titre</b> servi, jamais recopie sur l'etape. Sans ce fetch, un
     * historique de trente competences coutait trente requetes.
     */
    @Query("""
            SELECT s FROM JourneyStep s
            LEFT JOIN FETCH s.skill
            WHERE s.journey.id IN :journeyIds
              AND s.closedAt IS NOT NULL
              AND (s.resolution IS NULL
                   OR s.resolution <> com.sejourfr.app.enums.JourneyStepResolution.SUPERSEDED)
            ORDER BY s.position ASC
            """)
    List<JourneyStep> findCloturesDesCycles(@Param("journeyIds") Collection<UUID> journeyIds);

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
     *
     * <p>🛑 <b>LE CYCLE EN COURS, ET LUI SEUL</b> (D-13). Depuis V067 un
     * candidat porte plusieurs cycles : un {@code EN_COURS}, un
     * {@code EN_ATTENTE} <b>invisible</b>, et son historique. Sans ce filtre, la
     * premiere place du Plan pouvait tomber sur une etape d'un cycle que le
     * candidat n'a pas sous les yeux — donc annoncer une competence introuvable
     * dans son parcours. ⚠️ Le <b>niveau cible n'est plus une cle</b> : un
     * changement d'objectif met a jour le cycle en cours au lieu d'en creer un
     * second, et filtrer dessus aurait rendu la premiere place muette entre le
     * changement d'objectif et la lecture suivante.
     */
    @Query("""
            SELECT s.skill FROM JourneyStep s
            WHERE s.journey.user.id = :userId
              AND s.journey.module = com.sejourfr.app.enums.Module.TCF
              AND s.journey.status = com.sejourfr.app.enums.JourneyStatus.EN_COURS
              AND s.closedAt IS NULL
              AND s.type = com.sejourfr.app.enums.JourneyStepType.TRAIN_SKILL
              AND s.skill IS NOT NULL
            ORDER BY s.position ASC
            """)
    List<Skill> findCompetencesOuvertes(@Param("userId") UUID userId, Pageable pageable);
}
