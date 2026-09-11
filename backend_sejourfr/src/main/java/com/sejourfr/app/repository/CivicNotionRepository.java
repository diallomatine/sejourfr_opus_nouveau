package com.sejourfr.app.repository;

import com.sejourfr.app.entity.CivicNotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
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
     *
     * <p>🛑 <b>Aucun filtre sur {@code question_type} ici</b>, a la difference
     * de la bascule de grain : ce compte mesure ce qu'une notion <b>porte
     * reellement</b>, pas l'avancement d'un chantier. Une question rattachee a
     * une notion est tirable par la serie ciblee quel que soit son type ;
     * l'ecarter du compte annoncerait une notion plus pauvre qu'elle ne l'est.
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
     * La file de tagging : questions civiques ACTIVES, filtrees par theme et
     * par etat de tagging, ordre stable.
     *
     * <p>🛑 <b>L'ordre est deterministe</b> ({@code created_at, id}) : un
     * tagueur qui pagine 1 016 questions ne doit jamais en revoir une deja
     * traitee ni en sauter une parce que le tri a bouge entre deux pages.
     *
     * <p>{@code theme} nul = tous les themes. {@code tagged} nul = les deux
     * etats ; {@code false} = la file de travail.
     *
     * <p>🛑 <b>La file ne propose que des questions de CONNAISSANCE.</b> Meme
     * regle que la bascule de grain : les notions rattachent des connaissances,
     * les mises en situation relevent des domaines {@code sit_*} ({@code 50_}
     * §6.2). Y faire defiler 176 mises en situation ferait perdre du temps
     * humain sur des questions dont le tag ne compterait dans aucune metrique —
     * et le reste a faire ne tomberait jamais a zero.
     *
     * <p>⚠️ <b>Une question DEJA taguee reste visible quel que soit son
     * type</b> ({@code OR q.civic_notion_id IS NOT NULL}) : si une mise en
     * situation a recu une notion par erreur, l'ecran doit pouvoir la retrouver
     * pour l'effacer. Cacher une erreur n'est pas la corriger.
     *
     * <p>Colonnes : {@code id}, {@code statement}, {@code explanation},
     * {@code theme.code}, {@code difficulty}, {@code notion.code},
     * {@code notion.label}.
     */
    @Query(value = """
            SELECT q.id, q.statement, q.explanation, t.code, q.difficulty, n.code, n.label
            FROM questions q
                     JOIN themes t ON t.id = q.theme_id
                     LEFT JOIN civic_notions n ON n.id = q.civic_notion_id
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND (q.question_type = 'CONNAISSANCE' OR q.civic_notion_id IS NOT NULL)
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

    /**
     * Les propositions des questions de la page, pour que le relecteur voie la
     * question ENTIERE et pas son seul enonce ({@code 20_} §3.2).
     *
     * <p>Une requete pour les 25 questions de la page plutot qu'une par
     * question : c'est la meme raison qu'aux suggestions.
     */
    @Query(value = """
            SELECT c.question_id, c.label, c.is_correct
            FROM choices c
            WHERE c.question_id IN (:questionIds)
            ORDER BY c.question_id, c.display_order, c.id
            """, nativeQuery = true)
    List<Object[]> choixDesQuestions(@Param("questionIds") Collection<UUID> questionIds);

    /**
     * Combien reste-t-il a taguer, tous themes confondus.
     *
     * <p>🛑 <b>Seules les CONNAISSANCE comptent</b>, comme la bascule de grain
     * et comme la file. Compter les 176 mises en situation afficherait un
     * chantier qui ne se termine jamais, et surtout un avancement qui ne
     * correspondrait pas a celui qui declenche le grain notion : deux metriques
     * pour une seule realite, exactement ce qu'on refuse ici.
     */
    @Query(value = """
            SELECT COUNT(*) FROM questions
            WHERE module = 'CIVIQUE' AND is_active = true
              AND question_type = 'CONNAISSANCE'
              AND civic_notion_id IS NULL
            """, nativeQuery = true)
    long resteATaguer();

    /**
     * La question existe-t-elle, et est-elle bien une question civique active ?
     *
     * <p>Necessaire depuis V054 : les verdicts {@code REJECTED} et
     * {@code SKIPPED} ne posent AUCUNE notion, donc {@link #poserNotion} ne les
     * traverse pas et ne peut plus servir de controle d'existence. Sans ce
     * garde-fou, relire une question inexistante rendrait un succes silencieux.
     */
    @Query(value = """
            SELECT EXISTS (
                SELECT 1 FROM questions
                WHERE id = :questionId AND module = 'CIVIQUE' AND is_active = true
            )
            """, nativeQuery = true)
    boolean existeQuestionCivique(@Param("questionId") UUID questionId);

    /**
     * Pose le tag VALIDE sur une question. {@code notion} nul l'efface —
     * « je me suis trompe » doit rester possible sans passer par la base.
     *
     * <p>Requete de mise a jour ciblee plutot qu'un chargement d'entite :
     * {@code Question} est un agregat lourd (theme, passage, medias, choix), et
     * un ecran de tagging en pose des centaines a la suite.
     */
    @Modifying
    @Query("UPDATE Question q SET q.civicNotion = :notion WHERE q.id = :questionId")
    int poserNotion(@Param("questionId") UUID questionId,
                    @Param("notion") CivicNotion notion);
}
