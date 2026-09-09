package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillTaskCode;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserSkillAttemptRepository extends JpaRepository<UserSkillAttempt, UUID> {

    /**
     * Tentative + sujet + competence deja charges. Indispensable au pipeline
     * asynchrone, qui lit l'entite hors de la session Hibernate d'origine.
     */
    @Query("""
            SELECT a FROM UserSkillAttempt a
            JOIN FETCH a.user
            JOIN FETCH a.skillPrompt p
            JOIN FETCH p.skill
            WHERE a.id = :id
            """)
    Optional<UserSkillAttempt> findByIdWithPrompt(@Param("id") UUID id);

    /**
     * Rejeu d'une production deja rendue (V046). Borne a l'utilisateur : une
     * cle tiree par un client ne peut jamais resoudre vers la production d'un
     * tiers, meme si deux clients tirent la meme UUID.
     */
    @Query("SELECT a FROM UserSkillAttempt a JOIN FETCH a.skillPrompt "
        + "WHERE a.user.id = :userId AND a.clientSubmissionId = :clientSubmissionId")
    Optional<UserSkillAttempt> findByUserAndClientSubmissionId(
            @Param("userId") UUID userId,
            @Param("clientSubmissionId") UUID clientSubmissionId);

    /**
     * Compteur du quota freemium : nombre d'analyses IA que l'utilisateur a
     * consommees a vie. On compte les analyses DEMANDEES (et acceptees), pas
     * les analyses reussies — sinon un echec fournisseur suivi d'un retry
     * offrirait des analyses supplementaires. S'appuie sur l'index partiel
     * {@code idx_user_skill_attempts_analysis_quota}.
     */
    long countByUserIdAndAnalysisRequestedTrue(UUID userId);

    /**
     * Le candidat a-t-il deja produit sur ce sujet ? C'est la condition qui
     * ouvre l'acces aux 3 references : on ne les revele qu'apres la production.
     */
    boolean existsByUserIdAndSkillPromptId(UUID userId, UUID skillPromptId);

    long countByUserIdAndSkillPromptId(UUID userId, UUID skillPromptId);

    /** Historique du candidat sur un sujet, plus recente d'abord, plafonne. */
    List<UserSkillAttempt> findByUserIdAndSkillPromptIdOrderByCreatedAtDesc(
            UUID userId, UUID skillPromptId, Pageable pageable);

    /** Derniere tentative du candidat sur un sujet : c'est elle qui donne le statut. */
    Optional<UserSkillAttempt> findFirstByUserIdAndSkillPromptIdOrderByCreatedAtDesc(
            UUID userId, UUID skillPromptId);

    /**
     * Derniere tentative du candidat sur CHACUN des sujets des taches demandees.
     *
     * <p>Formule en JPQL pur (sous-requete correlee sur {@code MAX(createdAt)})
     * plutot qu'en {@code DISTINCT ON} natif : le resultat reste une liste
     * d'entites typees, sans conversion manuelle de colonnes. L'index
     * {@code (user_id, skill_prompt_id, created_at DESC)} couvre exactement
     * cette sous-requete.
     *
     * <p>Une egalite parfaite de {@code createdAt} sur un meme sujet
     * renverrait deux lignes ; le caller deduplique en gardant la premiere, ce
     * qui rend le cas inoffensif.
     */
    @Query("""
            SELECT a FROM UserSkillAttempt a
            JOIN FETCH a.skillPrompt p
            JOIN FETCH p.skill s
            WHERE a.user.id = :userId
              AND s.taskCode IN :taskCodes
              AND a.createdAt = (
                    SELECT MAX(a2.createdAt) FROM UserSkillAttempt a2
                    WHERE a2.user.id = :userId AND a2.skillPrompt.id = p.id
              )
            """)
    List<UserSkillAttempt> findLatestPerPromptByTaskCodes(
            @Param("userId") UUID userId,
            @Param("taskCodes") Collection<SkillTaskCode> taskCodes);

    /** Meme principe, restreint aux sujets d'une seule competence. */
    @Query("""
            SELECT a FROM UserSkillAttempt a
            JOIN FETCH a.skillPrompt p
            JOIN FETCH p.skill s
            WHERE a.user.id = :userId
              AND s.id = :skillId
              AND a.createdAt = (
                    SELECT MAX(a2.createdAt) FROM UserSkillAttempt a2
                    WHERE a2.user.id = :userId AND a2.skillPrompt.id = p.id
              )
            """)
    List<UserSkillAttempt> findLatestPerPromptBySkill(
            @Param("userId") UUID userId,
            @Param("skillId") UUID skillId);

    /**
     * Meme principe, pour un ensemble de competences quelconque (le Plan
     * melange des competences de taches differentes : jusqu'a 11 d'un coup).
     */
    @Query("""
            SELECT a FROM UserSkillAttempt a
            JOIN FETCH a.skillPrompt p
            JOIN FETCH p.skill s
            WHERE a.user.id = :userId
              AND s.id IN :skillIds
              AND a.createdAt = (
                    SELECT MAX(a2.createdAt) FROM UserSkillAttempt a2
                    WHERE a2.user.id = :userId AND a2.skillPrompt.id = p.id
              )
            """)
    List<UserSkillAttempt> findLatestPerPromptBySkillIds(
            @Param("userId") UUID userId,
            @Param("skillIds") Collection<UUID> skillIds);

    /** Nombre de tentatives par sujet : {@code [skillPromptId, count]}. */
    @Query("""
            SELECT a.skillPrompt.id, COUNT(a)
            FROM UserSkillAttempt a
            WHERE a.user.id = :userId
              AND a.skillPrompt.skill.taskCode IN :taskCodes
            GROUP BY a.skillPrompt.id
            """)
    List<Object[]> countPerPromptByTaskCodes(
            @Param("userId") UUID userId,
            @Param("taskCodes") Collection<SkillTaskCode> taskCodes);

    @Query("""
            SELECT a.skillPrompt.id, COUNT(a)
            FROM UserSkillAttempt a
            WHERE a.user.id = :userId
              AND a.skillPrompt.skill.id = :skillId
            GROUP BY a.skillPrompt.id
            """)
    List<Object[]> countPerPromptBySkill(
            @Param("userId") UUID userId,
            @Param("skillId") UUID skillId);

    /** Un sujet ne peut plus etre supprime des qu'un candidat a produit dessus. */
    boolean existsBySkillPromptId(UUID skillPromptId);

    /**
     * Une competence ne peut plus etre supprimee des qu'un candidat a produit
     * sur N'IMPORTE LEQUEL de ses sujets : la supprimer emporterait ses sujets
     * en cascade, donc l'historique rattache. La console propose alors la
     * desactivation.
     */
    boolean existsBySkillPromptSkillId(UUID skillId);

    /** Tentatives, tous candidats confondus, sur un sujet (compteur admin). */
    long countBySkillPromptId(UUID skillPromptId);

    /**
     * Tentatives par sujet, tous candidats confondus : {@code [skillPromptId,
     * count]}. Version admin de {@code countPerPromptBySkill}, qui est elle
     * bornee au candidat courant.
     */
    @Query("""
            SELECT a.skillPrompt.id, COUNT(a)
            FROM UserSkillAttempt a
            WHERE a.skillPrompt.id IN :promptIds
            GROUP BY a.skillPrompt.id
            """)
    List<Object[]> countPerPromptForPromptIds(@Param("promptIds") Collection<UUID> promptIds);

    /**
     * Agregat des statistiques admin, une ligne par competence :
     * {@code [skillId, tentatives, analysees, validees]}.
     *
     * <p><b>« Analysee » = qui porte un verdict</b> ({@code criterionStatus}
     * non nul), et non « qui a demande une analyse » : une analyse partie en
     * echec fournisseur a bien consomme le quota du candidat mais n'a jamais
     * juge sa production. La compter au denominateur ferait baisser le taux de
     * validation d'une compétence pour une panne qui ne dit rien de son
     * contenu.
     */
    @Query("""
            SELECT a.skillPrompt.skill.id,
                   COUNT(a),
                   SUM(CASE WHEN a.criterionStatus IS NOT NULL THEN 1 ELSE 0 END),
                   SUM(CASE WHEN a.criterionStatus = :validated THEN 1 ELSE 0 END)
            FROM UserSkillAttempt a
            WHERE a.skillPrompt.skill.id IN :skillIds
            GROUP BY a.skillPrompt.skill.id
            """)
    List<Object[]> aggregateStatsBySkillIds(@Param("skillIds") Collection<UUID> skillIds,
                                            @Param("validated") SkillCriterionStatus validated);
}
