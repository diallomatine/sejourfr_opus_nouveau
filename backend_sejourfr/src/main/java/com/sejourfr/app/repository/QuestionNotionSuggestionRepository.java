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
    @Query(value = """
            SELECT s.question_id, n.code, n.label, s.confidence, s.rationale, s.review_verdict
            FROM question_notion_suggestions s
                     LEFT JOIN civic_notions n ON n.id = s.notion_id
            WHERE s.question_id IN (:questionIds)
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
     */
    @Query(value = """
            SELECT s.id, s.notion_id
            FROM question_notion_suggestions s
                     LEFT JOIN civic_notions n ON n.id = s.notion_id
            WHERE s.question_id = :questionId
            ORDER BY s.confidence DESC, n.code NULLS LAST
            LIMIT 1
            """, nativeQuery = true)
    List<Object[]> meilleureSuggestion(@Param("questionId") UUID questionId);

    /**
     * Inscrit le verdict de relecture sur <b>toutes</b> les suggestions d'une
     * question.
     *
     * <p>🛑 <b>Le verdict qualifie la relecture de la QUESTION</b>, pas une
     * ligne isolee : il dit ce que la proposition de la machine valait pour
     * cette question. Marquer la seule ligne retenue laisserait les autres a
     * {@code NULL}, c'est-a-dire « jamais relue » — et le reste a relire ne
     * tomberait jamais a zero. Se mesure donc en
     * {@code COUNT(DISTINCT question_id)}, jamais en {@code COUNT(*)}.
     *
     * @return le nombre de suggestions marquees — <b>0 est normal</b> quand
     *         aucune campagne de pre-tagging n'a encore tourne
     */
    @Modifying
    @Query(value = """
            UPDATE question_notion_suggestions
            SET review_verdict = CAST(:verdict AS varchar),
                reviewed_by = CAST(:relecteurId AS uuid),
                reviewed_at = now()
            WHERE question_id = :questionId
            """, nativeQuery = true)
    int marquerVerdict(@Param("questionId") UUID questionId,
                       @Param("verdict") String verdict,
                       @Param("relecteurId") UUID relecteurId);
}
