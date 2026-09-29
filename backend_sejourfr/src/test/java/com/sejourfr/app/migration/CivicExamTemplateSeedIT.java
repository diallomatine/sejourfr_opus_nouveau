package com.sejourfr.app.migration;

import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Fige l'invariant de <b>V298</b> : <b>un seul chemin d'examen blanc civique</b>.
 *
 * <p>Avant elle, 20 templates civiques etaient publies et <b>aucun</b> ne pouvait
 * etre conforme a l'arrete du 10 octobre 2025 : leurs regles ne savent viser
 * qu'un <b>theme</b>, pas une <b>unite officielle</b>. Mesure sur les 33 examens
 * de 40 questions reellement passes : <b>0 conforme</b>.
 */
class CivicExamTemplateSeedIT extends AbstractIntegrationTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    @DisplayName("🛑 Un seul template civique publié, et SANS règle : sa composition vient du programme")
    void unSeulCheminDExamenBlancCivique() {
        List<Map<String, Object>> publies = jdbc.queryForList("""
                SELECT t.slug, t.is_free, t.total_questions, t.passing_score, t.duration_seconds,
                       (SELECT count(*) FROM exam_template_rules r
                         WHERE r.exam_template_id = t.id) AS regles
                FROM exam_templates t
                WHERE t.module = 'CIVIQUE' AND t.is_published = true
                """);

        assertThat(publies)
                .as("un seul chemin de composition : un template civique publié de plus "
                        + "voudrait dire qu'un chemin concurrent a survécu (V298)")
                .hasSize(1);

        Map<String, Object> decouverte = publies.get(0);
        assertThat(decouverte.get("slug")).isEqualTo("civique-decouverte");

        // 🛑 SANS RÈGLE, et c'est l'invariant : un template civique sans règle est
        // une FICHE D'OFFRE, et sa composition vient du programme officiel
        // (D-45 option B). Une règle qui revient ici réintroduit un 2ᵉ chemin.
        assertThat(decouverte.get("regles"))
                .as("civique-decouverte est une fiche d'offre, pas une recette de composition")
                .isEqualTo(0L);

        // La promesse publique est tenue : gratuit, et au format de la loi.
        assertThat(decouverte.get("is_free")).isEqualTo(true);
        assertThat(decouverte.get("total_questions")).isEqualTo(CivicExamFormat.QUESTIONS);
        assertThat(decouverte.get("passing_score")).isEqualTo(CivicExamFormat.SEUIL_REUSSITE);
        assertThat(decouverte.get("duration_seconds")).isEqualTo(CivicExamFormat.DUREE_SECONDES);
    }

    @Test
    @DisplayName("🛑 Les 19 templates de composition sont DÉPUBLIÉS, pas supprimés (D-39)")
    void depubliesJamaisSupprimes() {
        // « Ne jamais supprimer une ligne référencée par un attempt. C'est la
        // règle générale, pas une exception pour ce cas. » 15 attempts référencent
        // un template civique : supprimer les lignes casserait l'historique d'un
        // candidat, qui est aussi la source de vérité du freemium.
        Integer depublies = jdbc.queryForObject("""
                SELECT count(*) FROM exam_templates
                WHERE module = 'CIVIQUE' AND is_published = false AND slug <> 'officiel-civique-40q'
                """, Integer.class);

        assertThat(depublies)
                .as("11 Focus mono-thématique + 7 Mix + 1 Marathon, tous conservés en base")
                .isEqualTo(19);
    }

    @Test
    @DisplayName("Aucun template TCF publié n'est sans règle — ce serait une erreur de saisie")
    void aucunTemplateTcfPublieSansRegle() {
        // 🛑 Le garde de `pickQuestionsForTemplate` lève sur ce cas (D-45) : le TCF
        // a sa composition stratifiée par épreuve et ne doit jamais retomber
        // silencieusement sur un « format officiel » qui n'existe pas chez lui.
        // Ce test le vérifie en DONNÉE, pour qu'un seed ne puisse pas l'introduire.
        List<String> fautifs = jdbc.queryForList("""
                SELECT t.slug FROM exam_templates t
                WHERE t.module = 'TCF' AND t.is_published = true
                  AND NOT EXISTS (SELECT 1 FROM exam_template_rules r
                                   WHERE r.exam_template_id = t.id)
                ORDER BY t.slug
                """, String.class);

        assertThat(fautifs).isEmpty();
    }
}
