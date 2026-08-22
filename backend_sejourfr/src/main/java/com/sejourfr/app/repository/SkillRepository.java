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
     * La PREMIERE competence active de chaque tache, {@code [taskCode, id]}.
     *
     * <p>C'est le lot ouvert aux comptes sans acces TCF (cf.
     * {@code SkillAccessService}) : une requete de 6 lignes, jamais 48 — le
     * verrou est evalue a chaque ecran du module, il ne doit pas couter le
     * catalogue entier.
     *
     * <p>« Premiere » = <b>rang le plus bas encore ACTIF</b>, et non
     * litteralement {@code display_order = 1} : desactiver le rang 1 depuis la
     * console fermerait sinon la tache entiere aux comptes gratuits. Sur le
     * contenu publie les deux definitions coincident, et
     * {@code uq_skills_task_order} garantit qu'il n'y a jamais d'ex aequo.
     */
    @Query("""
            SELECT s.taskCode, s.id
            FROM Skill s
            WHERE s.active = true
              AND s.displayOrder = (
                  SELECT MIN(s2.displayOrder) FROM Skill s2
                  WHERE s2.taskCode = s.taskCode AND s2.active = true)
            """)
    List<Object[]> findFirstActiveIdPerTaskCode();

    /**
     * La PREMIERE competence active de chaque domaine de COMPREHENSION,
     * {@code [section, id]}. Jumelle de {@link #findFirstActiveIdPerTaskCode()}
     * pour les competences sans tache : c'est le lot ouvert aux comptes sans
     * acces TCF (cf. {@code SkillAccessService}), deux lignes au plus.
     *
     * <p>Meme definition de « premiere » que sa jumelle : <b>rang le plus bas
     * encore ACTIF</b>, et non litteralement {@code display_order = 1}.
     * Desactiver le rang 1 depuis la console fermerait sinon le domaine entier
     * aux comptes gratuits. Sur le contenu publie ce rang est le niveau A2,
     * l'entree de gamme du domaine.
     *
     * <p>{@code taskCode IS NULL} identifie exactement les competences de
     * comprehension : la base garantit l'equivalence
     * ({@code chk_skills_task_code_presence}), il n'existe pas de troisieme cas.
     */
    @Query("""
            SELECT s.section, s.id
            FROM Skill s
            WHERE s.active = true
              AND s.taskCode IS NULL
              AND s.displayOrder = (
                  SELECT MIN(s2.displayOrder) FROM Skill s2
                  WHERE s2.section = s.section AND s2.taskCode IS NULL AND s2.active = true)
            """)
    List<Object[]> findFirstActiveIdPerComprehensionSection();

    /**
     * Toutes les competences SANS tache d'un domaine, desactivees comprises.
     * Reserve a l'admin : c'est le pendant de
     * {@link #findByTaskCodeOrderByDisplayOrderAsc} pour le controle d'unicite
     * du rang, que {@code uq_skills_section_order_comprehension} verrouille en
     * base.
     */
    List<Skill> findBySectionAndTaskCodeIsNullOrderByDisplayOrderAsc(SkillSection section);

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

    /**
     * Les competences ACTIVES de comprehension, tous domaines confondus : six
     * lignes au plus sur le contenu publie ({@code CO-A2}..{@code CE-B2}).
     *
     * <p>C'est la table de correspondance dont a besoin le producteur
     * d'observations CO/CE : une question de niveau B1 en comprehension orale
     * alimente {@code CO-B1} et rien d'autre. La charger d'un coup evite une
     * requete par niveau observe, et une seule suffit pour tout un attempt.
     *
     * <p>{@code taskCode IS NULL} identifie exactement la comprehension, la base
     * garantissant l'equivalence ({@code chk_skills_task_code_presence}).
     */
    List<Skill> findByTaskCodeIsNullAndActiveTrueOrderBySectionAscDisplayOrderAsc();

    /**
     * Les competences ACTIVES d'EXPRESSION, toutes taches confondues : 48 lignes
     * sur le contenu publie (2 epreuves x 3 taches x 8), dans l'ordre du
     * referentiel.
     *
     * <p>C'est le pendant de
     * {@link #findByTaskCodeIsNullAndActiveTrueOrderBySectionAscDisplayOrderAsc()}
     * pour l'expression, et le socle de la vue « une epreuve, ses competences »
     * du Plan. Elle <b>remplace</b> le {@code GROUP BY} de
     * {@link #countActiveByTaskCodes} chez {@code PlanCycleResolver} : les
     * comptes par tache s'en derivent, donc le Plan ne paie <b>aucune requete de
     * plus</b> — il lit les lignes au lieu de les compter.
     *
     * <p>{@code taskCode IS NOT NULL} identifie exactement l'expression, la base
     * garantissant l'equivalence ({@code chk_skills_task_code_presence}).
     */
    List<Skill> findByTaskCodeIsNotNullAndActiveTrueOrderBySectionAscTaskCodeAscDisplayOrderAsc();

    /**
     * Les competences ACTIVES d'un ou plusieurs <b>paliers</b>, tous domaines
     * confondus, dans l'ordre pedagogique (domaine, tache, rang d'affichage).
     *
     * <p>C'est le referentiel dont a besoin le Plan pour repondre a « que reste-t-il
     * a APPRENDRE au palier que je construis ? » — une question qui ne se lit pas
     * dans l'historique du candidat, puisque par definition il n'y a rien observe.
     * Une seule requete quel que soit le nombre de paliers demandes.
     *
     * <p>{@code target_level} est une chaine ({@code "A1"}..{@code "B2"}) : le
     * referentiel des competences descend plus bas que {@code TargetLevel}, et la
     * colonne fait foi.
     */
    List<Skill> findByTargetLevelInAndActiveTrueOrderBySectionAscTaskCodeAscDisplayOrderAsc(
            Collection<String> targetLevels);
}
