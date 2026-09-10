package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AiEvaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lecture de la vue {@code v_ai_usage} (V048), <b>seule autorite de lecture du
 * cout IA</b>.
 *
 * <p>🛑 <b>Requetes natives, et c'est voulu</b> : {@code v_ai_usage} est une
 * VUE, pas une table. La mapper en entite JPA creerait un agregat que rien ne
 * peut ecrire, avec un {@code @Id} qui n'est unique que par accident (les
 * quatre sources ont chacune leurs identifiants). On lit des agregats, on ne
 * materialise aucune ligne.
 *
 * <p>🛑 <b>Les deux colonnes de cout ne sont JAMAIS additionnees entre elles</b>
 * — deux unites, deux devises, deux epoques. Elles sont sommees separement et
 * remontent cote a cote.
 *
 * <p>🛑 <b>{@code COUNT} des lignes SANS cout</b> : un cout inconnu vaut
 * {@code null}, jamais zero. Sans ce compte, un total bas se lit « l'IA ne
 * coute presque rien » alors qu'il se lit « on ne sait pas ».
 */
@Repository
public interface AiUsageRepository extends JpaRepository<AiEvaluation, UUID> {

    /** Colonnes, dans l'ordre : cle, appels, sansCout, tokensIn, tokensOut, cacheHit, microUsd, centimes. */
    String COLONNES = """
            COUNT(*),
            COUNT(*) FILTER (WHERE cout_micro_usd IS NULL AND cout_legacy_centimes IS NULL),
            SUM(tokens_input),
            SUM(tokens_output),
            SUM(tokens_input_cache_hit),
            SUM(cout_micro_usd),
            SUM(cout_legacy_centimes)
            """;

    @Query(value = "SELECT " + COLONNES + """
            FROM v_ai_usage
            WHERE occurred_at >= :from AND occurred_at < :to
            """, nativeQuery = true)
    List<Object[]> total(@Param("from") Instant from, @Param("to") Instant to);

    @Query(value = "SELECT famille, " + COLONNES + """
            FROM v_ai_usage
            WHERE occurred_at >= :from AND occurred_at < :to
            GROUP BY famille
            ORDER BY COALESCE(SUM(cout_micro_usd), 0) DESC, famille
            """, nativeQuery = true)
    List<Object[]> parFamille(@Param("from") Instant from, @Param("to") Instant to);

    @Query(value = "SELECT source, " + COLONNES + """
            FROM v_ai_usage
            WHERE occurred_at >= :from AND occurred_at < :to
            GROUP BY source
            ORDER BY COALESCE(SUM(cout_micro_usd), 0) DESC, source
            """, nativeQuery = true)
    List<Object[]> parSource(@Param("from") Instant from, @Param("to") Instant to);

    /**
     * Par modele. {@code COALESCE} sur le libelle : un appel dont le modele n'a
     * pas ete enregistre existe quand meme et doit apparaitre — le faire
     * disparaitre d'un tableau de couts serait pire que l'y voir « inconnu ».
     */
    @Query(value = "SELECT COALESCE(modele, '(inconnu)'), " + COLONNES + """
            FROM v_ai_usage
            WHERE occurred_at >= :from AND occurred_at < :to
            GROUP BY COALESCE(modele, '(inconnu)')
            ORDER BY COALESCE(SUM(cout_micro_usd), 0) DESC, 1
            """, nativeQuery = true)
    List<Object[]> parModele(@Param("from") Instant from, @Param("to") Instant to);

    /**
     * Ce que les appels de DIAGNOSTIC ont coute sur la fenetre, en micro-USD.
     *
     * <p>🛑 <b>On ne somme QUE les micro-USD.</b> Melanger les deux unites dans
     * une moyenne serait exactement l'erreur que V048 interdit. Les lignes
     * anciennes, en centimes d'euro, n'entrent pas ici — la moyenne porte donc
     * sur la periode ou le cout est reellement connu, et c'est mieux qu'une
     * moyenne fausse.
     */
    @Query(value = """
            SELECT SUM(cout_micro_usd)
            FROM v_ai_usage
            WHERE occurred_at >= :from AND occurred_at < :to
              AND source LIKE 'DIAGNOSTIC%'
            """, nativeQuery = true)
    Long coutDiagnosticsMicroUsd(@Param("from") Instant from, @Param("to") Instant to);

    /**
     * Combien de diagnostics ont ete <b>menes a terme</b> sur la fenetre.
     *
     * <p>🛑 La fenetre porte sur la <b>cloture</b>, pas sur chaque appel : un
     * diagnostic commence le 30 et fini le 2 compte une fois, du cote ou il
     * s'est termine.
     *
     * <p>Le rapport des deux est un <b>cout moyen d'ensemble</b> sur la
     * fenetre, pas une moyenne de couts par session : la vue ne porte pas
     * l'identifiant de soumission, et l'y ajouter demanderait de reecrire une
     * vue livree. Cf. {@code docs/review_all/60_DECISIONS_IMPLEMENTATION.md}.
     */
    @Query(value = """
            SELECT COUNT(*)
            FROM diagnostic_sessions
            WHERE status = 'COMPLETED'
              AND completed_at >= :from AND completed_at < :to
            """, nativeQuery = true)
    long diagnosticsClos(@Param("from") Instant from, @Param("to") Instant to);
}
