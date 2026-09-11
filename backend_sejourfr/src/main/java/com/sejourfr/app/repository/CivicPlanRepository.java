package com.sejourfr.app.repository;

import com.sejourfr.app.entity.CivicNotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * Les lectures du <b>plan civique</b> (L10).
 *
 * <p>Elle ne porte aucune ecriture, et c'est le point : le plan est un
 * <b>derive relu a chaque appel</b> — aucune table de progression n'existe
 * (cf. {@code CivicLeitnerResolver}).
 *
 * <p>Elle etend {@code JpaRepository<CivicNotion, ...>} par commodite : ses
 * requetes sont natives et ne portent que sur des projections. Aucune n'ecrit.
 */
@Repository
public interface CivicPlanRepository extends JpaRepository<CivicNotion, UUID> {

    /**
     * <b>Toutes</b> les reponses civiques corrigees d'un candidat, dans l'ordre.
     *
     * <p>🛑 <b>Aucune source n'est filtree</b> : diagnostic, series et examens
     * blancs alimentent les memes boites ({@code 20_} §8.2). Ecarter une source
     * rendrait le plan sourd a la moitie de ce que le candidat produit.
     *
     * <p>🛑 <b>L'ordre fait la boite</b> : le repli Leitner rejoue les reponses,
     * et deux reponses inversees donnent deux boites differentes. Le tri est
     * pose ici plutot que laisse a l'appelant — un {@code ORDER BY} oublie se
     * verrait comme un plan qui change sans raison.
     *
     * <p>🛑 {@code a.is_correct IS NOT NULL} : une reponse non corrigee (examen
     * en cours) ne dit rien. La compter comme fausse inventerait une erreur.
     *
     * <p>Colonnes : {@code civic_notion_id} (nullable — question pas encore
     * taguee), {@code theme_id}, {@code is_correct}, {@code answered_at}.
     */
    @Query(value = """
            SELECT q.civic_notion_id, q.theme_id, a.is_correct, a.answered_at
            FROM answers a
                     JOIN attempt_questions aq ON aq.id = a.attempt_question_id
                     JOIN attempts at ON at.id = aq.attempt_id
                     JOIN questions q ON q.id = aq.question_id
            WHERE at.user_id = :userId
              AND q.module = 'CIVIQUE'
              AND a.is_correct IS NOT NULL
            ORDER BY a.answered_at, a.id
            """, nativeQuery = true)
    List<Object[]> reponsesCiviques(@Param("userId") UUID userId);

    /**
     * L'avancement du tagging, <b>par theme</b> : questions de CONNAISSANCE
     * actives, et combien sont taguees.
     *
     * <p>C'est ce couple qui fait basculer un theme du grain THEME au grain
     * NOTION ({@code 20_} §3.3). 🛑 <b>Par theme, jamais globalement</b> : un
     * theme tague a 90 % n'a pas a attendre celui qui est a 10 %.
     *
     * <p>🛑 <b>SEULES LES QUESTIONS DE CONNAISSANCE COMPTENT — c'est une REGLE,
     * pas un reglage.</b> Les connaissances se rattachent a des <b>notions</b> ;
     * les 176 <b>mises en situation</b> relevent d'un axe pedagogique distinct
     * et seront suivies par leurs <b>domaines de situation</b> ({@code 50_}
     * §6.2, codes {@code sit_*}). Elles ne recoivent donc jamais de
     * {@code civic_notion_id}, et une mise en situation non taguee ne doit
     * jamais empecher l'activation du grain notion.
     *
     * <p>Les compter melangeait deux metriques qui ne mesurent pas la meme
     * chose, et le coût etait mesure : trois themes sur cinq plafonnaient a
     * 77,9 / 77,9 / 79,0 % et <b>n'auraient JAMAIS franchi le seuil de 80 %</b>,
     * meme avec 100 % des questions de connaissance taguees. Le grain notion
     * leur etait inaccessible par construction.
     */
    @Query(value = """
            SELECT t.id,
                   COUNT(*),
                   COUNT(q.civic_notion_id)
            FROM questions q
                     JOIN themes t ON t.id = q.theme_id
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND q.question_type = 'CONNAISSANCE'
            GROUP BY t.id
            """, nativeQuery = true)
    List<Object[]> taggageParTheme();

    /**
     * Combien de questions <b>jouables</b> par notion pour une mention donnee.
     *
     * <p>🛑 <b>Par mention</b>, jamais un total global : une notion peut etre
     * pleinement dotee pour un candidat NAT et vide pour un CSP, et c'est
     * exactement ce que {@code 20_} §3.4 appelle {@code insufficient_content}.
     *
     * <p>🛑 <b>Ici, PAS de filtre sur {@code question_type}</b> — contrairement
     * a {@link #taggageParTheme()}, et pour une raison precise : ce compte est
     * une <b>dotation</b>, pas une couverture de tagging. Il doit rendre
     * exactement ce que {@link #tirageSerieCiblee} peut tirer, et ce tirage ne
     * connait que {@code civic_notion_id}. Ecarter un type que le tirage
     * accepte degraderait la {@code CivicDotation} d'une notion qui remplit
     * pourtant sa serie.
     */
    @Query(value = """
            SELECT q.civic_notion_id, COUNT(*)
            FROM questions q
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND q.civic_notion_id IS NOT NULL
              AND q.difficulty = CAST(:mention AS varchar)
            GROUP BY q.civic_notion_id
            """, nativeQuery = true)
    List<Object[]> questionsParNotion(@Param("mention") String mention);

    /**
     * Meme compte, au grain theme : de quoi savoir si une serie est jouable.
     *
     * <p>🛑 <b>Meme raison qu'au grain notion : aucun filtre de type.</b> Une
     * serie ciblee sur un theme tire aussi bien une mise en situation qu'une
     * connaissance — la dotation doit refleter le tirage, pas la couverture.
     */
    @Query(value = """
            SELECT q.theme_id, COUNT(*)
            FROM questions q
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND q.difficulty = CAST(:mention AS varchar)
            GROUP BY q.theme_id
            """, nativeQuery = true)
    List<Object[]> questionsParTheme(@Param("mention") String mention);

    /**
     * Le tirage d'une <b>serie ciblee</b> ({@code 20_} §6 bloc 2).
     *
     * <p>🛑 <b>Ce n'est pas un tirage au hasard dans le theme.</b> L'ordre porte
     * l'intention du plan : ce que le candidat a <b>rate en dernier</b> vient
     * d'abord, puis ce qu'il n'a <b>jamais vu</b>, puis le reste. C'est ce qui
     * distingue une serie ciblee d'un lot — sans cet ordre, « travailler Le
     * Parlement » redonnerait les memes questions deja reussies.
     *
     * <p>La cible est une <b>notion</b> ({@code notionId} pose) ou un
     * <b>theme</b> ({@code themeId} pose) : le mode degrade joue exactement la
     * meme requete, a un cran de precision pres.
     *
     * <p>{@code random()} departage a l'interieur d'un rang : deux series
     * consecutives sur la meme cible ne redonnent pas la meme liste.
     */
    @Query(value = """
            SELECT q.id
            FROM questions q
                     LEFT JOIN LATERAL (
                         SELECT a.is_correct
                         FROM answers a
                                  JOIN attempt_questions aq ON aq.id = a.attempt_question_id
                                  JOIN attempts at ON at.id = aq.attempt_id
                         WHERE aq.question_id = q.id
                           AND at.user_id = :userId
                           AND a.is_correct IS NOT NULL
                         ORDER BY a.answered_at DESC, a.id DESC
                         LIMIT 1
                     ) derniere ON true
            WHERE q.module = 'CIVIQUE'
              AND q.is_active = true
              AND q.difficulty = CAST(:mention AS varchar)
              AND (CAST(:notionId AS uuid) IS NULL OR q.civic_notion_id = CAST(:notionId AS uuid))
              AND (CAST(:themeId AS uuid) IS NULL OR q.theme_id = CAST(:themeId AS uuid))
            ORDER BY CASE
                         WHEN derniere.is_correct IS FALSE THEN 0
                         WHEN derniere.is_correct IS NULL THEN 1
                         ELSE 2
                     END,
                     random()
            LIMIT :taille
            """, nativeQuery = true)
    List<UUID> tirageSerieCiblee(@Param("userId") UUID userId,
                                 @Param("mention") String mention,
                                 @Param("notionId") UUID notionId,
                                 @Param("themeId") UUID themeId,
                                 @Param("taille") int taille);
}
