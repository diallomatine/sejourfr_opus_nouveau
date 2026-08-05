package com.sejourfr.app.calibration;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille l'arithmetique du banc de mesure : accord de niveau, ecart signe
 * (severite), pieges, stabilite, conformite. Aucun reseau, aucun LLM — ces
 * calculs doivent rester justes independamment de la campagne.
 */
class CalibrationMetricsTest {

    private static CaseRun run(String id, String groupe, int passe, String attendu, List<String> tolerance,
                               String obtenu, Double note, double min, double max) {
        return new CaseRun(id, groupe, passe, "OK", null, attendu, tolerance, obtenu, obtenu,
            note, Map.of(), min, max, "HAUTE", "HAUTE", true, true, List.of(), List.of(), List.of(),
            List.of(), List.of(), true, 1, 0, "modele-test", 10, 20, 1, 5);
    }

    @Test
    void accord_exact_et_tolerance_se_distinguent() {
        CaseRun exact = run("c1", "EE_T1", 1, "B1", List.of("B1"), "B1", 13.0, 11, 15);
        CaseRun voisin = run("c2", "EE_T1", 1, "A2", List.of("A2", "B1"), "B1", 12.0, 7, 11);
        CaseRun hors = run("c3", "EE_T1", 1, "A1", List.of("A1", "A2"), "B2", 17.0, 2, 6);

        CalibrationMetrics.Agregat a = CalibrationMetrics.agregat("t", List.of(exact, voisin, hors));

        assertThat(a.accordExact()).isEqualTo(1);
        assertThat(a.accordTolerance()).isEqualTo(2);
        assertThat(a.noteDansFourchette()).isEqualTo(1);
    }

    @Test
    void ecart_negatif_quand_l_ia_note_au_dessus_de_la_reference() {
        // Convention backend : ecart = reference - IA. Reference centree sur 9,
        // note IA 14 -> -5 ; deborde la borne haute de 3 -> -3. IA trop indulgente.
        CaseRun indulgent = run("c1", "EE_T1", 1, "A2", List.of("A2"), "B1", 14.0, 7, 11);
        CalibrationMetrics.Agregat a = CalibrationMetrics.agregat("t", List.of(indulgent));

        assertThat(a.ecartCentreMoyen()).isEqualTo(-5.0);
        assertThat(a.ecartFourchetteMoyen()).isEqualTo(-3.0);
        assertThat(a.ecartNiveauMoyen()).isEqualTo(-1.0);
    }

    @Test
    void ecart_positif_quand_l_ia_note_en_dessous_de_la_reference() {
        CaseRun severe = run("c1", "EE_T1", 1, "B1", List.of("B1"), "A2", 8.0, 11, 15);
        CalibrationMetrics.Agregat a = CalibrationMetrics.agregat("t", List.of(severe));

        assertThat(a.ecartCentreMoyen()).isEqualTo(5.0);
        assertThat(a.ecartFourchetteMoyen()).isEqualTo(3.0);
        assertThat(a.ecartNiveauMoyen()).isEqualTo(1.0);
    }

    @Test
    void note_dans_la_fourchette_donne_un_ecart_de_borne_nul() {
        CaseRun juste = run("c1", "EE_T1", 1, "B1", List.of("B1"), "B1", 12.0, 11, 15);
        assertThat(juste.ecartFourchette()).isZero();
        assertThat(juste.ecartCentre()).isEqualTo(1.0);
    }

    @Test
    void un_run_en_erreur_n_est_pas_exploitable_et_compte_comme_invalide() {
        CaseRun erreur = new CaseRun("c1", "EE_T1", 1, "ERREUR_APPEL", "timeout", "B1", List.of("B1"),
            null, null, null, Map.of(), 11, 15, "HAUTE", null, true, null, List.of(), List.of(), List.of(),
            List.of(), List.of(), true, 3, 3, "modele-test", null, null, null, 5);

        assertThat(erreur.exploitable()).isFalse();
        CalibrationMetrics.Conformite c = CalibrationMetrics.conformite(List.of(erreur));
        assertThat(c.erreurAppel()).isEqualTo(1);
        assertThat(c.casPerdus()).isEqualTo(1);
        assertThat(c.pctAppelsRates()).isEqualTo(100.0);
    }

    @Test
    void le_court_circuit_de_validite_reste_une_reponse_du_systeme() {
        CaseRun bloque = new CaseRun("c1", "EE_T3", 1, "VALIDITE_SERVEUR", null, "A1_NON_ATTEINT",
            List.of("A1_NON_ATTEINT"), "A1_NON_ATTEINT", null, 0.0, Map.of(), 0, 0, "HAUTE", "FAIBLE",
            false, false, List.of(), List.of(), List.of("HORS_SUJET"), List.of(), List.of(),
            false, 0, 0, "validation-serveur", 0, 0, 0, 1);

        assertThat(bloque.exploitable()).isTrue();
        assertThat(bloque.accordExact()).isTrue();
        CalibrationMetrics.Conformite c = CalibrationMetrics.conformite(List.of(bloque));
        assertThat(c.validiteServeur()).isEqualTo(1);
        assertThat(c.pctAppelsRates()).isZero();
    }

    @Test
    void un_piege_est_rate_vers_le_haut_quand_le_niveau_depasse_la_tolerance() {
        CaseRun surevalue = new CaseRun("p1", "EE_T3", 1, "OK", null, "A1_NON_ATTEINT",
            List.of("A1_NON_ATTEINT"), "A2", "A2", 9.0, Map.of(), 0, 0, "HAUTE", "HAUTE", false, false,
            List.of(), List.of(), List.of("HORS_SUJET"), List.of(), List.of(), true, 1, 0, "m", 1, 1, 1, 1);

        List<CalibrationMetrics.PiegeResultat> p = CalibrationMetrics.pieges(List.of(surevalue));

        assertThat(p).hasSize(1);
        assertThat(p.get(0).evite()).isFalse();
        assertThat(p.get(0).sens()).isEqualTo("SUR");
    }

    @Test
    void un_piege_est_evite_quand_niveau_et_note_tiennent_dans_la_zone() {
        CaseRun bon = new CaseRun("p1", "EO_T2", 1, "OK", null, "A2", List.of("A2", "B1"), "B1", "B1",
            12.0, Map.of(), 9, 13, "MOYENNE", "MOYENNE", true, true, List.of(), List.of(),
            List.of("TRANSCRIPTION_BRUITEE"), List.of(), List.of(), true, 1, 0, "m", 1, 1, 1, 1);

        assertThat(CalibrationMetrics.pieges(List.of(bon)).get(0).evite()).isTrue();
    }

    @Test
    void la_stabilite_mesure_l_amplitude_de_note_et_le_nombre_de_niveaux() {
        List<CaseRun> runs = List.of(
            run("c1", "EE_T1", 1, "B1", List.of("B1"), "B1", 12.0, 11, 15),
            run("c1", "EE_T1", 2, "B1", List.of("B1"), "A2", 10.0, 11, 15),
            run("c1", "EE_T1", 3, "B1", List.of("B1"), "B1", 13.0, 11, 15));

        List<CalibrationMetrics.Stabilite> s = CalibrationMetrics.stabilite(runs);

        assertThat(s).hasSize(1);
        assertThat(s.get(0).amplitude()).isEqualTo(3.0);
        assertThat(s.get(0).niveauxDistincts()).isEqualTo(2);
    }

    @Test
    void un_cas_joue_une_seule_fois_ne_produit_pas_de_mesure_de_stabilite() {
        assertThat(CalibrationMetrics.stabilite(
            List.of(run("c1", "EE_T1", 1, "B1", List.of("B1"), "B1", 12.0, 11, 15)))).isEmpty();
    }

    @Test
    void la_confiance_distingue_le_sur_et_le_sous_confiant() {
        CaseRun plusSur = new CaseRun("c1", "EE_T1", 1, "OK", null, "B1", List.of("B1"), "B1", "B1",
            12.0, Map.of(), 11, 15, "MOYENNE", "HAUTE", true, true, List.of(), List.of(), List.of(),
            List.of(), List.of(), true, 1, 0, "m", 1, 1, 1, 1);
        CaseRun moinsSur = new CaseRun("c2", "EE_T1", 1, "OK", null, "B1", List.of("B1"), "B1", "B1",
            12.0, Map.of(), 11, 15, "HAUTE", "FAIBLE", true, true, List.of(), List.of(), List.of(),
            List.of(), List.of(), true, 1, 0, "m", 1, 1, 1, 1);

        CalibrationMetrics.ConfianceResultat c = CalibrationMetrics.confiance(List.of(plusSur, moinsSur));

        assertThat(c.evalues()).isEqualTo(2);
        assertThat(c.plusSur()).isEqualTo(1);
        assertThat(c.moinsSur()).isEqualTo(1);
        assertThat(c.accord()).isZero();
    }

    @Test
    void le_rapprochement_des_points_oublies_tolere_les_variantes_de_formulation() {
        assertThat(CalibrationMetrics.detecte("date ou moment de restitution du vélo",
            List.of("Moment de restitution du velo non precise"))).isTrue();
        assertThat(CalibrationMetrics.detecte("description du logement",
            List.of("Invitation formulée"))).isFalse();
    }

    /** Cas non mesure, avec le message d'erreur que le pipeline aurait produit. */
    private static CaseRun perdu(String id, String erreur) {
        return new CaseRun(id, "EO_T2", 1, "ERREUR_APPEL", erreur, "B1", List.of("B1"),
            null, null, null, Map.of(), 6, 9, "HAUTE", null, true, null, List.of(), List.of(),
            List.of(), List.of(), List.of(), true, 3, 3, "m", null, null, null, 5);
    }

    @Test
    void chaque_cas_perdu_est_rattache_a_son_motif() {
        assertThat(CalibrationMetrics.motifPerte(perdu("c1",
            "AiEvaluationException : tool_call.arguments non desorialisable : Unexpected end-of-input")))
            .isEqualTo(CalibrationMetrics.MotifPerte.TRONCATURE_JSON);
        assertThat(CalibrationMetrics.motifPerte(perdu("c2",
            "AiEvaluationException : Pas de tool_calls dans la reponse DeepSeek (finish_reason=length)")))
            .isEqualTo(CalibrationMetrics.MotifPerte.TRONCATURE_JSON);
        assertThat(CalibrationMetrics.motifPerte(perdu("c3",
            "AiEvaluationException : Sortie LLM invalide apres une tentative de reparation : "
                + "preuve[lexique] doit citer un passage reel de la production")))
            .isEqualTo(CalibrationMetrics.MotifPerte.REJET_PREUVE);
        assertThat(CalibrationMetrics.motifPerte(perdu("c4",
            "AiEvaluationException : Sortie LLM invalide apres une tentative de reparation : "
                + "suggestions fonde le feedback oral sur un element non evaluable")))
            .isEqualTo(CalibrationMetrics.MotifPerte.GARDE_FOU_ORAL);
        assertThat(CalibrationMetrics.motifPerte(perdu("c5",
            "AiEvaluationException : DeepSeek eval indisponible apres plusieurs tentatives")))
            .isEqualTo(CalibrationMetrics.MotifPerte.FOURNISSEUR_INDISPONIBLE);
        assertThat(CalibrationMetrics.motifPerte(perdu("c6", "IllegalStateException : bizarre")))
            .isEqualTo(CalibrationMetrics.MotifPerte.AUTRE);
    }

    @Test
    void un_cas_mesure_ne_porte_aucun_motif_de_perte() {
        assertThat(CalibrationMetrics.motifPerte(
            run("c1", "EE_T1", 1, "B1", List.of("B1"), "B1", 8.0, 6, 9))).isNull();
    }

    @Test
    void la_conformite_ventile_les_pertes_et_expose_les_deux_taux() {
        // Le defaut que cette ventilation rend visible : trois cas perdus par
        // troncature JSON tombaient dans « erreur d'appel » pendant que le
        // rapport annoncait 0 % de sortie invalide.
        List<CaseRun> runs = List.of(
            run("ok1", "EE_T1", 1, "B1", List.of("B1"), "B1", 8.0, 6, 9),
            run("ok2", "EE_T1", 1, "B1", List.of("B1"), "B1", 8.0, 6, 9),
            perdu("t1", "AiEvaluationException : tool_call.arguments non desorialisable"),
            perdu("t2", "AiEvaluationException : tool_call.arguments non desorialisable"),
            perdu("p1", "AiEvaluationException : preuve[lexique] doit citer un passage reel "
                + "de la production"));

        CalibrationMetrics.Conformite c = CalibrationMetrics.conformite(runs);

        assertThat(c.casPerdus()).isEqualTo(3);
        assertThat(c.casNonMesures()).isEqualTo(3);
        assertThat(c.pctCasPerdus()).isEqualTo(60.0);
        assertThat(c.pctSortieInvalide()).isZero();
        assertThat(c.motif(CalibrationMetrics.MotifPerte.TRONCATURE_JSON)).isEqualTo(2);
        assertThat(c.motif(CalibrationMetrics.MotifPerte.REJET_PREUVE)).isEqualTo(1);
        assertThat(c.motif(CalibrationMetrics.MotifPerte.AUTRE)).isZero();
        assertThat(CalibrationReport.motifs(c))
            .isEqualTo("troncature JSON (plafond de tokens) 2 · rejet de preuve 1");
    }

    @Test
    void une_sortie_structurellement_incomplete_compte_dans_les_cas_non_mesures() {
        CaseRun incomplet = new CaseRun("c1", "EE_T1", 1, "SORTIE_INVALIDE", null, "B1",
            List.of("B1"), "B1", "B1", 8.0, Map.of(), 6, 9, "HAUTE", "HAUTE", true, true,
            List.of(), List.of(), List.of(), List.of("confiance"), List.of(), true, 1, 0,
            "m", 1, 1, 1, 1);

        CalibrationMetrics.Conformite c = CalibrationMetrics.conformite(List.of(incomplet));

        assertThat(c.sortieInvalide()).isEqualTo(1);
        assertThat(c.pctSortieInvalide()).isEqualTo(100.0);
        assertThat(c.casPerdus()).isZero();
        assertThat(c.casNonMesures()).isEqualTo(1);
        assertThat(c.motif(CalibrationMetrics.MotifPerte.SORTIE_INCOMPLETE)).isEqualTo(1);
    }

    @Test
    void le_rapport_json_porte_les_deux_taux_et_la_ventilation() {
        Map<String, Object> json = CalibrationReport.conformiteJson(
            CalibrationMetrics.conformite(List.of(
                run("ok1", "EE_T1", 1, "B1", List.of("B1"), "B1", 8.0, 6, 9),
                perdu("t1", "AiEvaluationException : tool_call.arguments non desorialisable"))));

        assertThat(json).containsKeys("sortie_invalide_pct", "cas_perdus_pct",
            "cas_non_mesures_pct", "motifs_perte", "motifs_perte_lisible");
        assertThat(json.get("cas_perdus_pct")).isEqualTo(50.0);
        assertThat(json.get("sortie_invalide_pct")).isEqualTo(0.0);
    }

    @Test
    void le_corpus_de_reference_est_lisible_et_complet() {
        List<GoldenSet.Cas> corpus = GoldenSet.load();

        assertThat(corpus).hasSize(48);
        assertThat(corpus).allSatisfy(c -> {
            assertThat(c.id()).isNotBlank();
            assertThat(c.consigne()).isNotBlank();
            assertThat(c.production()).isNotBlank();
            assertThat(c.attendu().niveau()).isNotNull();
            assertThat(c.attendu().tolerance()).contains(c.attendu().niveau());
            assertThat(c.attendu().noteMin()).isLessThanOrEqualTo(c.attendu().noteMax());
        });
        assertThat(corpus.stream().map(GoldenSet.Cas::groupe).distinct()).hasSize(6);
    }
}
