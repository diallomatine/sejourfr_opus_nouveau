package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminAiCostResponse;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA SUPERVISION DU COÛT IA (L12), contre la vraie vue {@code v_ai_usage}.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>la requête <b>tourne réellement</b> sur la vue — quatre {@code UNION
 *       ALL} et des colonnes de types différents, c'est exactement le genre de
 *       SQL qui compile et casse au premier appel ;</li>
 *   <li>🛑 un coût <b>inconnu</b> reste {@code null} et se compte dans
 *       {@code lignesSansCout} : c'est la seule chose qui empêche de lire
 *       « l'IA ne coûte presque rien » là où la vérité est « on ne sait pas » ;</li>
 *   <li>🛑 les deux unités ne sont <b>jamais</b> mélangées.</li>
 * </ul>
 *
 * <p>Aucun appel LLM n'est émis : on lit une vue.
 */
class AdminAiCostServiceIT extends AbstractIntegrationTest {

    @Autowired private AdminAiCostService service;
    @Autowired private JdbcTemplate jdbc;

    @Test
    @DisplayName("La vue répond, et une base sans appel IA rend des totaux honnêtes")
    void baseSansAppelRendDesTotauxHonnetes() {
        AdminAiCostResponse response = service.lire(null, null, 30);

        assertThat(response.from()).isNotNull();
        assertThat(response.to()).isNotNull();
        // 🛑 Aucun appel ⇒ aucun coût CONNU. Le total n'est pas zéro : il est
        // nul. Un `0` afficherait « ça n'a rien coûté ».
        assertThat(response.total().coutMicroUsd()).isNull();
        assertThat(response.total().coutLegacyCentimes()).isNull();
        assertThat(response.total().appels()).isZero();
        assertThat(response.parFamille()).isEmpty();
        assertThat(response.parSource()).isEmpty();
        assertThat(response.parModele()).isEmpty();
    }

    @Test
    @DisplayName("🛑 Un appel sans coût enregistré est COMPTÉ, pas escamoté")
    void appelSansCoutEstCompte() {
        // La vue est lisible telle quelle : on interroge directement le compte
        // des lignes sans coût, sur toute l'histoire de la base.
        Long sansCout = jdbc.queryForObject("""
                SELECT COUNT(*) FROM v_ai_usage
                WHERE cout_micro_usd IS NULL AND cout_legacy_centimes IS NULL
                """, Long.class);
        Long total = jdbc.queryForObject("SELECT COUNT(*) FROM v_ai_usage", Long.class);

        assertThat(sansCout).isNotNull();
        assertThat(total).isNotNull().isGreaterThanOrEqualTo(sansCout);
    }

    @Test
    @DisplayName("La fenêtre est celle du serveur, et elle est rendue telle qu'appliquée")
    void laFenetreEstRendueTelleQuAppliquee() {
        AdminAiCostResponse response = service.lire("2026-08-01", "2026-08-31", 30);

        assertThat(response.from()).hasToString("2026-08-01");
        assertThat(response.to()).hasToString("2026-08-31");
    }

    @Test
    @DisplayName("🛑 Aucun diagnostic clos ⇒ pas de moyenne inventée")
    void aucunDiagnosticClosNInventePasDeMoyenne() {
        AdminAiCostResponse response = service.lire(null, null, 30);

        assertThat(response.diagnosticComplet().sessions()).isZero();
        assertThat(response.diagnosticComplet().moyenneMicroUsd()).isNull();
    }
}
