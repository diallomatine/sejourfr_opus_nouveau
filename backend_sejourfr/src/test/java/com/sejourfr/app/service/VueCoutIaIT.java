package com.sejourfr.app.service;

import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La vue {@code v_ai_usage} (V048) : lecture unifiee du cout des appels IA.
 *
 * <p>Une vue n'a pas de test « metier » — elle n'a pas de comportement. Ce qui
 * doit etre verrouille, c'est qu'elle <b>existe encore</b> et qu'elle
 * <b>couvre toujours ses quatre sources</b>. Une cinquieme famille d'appels
 * payants ajoutee sans etre branchee ici serait invisible dans le suivi des
 * couts : le probleme exact que la vue existe pour empecher.
 */
class VueCoutIaIT extends AbstractIntegrationTest {

    /** Les quatre familles d'appels payants du depot. */
    private static final List<String> FAMILLES_ATTENDUES = List.of(
            "PRODUCTION_EVALUATION", "TRANSCRIPTION",
            "COMPETENCE_ANALYSIS", "DIAGNOSTIC_ANALYSIS");

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    @DisplayName("La vue existe et expose son contrat de colonnes")
    void laVueExposeSonContrat() {
        List<String> colonnes = jdbc.queryForList(
                "SELECT column_name FROM information_schema.columns "
                        + "WHERE table_name = 'v_ai_usage'", String.class);

        assertThat(colonnes).contains(
                "usage_id", "famille", "source", "user_id", "modele",
                "prompt_version", "rubrics_version",
                "tokens_input", "tokens_output", "tokens_input_cache_hit",
                "cout_micro_usd", "cout_legacy_centimes", "occurred_at");
    }

    /**
     * 🛑 Le test qui compte. Il ne verifie pas des lignes — la base de test est
     * vide — mais que la vue SAIT nommer ses quatre familles. Retirer une
     * branche du UNION ferait disparaitre silencieusement un poste de cout.
     */
    @Test
    @DisplayName("Les quatre familles d'appels payants sont couvertes, aucune ne peut disparaître")
    void lesQuatreFamillesSontCouvertes() {
        String definition = jdbc.queryForObject(
                "SELECT pg_get_viewdef('v_ai_usage'::regclass, true)", String.class);

        assertThat(definition).isNotNull();
        FAMILLES_ATTENDUES.forEach(famille ->
                assertThat(definition)
                        .as("la famille %s doit rester une branche de la vue", famille)
                        .contains(famille));
    }

    /**
     * Les deux unites de cout ne se melangent pas : micro-USD (vivant) et
     * centimes d'euro (legacy, plus jamais ecrit). Les sommer produirait un
     * nombre qui ne veut rien dire — la vue les garde separees, et une requete
     * agregee doit pouvoir le constater.
     */
    @Test
    @DisplayName("Les deux unités de coût restent deux colonnes distinctes")
    void deuxUnitesDeuxColonnes() {
        List<Map<String, Object>> lignes = jdbc.queryForList(
                "SELECT famille, sum(cout_micro_usd) AS micro, "
                        + "sum(cout_legacy_centimes) AS centimes "
                        + "FROM v_ai_usage GROUP BY famille");

        // Base de test vide : ce qui est verifie, c'est que la requete est
        // valide et que les deux colonnes s'agregent separement.
        assertThat(lignes).isNotNull();
    }

    @Test
    @DisplayName("La vue est interrogeable par source, sans erreur de type entre ses branches")
    void interrogeableParSource() {
        Integer total = jdbc.queryForObject(
                "SELECT count(*) FROM v_ai_usage WHERE source LIKE 'DIAGNOSTIC%'", Integer.class);

        assertThat(total).isNotNull().isGreaterThanOrEqualTo(0);
    }
}
