package com.sejourfr.app.repository;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillTaskCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SkillPromptRepository extends JpaRepository<SkillPrompt, UUID> {

    /** Les petits sujets actifs d'une competence, dans l'ordre d'affichage. */
    List<SkillPrompt> findBySkillIdAndActiveTrueOrderByDisplayOrderAsc(UUID skillId);

    Optional<SkillPrompt> findByCode(String code);

    /**
     * Sujet + sa competence deja chargee. Necessaire des qu'on quitte la session
     * Hibernate d'origine (pipeline asynchrone) ou qu'on construit un DTO qui
     * expose le code, le titre et la tache de la competence : sans le JOIN
     * FETCH, chaque sujet declencherait une requete supplementaire.
     */
    @Query("SELECT p FROM SkillPrompt p JOIN FETCH p.skill WHERE p.id = :id")
    Optional<SkillPrompt> findByIdWithSkill(@Param("id") UUID id);

    /**
     * Nombre de sujets actifs par competence active, pour un ensemble de taches.
     * Renvoie {@code [skillId, count]}. Une competence sans sujet actif est
     * absente : au caller de comber a zero.
     */
    @Query("""
            SELECT p.skill.id, COUNT(p)
            FROM SkillPrompt p
            WHERE p.skill.taskCode IN :taskCodes
              AND p.active = true
              AND p.skill.active = true
            GROUP BY p.skill.id
            """)
    List<Object[]> countActiveBySkillForTaskCodes(@Param("taskCodes") Collection<SkillTaskCode> taskCodes);

    /**
     * Les sujets actifs de PLUSIEURS competences actives, en une seule requete,
     * competence chargee. Sert les ecrans qui melangent des competences sans
     * rapport de tache (le Plan : jusqu'a 11 competences) — une requete par
     * competence y serait un N+1 pur.
     */
    @Query("""
            SELECT p FROM SkillPrompt p
            JOIN FETCH p.skill s
            WHERE s.id IN :skillIds
              AND p.active = true
              AND s.active = true
            ORDER BY p.displayOrder ASC
            """)
    List<SkillPrompt> findActiveBySkillIds(@Param("skillIds") Collection<UUID> skillIds);

    /**
     * Vue admin des sujets d'une competence : DESACTIVES COMPRIS. La console
     * doit pouvoir rouvrir un sujet retire du catalogue, donc le voir.
     */
    List<SkillPrompt> findBySkillIdOrderByDisplayOrderAsc(UUID skillId);

    /** Meme portee que ci-dessus : le compteur admin inclut les sujets desactives. */
    long countBySkillId(UUID skillId);

    /**
     * Nombre de sujets (actifs ou non) par competence, pour la page de liste et
     * les statistiques admin. Renvoie {@code [skillId, count]} ; une competence
     * sans aucun sujet est absente, au caller de combler a zero.
     */
    @Query("""
            SELECT p.skill.id, COUNT(p)
            FROM SkillPrompt p
            WHERE p.skill.id IN :skillIds
            GROUP BY p.skill.id
            """)
    List<Object[]> countBySkillIds(@Param("skillIds") Collection<UUID> skillIds);

    /**
     * Les competences qui ont <b>au moins un sujet actif</b> — une seule requete
     * agregee, jamais un compte par competence.
     *
     * <p>C'est le filtre de <b>faisabilite</b> du Plan cote expression : une
     * competence sans sujet publie ne peut porter aucune action, donc elle ne
     * doit ni entrer dans le pool, ni etre comptee a l'ecran. Le referentiel
     * tient en quelques dizaines de lignes : on rend l'ensemble, on ne le
     * parametre pas par une liste d'identifiants qui ferait varier le plan
     * d'execution d'un candidat a l'autre.
     */
    @Query("""
            SELECT DISTINCT p.skill.id
            FROM SkillPrompt p
            WHERE p.active = true
              AND p.skill.active = true
            """)
    List<UUID> findSkillIdsWithActivePrompt();

    boolean existsByCode(String code);
}
