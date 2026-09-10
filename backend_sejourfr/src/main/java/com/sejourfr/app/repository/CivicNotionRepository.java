package com.sejourfr.app.repository;

import com.sejourfr.app.entity.CivicNotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CivicNotionRepository extends JpaRepository<CivicNotion, UUID> {

    @Query("""
            SELECT n FROM CivicNotion n
            LEFT JOIN FETCH n.mergedInto
            ORDER BY n.themeCode, n.displayOrder
            """)
    List<CivicNotion> findAllOrdonnees();

    Optional<CivicNotion> findByCode(String code);

    /**
     * Combien de questions <b>validees</b> par notion, et sur quelle mention.
     *
     * <p>🛑 La ventilation par mention n'est pas un confort : la regle de
     * {@code 50_} §6.1 degrade <b>par notion ET par mention</b>. Un total
     * global cacherait qu'une notion pleinement utilisable en NAT est vide en
     * CSP.
     *
     * <p>Seules les questions ACTIVES comptent : une question desactivee ne
     * peut plus etre tiree, elle ne couvre donc rien.
     */
    @Query(value = """
            SELECT q.civic_notion_id, q.difficulty, COUNT(*)
            FROM questions q
            WHERE q.civic_notion_id IS NOT NULL AND q.is_active = true
            GROUP BY q.civic_notion_id, q.difficulty
            """, nativeQuery = true)
    List<Object[]> couvertureParNotionEtMention();

    @Query(value = """
            SELECT notion_id, COUNT(*)
            FROM question_notion_suggestions
            GROUP BY notion_id
            """, nativeQuery = true)
    List<Object[]> suggestionsParNotion();

    /**
     * Pose le tag VALIDE sur une question. {@code notionId} nul l'efface —
     * « je me suis trompe » doit rester possible sans passer par la base.
     *
     * <p>Requete de mise a jour ciblee plutot qu'un chargement d'entite :
     * {@code Question} est un agregat lourd (theme, passage, medias, choix), et
     * un ecran de tagging en pose des centaines a la suite.
     */
    /**
     * La file de tagging : questions civiques ACTIVES, filtrees par theme et
     * par etat de tagging, ordre stable.
     *
     * <p>🛑 <b>L'ordre est deterministe</b> ({@code created_at, id}) : un
     * tagueur qui pagine 1 016 questions ne doit jamais en revoir une deja
     * traitee ni en sauter une parce que le tri a bouge entre deux pages.
     *
     * <p>{@code theme} nul = tous les themes. {@code tagged} nul = les deux
     * etats ; {@code false} = la file de travail.
     */
    @Query(value = """
            SELECT q.id, q.statement, t.code, q.difficulty, n.code, n.label
            FROM questions q
                     JOIN themes t ON t.id = q.theme_id
                     LEFT JOIN civic_notions n ON n.id = q.civic_notion_id
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND (CAST(:theme AS varchar) IS NULL OR t.code = CAST(:theme AS varchar))
              AND (CAST(:tagged AS boolean) IS NULL
                   OR (CAST(:tagged AS boolean) = true AND q.civic_notion_id IS NOT NULL)
                   OR (CAST(:tagged AS boolean) = false AND q.civic_notion_id IS NULL))
            ORDER BY q.created_at, q.id
            LIMIT :limit OFFSET :offset
            """, nativeQuery = true)
    List<Object[]> fileDeTagging(@Param("theme") String theme,
                                 @Param("tagged") Boolean tagged,
                                 @Param("limit") int limit,
                                 @Param("offset") int offset);

    /** Combien reste-t-il a taguer, tous themes confondus. */
    @Query(value = """
            SELECT COUNT(*) FROM questions
            WHERE module = 'CIVIQUE' AND is_active = true AND civic_notion_id IS NULL
            """, nativeQuery = true)
    long resteATaguer();

    @Modifying
    @Query("UPDATE Question q SET q.civicNotion = :notion WHERE q.id = :questionId")
    int poserNotion(@Param("questionId") UUID questionId,
                    @Param("notion") CivicNotion notion);
}
