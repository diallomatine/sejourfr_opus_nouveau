package com.sejourfr.app.calibration;

import org.junit.jupiter.api.Test;

import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * GARDE-FOU DE COMPARABILITE des campagnes. Aucun reseau : ce test verrouille
 * l'arithmetique de comparaison, pas le banc lui-meme.
 *
 * <p>Motif : {@code v9-flash} a tourne a {@code retries=9}, {@code v9-pro} a 3 et
 * {@code gpt-5.4} a 1. La colonne « cas perdus » n'y mesurait donc pas la meme
 * chose — et c'est precisement sur elle qu'un choix de modele a ete fait.
 */
class CalibrationReportTest {

    private static Map<String, Object> contexte(int retries, String modele) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rubrics_version", "v9");
        m.put("prompt_version", "v5");
        m.put("provider", "deepseek");
        m.put("modele", modele);
        m.put("corpus", "calibration/golden-set-v1.json");
        m.put("cas", 48);
        m.put("passes", 1);
        m.put("retries", retries);
        return m;
    }

    @Test
    void deux_campagnes_aux_memes_reglages_sont_comparables() {
        assertThat(CalibrationReport.divergencesDeReglage(
            contexte(3, "deepseek-v4-flash"), contexte(3, "deepseek-v4-flash"))).isEmpty();
    }

    @Test
    void un_ecart_de_retries_est_bloquant_et_annonce_en_premier() {
        List<String> divergences = CalibrationReport.divergencesDeReglage(
            contexte(1, "deepseek-v4-flash"), contexte(9, "deepseek-v4-flash"));

        assertThat(divergences).hasSize(1);
        assertThat(divergences.get(0)).startsWith("retries : temoin=9 vs campagne=1");
        assertThat(CalibrationReport.bloquant(divergences)).isTrue();
        assertThat(CalibrationReport.bandeauComparabilite(divergences))
            .contains("CAMPAGNES NON COMPARABLES")
            .contains("retries : temoin=9 vs campagne=1");
    }

    /** Changer de modele est le but d'une comparaison : signale, jamais bloquant. */
    @Test
    void un_ecart_de_modele_avertit_sans_bloquer() {
        List<String> divergences = CalibrationReport.divergencesDeReglage(
            contexte(3, "gpt-5.4"), contexte(3, "deepseek-v4-flash"));

        assertThat(divergences).containsExactly(
            "modele : temoin=deepseek-v4-flash vs campagne=gpt-5.4");
        assertThat(CalibrationReport.bloquant(divergences)).isFalse();
        assertThat(CalibrationReport.bandeauComparabilite(divergences))
            .contains("ATTENTION")
            .doesNotContain("NON COMPARABLES");
    }

    /** Le retries de la campagne courante DOIT etre ecrit dans le rapport. */
    @Test
    void le_rapport_ecrit_et_relit_les_reglages_de_la_campagne() {
        Map<String, Object> contexte = contexte(3, "deepseek-v4-flash");
        // Ecrit sous target/calibration/, comme une vraie campagne.
        Path ecrit = CalibrationReport.ecrire("temoin-de-test", contexte, List.of(run()));

        Map<String, Object> relu = CalibrationReport.contexteDuRapport(ecrit);

        assertThat(relu).containsEntry("retries", 3);
        assertThat(CalibrationReport.divergencesDeReglage(contexte, relu)).isEmpty();
    }

    /**
     * Le rapport publie les DEUX taux separement : ce que nos controles refusent,
     * et ce qu'un candidat subit. L'ancienne cle unique les melangeait.
     */
    @Test
    void le_json_publie_les_deux_taux_distinctement() {
        Map<String, Object> conformite = CalibrationReport.conformiteJson(
            CalibrationMetrics.conformite(List.of(run(), refuseDeuxFois())));

        assertThat(conformite)
            .containsKeys("sorties_refusees", "sorties_refusees_pct", "appels_llm",
                "evaluations_tentees", "evaluations_echouees", "echec_production_pct")
            .doesNotContainKeys("appels_rates", "appels_rates_pct");
    }

    private static CaseRun run() {
        return new CaseRun("c1", "EE_T1", 1, "OK", null, "B1", List.of("B1"), "B1", "B1",
            8.0, Map.of(), 6, 9, "HAUTE", "HAUTE", true, true, List.of(), List.of(), List.of(),
            List.of(), List.of(), true, 1, 0, "m", 1, 1, 1, 1, 1, List.of());
    }

    /** Un cas perdu : 2 tentatives, 4 appels LLM, 4 sorties refusees. */
    private static CaseRun refuseDeuxFois() {
        CaseRun.Tentative tentative = new CaseRun.Tentative(1, false,
            "AiEvaluationException : Sortie LLM invalide apres une tentative de reparation : "
                + "preuve[lexique] doit citer un passage reel de la production",
            2, List.of("PREMIER_APPEL : preuve[lexique] doit citer un passage reel de la production"),
            List.of("PREMIER_APPEL : lexique : citation absente"),
            Map.of("PREUVE_NON_RATTACHEE", 1));
        return new CaseRun("c2", "EO_T2", 1, "ERREUR_APPEL", tentative.erreur(), "B1",
            List.of("B1"), null, null, null, Map.of(), 6, 9, "HAUTE", null, true, null,
            List.of(), List.of(), List.of(), List.of(), List.of(), true, 2, 2, "m",
            null, null, null, 5, 4, List.of(tentative, tentative));
    }
}
