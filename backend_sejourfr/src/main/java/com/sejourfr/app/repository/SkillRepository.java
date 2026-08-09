package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * {@link JpaSpecificationExecutor} est necessaire a la console admin, dont les
 * quatre filtres (epreuve, tache, actif, recherche libre) sont facultatifs et se
 * combinent : les decliner en methodes derivees demanderait seize signatures.
 */
@Repository
public interface SkillRepository extends JpaRepository<Skill, UUID>,
        JpaSpecificationExecutor<Skill> {

    /** Les competences actives d'une tache, dans l'ordre pedagogique. */
    List<Skill> findByTaskCodeAndActiveTrueOrderByDisplayOrderAsc(SkillTaskCode taskCode);

    /** Les competences actives d'une epreuve entiere (3 taches), ordre d'examen. */
    List<Skill> findBySectionAndActiveTrueOrderByTaskCodeAscDisplayOrderAsc(SkillSection section);

    /** Inclut les competences desactivees : reserve a l'admin. */
    List<Skill> findByTaskCodeOrderByDisplayOrderAsc(SkillTaskCode taskCode);

    /** Le code editorial est unique et immuable : c'est l'ancre des seeds et de l'admin. */
    Optional<Skill> findByCode(String code);

    /** Resolution en lot des codes editoriaux : une requete, pas une par code. */
    List<Skill> findByCodeIn(Collection<String> codes);

    /**
     * Nombre de competences actives par tache. Renvoie {@code [taskCode, count]} :
     * les taches sans aucune competence active sont ABSENTES du resultat — au
     * caller de derouler les 3 taches attendues et de combler a zero, sinon une
     * epreuve non encore seedee disparaitrait de l'ecran.
     */
    @Query("""
            SELECT s.taskCode, COUNT(s)
            FROM Skill s
            WHERE s.taskCode IN :taskCodes AND s.active = true
            GROUP BY s.taskCode
            """)
    List<Object[]> countActiveByTaskCodes(@Param("taskCodes") Collection<SkillTaskCode> taskCodes);

    /**
     * Le code editorial est unique en base : ce test permet a l'admin de
     * refuser un doublon avec un message explicite plutot que de laisser
     * remonter une violation de contrainte en 500.
     */
    boolean existsByCode(String code);

    /**
     * Vue admin d'une epreuve : competences DESACTIVEES COMPRISES, dans l'ordre
     * d'affichage de la console (tache puis rang). Le candidat, lui, passe par
     * {@link #findBySectionAndActiveTrueOrderByTaskCodeAscDisplayOrderAsc}.
     */
    List<Skill> findBySectionOrderByTaskCodeAscDisplayOrderAsc(SkillSection section);

    /** Meme vue, toutes epreuves confondues. */
    List<Skill> findAllByOrderByTaskCodeAscDisplayOrderAsc();
}
