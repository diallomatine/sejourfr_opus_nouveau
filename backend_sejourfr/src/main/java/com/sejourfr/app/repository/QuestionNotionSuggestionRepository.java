package com.sejourfr.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Les propositions de tagging d'une machine (V051, enrichies par V054, lot L8).
 *
 * <p>🛑 <b>Aucune de ces lignes ne vaut decision.</b> Le tag qui fait foi est
 * {@code questions.civic_notion_id}, pose par un humain. « Le job propose, un
 * humain valide » ({@code 50_} §6.1.3).
 *
 * <p>🛑 <b>Cette table est creee VIDE</b> et rien dans le depot ne la
 * remplit : la remplir coute un appel LLM paye pour 1 016 questions, et c'est
 * une decision du proprietaire. Les ecritures ci-dessous ne posent QUE des
 * verdicts de relecture ; aucune ne cree de suggestion, et aucune ne touche
 * {@code questions.civic_notion_id}.
 */
@Repository
public interface QuestionNotionSuggestionRepository
        extends JpaRepository<com.sejourfr.app.entity.CivicNotion, UUID> {

    /**
     * Les suggestions de PLUSIEURS questions, en une requete : l'ecran en
     * affiche 25 d'un coup.
     *
     * <p>🛑 <b>{@code LEFT JOIN}, jamais {@code JOIN}</b> (V057). Une
     * suggestion « aucune notion ne convient » porte {@code notion_id NULL} :
     * une jointure interne la ferait disparaitre EN SILENCE, et c'est
     * exactement la ligne qui revele un trou du referentiel. Colonnes
     * {@code n.code} / {@code n.label} nulles dans ce cas — le service les sert
     * telles quelles, sans sentinelle.
     *
     * <p>{@code NULLS LAST} explicite : a confiance egale, « aucune notion »
     * passe apres les notions nommees, et le tri reste deterministe.
     */
    /**
     * 🛑 <b>LA CAMPAGNE COURANTE D'UNE QUESTION</b>, definie une seule fois et
     * partagee par les trois requetes de relecture.
     *
     * <p>Depuis V290, une question peut porter les propositions de PLUSIEURS
     * campagnes : la cle d'unicite inclut le {@code batch_id}, et c'est voulu —
     * une campagne close doit garder sa mesure intacte quand la suivante passe.
     * Mais l'ecran ne montre qu'une proposition, et le verdict humain ne
     * qualifie que celle-la.
     *
     * <p>La campagne courante est <b>la plus recente parmi les APPLICABLES</b>,
     * c'est-a-dire celles dont {@code source_theme_code} vaut encore le theme
     * de la question (V061). Deux filtres qui se completent et qu'il ne faut
     * pas confondre : le theme ecarte ce qui a ete propose pour un AUTRE
     * programme, le {@code batch_id} ecarte une campagne PRECEDENTE faite dans
     * le meme theme. Mesure du 2026-09-11 : le premier seul laissait un verdict
     * tamponner 21 lignes d'une campagne terminee.
     *
     * <p>{@code IS NOT DISTINCT FROM} et non {@code =} : une suggestion sans
     * {@code batch_id} — il en existe d'avant V054 — forme sa propre campagne
     * plutot que de disparaitre de l'ecran.
     */
    @Query(value = """
            WITH courante AS (
                SELECT DISTINCT ON (s.question_id) s.question_id, s.batch_id
                  FROM question_notion_suggestions s
                           JOIN questions q ON q.id = s.question_id
                           JOIN themes t ON t.id = q.theme_id
                 WHERE s.question_id IN (:questionIds)
                   AND s.source_theme_code = t.code
                 ORDER BY s.question_id, s.created_at DESC, s.id
            )
            SELECT s.question_id, n.code, n.label, s.confidence, s.rationale, s.review_verdict
            FROM question_notion_suggestions s
                     JOIN courante c ON c.question_id = s.question_id
                          AND c.batch_id IS NOT DISTINCT FROM s.batch_id
                     LEFT JOIN civic_notions n ON n.id = s.notion_id
            ORDER BY s.question_id, s.confidence DESC, n.code NULLS LAST
            """, nativeQuery = true)
    List<Object[]> parQuestions(@Param("questionIds") Collection<UUID> questionIds);

    /**
     * La suggestion <b>la mieux notee</b> d'une question, sous une forme qui
     * distingue <b>trois</b> cas.
     *
     * <p>🛑 Le retour est une <b>liste d'au plus une ligne</b>
     * {@code (id, notion_id)} et non un {@code Optional<UUID>} : depuis V057,
     * « aucune ligne » et « la meilleure ligne conclut qu'aucune notion ne
     * convient » sont deux situations differentes, et un {@code Optional} vide
     * les confondrait. La colonne {@code s.id} est la pour ca — elle est
     * toujours non nulle, donc la PRESENCE de la ligne se lit sans ambiguite.
     *
     * <ul>
     *   <li>liste vide — aucune campagne n'a tourne sur cette question ;</li>
     *   <li>une ligne, {@code notion_id} nul — le modele a conclu « aucune
     *       notion » ;</li>
     *   <li>une ligne, {@code notion_id} renseigne — la notion proposee.</li>
     * </ul>
     *
     * <p>🛑 C'est la seule reference qui distingue {@code VALIDATED} de
     * {@code CORRECTED}, et elle est lue <b>cote serveur</b> : un client qui
     * annoncerait lui-meme « j'ai validé » pourrait mentir sur la metrique de
     * qualite du modele.
     *
     * <p>Le departage {@code n.code NULLS LAST} rend la lecture deterministe :
     * deux suggestions a la meme confiance ne doivent pas donner deux verdicts
     * selon l'humeur du planificateur.
     *
     * <p>🛑 <b>SEULES LES SUGGESTIONS ENCORE APPLICABLES COMPTENT</b>
     * ({@code source_theme_code} = theme actuel de la question, V061). Une
     * question qui a change de theme garde ses anciennes suggestions : elles
     * pointent vers des notions d'un autre theme, ou concluent « aucune
     * notion » pour un referentiel qui n'est plus le sien. Les laisser
     * concourir, c'est risquer de comparer la notion retenue par l'humain a
     * une proposition faite pour un AUTRE programme — et de rendre un
     * {@code CORRECTED} la ou le modele avait raison, ou l'inverse.
     */
    @Query(value = """
            WITH courante AS (
                SELECT DISTINCT ON (s.question_id) s.question_id, s.batch_id
                  FROM question_notion_suggestions s
                           JOIN questions q ON q.id = s.question_id
                           JOIN themes t ON t.id = q.theme_id
                 WHERE s.question_id = :questionId
                   AND s.source_theme_code = t.code
                 ORDER BY s.question_id, s.created_at DESC, s.id
            )
            SELECT s.id, s.notion_id
            FROM question_notion_suggestions s
                     JOIN courante c ON c.question_id = s.question_id
                          AND c.batch_id IS NOT DISTINCT FROM s.batch_id
                     LEFT JOIN civic_notions n ON n.id = s.notion_id
            ORDER BY s.confidence DESC, n.code NULLS LAST
            LIMIT 1
            """, nativeQuery = true)
    List<Object[]> meilleureSuggestion(@Param("questionId") UUID questionId);

    /**
     * Inscrit le verdict de relecture sur les suggestions <b>encore
     * applicables</b> d'une question.
     *
     * <p>🛑 <b>Le verdict qualifie la relecture de la QUESTION</b>, pas une
     * ligne isolee : il dit ce que la proposition de la machine valait pour
     * cette question. Marquer la seule ligne retenue laisserait les autres a
     * {@code NULL}, c'est-a-dire « jamais relue » — et le reste a relire ne
     * tomberait jamais a zero. Se mesure donc en
     * {@code COUNT(DISTINCT question_id)}, jamais en {@code COUNT(*)}.
     *
     * <p>🛑 <b>MAIS PAS SUR LES SUGGESTIONS PERIMEES</b>
     * ({@code source_theme_code} != theme actuel, V061). Mesure du
     * 2026-09-11 : apres le deplacement de 20 questions et leur reproposition,
     * valider la nouvelle suggestion tamponnait aussi l'ancienne — 21 lignes
     * d'une campagne close se sont retrouvees {@code VALIDATED}, donnant a
     * lire « le modele a dit qu'aucune notion ne convenait, et l'humain l'a
     * suivi » alors que l'humain avait fait exactement l'inverse : deplacer la
     * question et la taguer ailleurs. Une campagne mesuree apres coup en
     * ressortait faussee, et c'est precisement ce qu'une mesure ne doit jamais
     * subir.
     *
     * <p>🛑 <b>La provenance vaut toujours {@code OWNER_REVIEW} ici</b>, et
     * c'est la seule valeur que cet endpoint sache ecrire. Il sert la console
     * d'administration : derriere lui il y a un humain authentifie, dont le
     * jugement est LA reference contre laquelle se mesure la precision du
     * modele. {@code AGENT_REVIEW} ne se pose que par un backfill explicite,
     * quand on sait apres coup qu'un agent a arbitre sous delegation — c'est
     * le cas des 157 verdicts de V062. Cette friction est voulue : une
     * relecture deleguee ne doit jamais pouvoir se faire passer pour celle du
     * proprietaire par simple appel d'API.
     *
     * @return le nombre de suggestions marquees — <b>0 est normal</b> quand
     *         aucune campagne de pre-tagging n'a encore tourne
     */
    @Modifying
    @Query(value = """
            UPDATE question_notion_suggestions s
            SET review_verdict = CAST(:verdict AS varchar),
                reviewed_by = CAST(:relecteurId AS uuid),
                reviewed_at = now(),
                review_source = 'OWNER_REVIEW'
            FROM (
                SELECT DISTINCT ON (x.question_id) x.question_id, x.batch_id
                  FROM question_notion_suggestions x
                           JOIN questions q ON q.id = x.question_id
                           JOIN themes t ON t.id = q.theme_id
                 WHERE x.question_id = :questionId
                   AND x.source_theme_code = t.code
                 ORDER BY x.question_id, x.created_at DESC, x.id
            ) c
            WHERE s.question_id = c.question_id
              AND s.batch_id IS NOT DISTINCT FROM c.batch_id
            """, nativeQuery = true)
    int marquerVerdict(@Param("questionId") UUID questionId,
                       @Param("verdict") String verdict,
                       @Param("relecteurId") UUID relecteurId);
}
