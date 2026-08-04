package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * Verifie la math CECRL des epreuves productives :
 * <ul>
 *   <li>{@code niveau_cecrl} par soumission derive de lexique+morphosyntaxe
 *       (cf. {@link ProductionBilanService#computeNiveau}) ;</li>
 *   <li>bilan d'epreuve en examen = moyenne ponderee des competences des 3
 *       taches (poids 1/2/3) (cf. {@link ProductionBilanService#bilanEpreuve}).</li>
 * </ul>
 */
class ProductionBilanServiceTest {

    private static final List<String> SOURCE = List.of("lexique", "morphosyntaxe");
    /** Seuils par defaut : B2≥15, B1≥12, A2≥7 ; poids taches 1/2/3. */
    private static final ProductionEvaluationProperties.NiveauCecrl SEUILS =
        new ProductionEvaluationProperties.NiveauCecrl();

    private static Map<String, Object> score(String code, Number note) {
        return Map.of("code", code, "note_sur_20", note, "commentaire", "x");
    }

    // ------------------------------------------------------------------------
    // niveau_cecrl par soumission (lexique + morphosyntaxe)
    // ------------------------------------------------------------------------

    private static NiveauCecrl niveau(List<Map<String, Object>> scores, BigDecimal note) {
        return ProductionBilanService.computeNiveau(scores, SOURCE, note, SEUILS);
    }

    @Test
    void niveau_lexique10_morpho12_donne_A2() {
        // competence = (10 + 12) / 2 = 11 -> A2
        List<Map<String, Object>> s = List.of(score("lexique", 10), score("morphosyntaxe", 12));
        assertThat(niveau(s, new BigDecimal("11"))).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void niveau_lexique15_morpho14_donne_B1() {
        // 14.5 -> B1 (< 15)
        List<Map<String, Object>> s = List.of(score("lexique", 15), score("morphosyntaxe", 14));
        assertThat(niveau(s, new BigDecimal("15"))).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void niveau_lexique17_morpho16_donne_B2() {
        // 16.5 -> B2
        List<Map<String, Object>> s = List.of(score("lexique", 17), score("morphosyntaxe", 16));
        assertThat(niveau(s, new BigDecimal("17"))).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void niveau_lexique16_morpho16_donne_B2_corrige_le_B1_errone() {
        // 16 -> B2 (cas de la capture : le LLM renvoyait B1)
        List<Map<String, Object>> s = List.of(score("lexique", 16), score("morphosyntaxe", 16));
        assertThat(niveau(s, new BigDecimal("16"))).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void niveau_hors_sujet_note_zero_donne_A1_NON_ATTEINT() {
        List<Map<String, Object>> s = List.of(score("lexique", 0), score("morphosyntaxe", 0));
        assertThat(niveau(s, BigDecimal.ZERO)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    @Test
    void niveau_plafonne_a_B2_meme_a_20() {
        List<Map<String, Object>> s = List.of(score("lexique", 20), score("morphosyntaxe", 20));
        assertThat(niveau(s, new BigDecimal("20"))).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void niveau_critere_manquant_fallback_sur_note_globale_sans_crash() {
        // morphosyntaxe absent -> fallback competence = note_globale (moyenne ponderee) = 8 -> A2
        List<Map<String, Object>> s = List.of(score("lexique", 10), score("pertinence", 6));
        assertThat(niveau(s, new BigDecimal("8"))).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void niveau_criteres_et_note_absents_retourne_null() {
        assertThat(niveau(List.of(score("pertinence", 12)), null)).isNull();
    }

    // ------------------------------------------------------------------------
    // bilan d'epreuve en examen (moyenne ponderee des competences, poids 1/2/3)
    // ------------------------------------------------------------------------

    private final ProductionBilanService service = new ProductionBilanService(
        mock(AiEvaluationManager.class),
        new TcfLevelEstimatorService(),
        propsAvecSeuilsParDefaut());

    private static ProductionEvaluationProperties propsAvecSeuilsParDefaut() {
        return new ProductionEvaluationProperties();
    }

    private static AiEvaluation eval(Number lexique, Number morpho, String note) {
        AiEvaluation e = new AiEvaluation();
        e.setNoteSur20(note == null ? null : new BigDecimal(note));
        e.setNiveauCecrl(null);
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("scores_criteres", List.of(
            score("lexique", lexique), score("morphosyntaxe", morpho)));
        e.setFeedbackJson(feedback);
        return e;
    }

    @Test
    void bilan_une_T1_faible_ne_plafonne_plus_l_epreuve() {
        // T1 competence 8 (A2), T2 et T3 competence 14 (B1).
        // Plancher (ancien calcul) -> A2. Pondere : (8×1 + 14×2 + 14×3)/6 = 13 -> B1.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(8, 8, "8"),
            2, eval(14, 14, "14"),
            3, eval(14, 14, "14"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void bilan_pondere_T3_pese_plus_que_T1() {
        // (16×1 + 10×2 + 10×3)/6 = 11 -> A2 : un bon T1 ne suffit pas.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(16, 16, "16"),
            2, eval(10, 10, "10"),
            3, eval(10, 10, "10"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void bilan_hors_sujet_partiel_penalise_sans_annuler() {
        // T1 hors-sujet (note 0 -> competence 0), T2/T3 a 15.
        // (0×1 + 15×2 + 15×3)/6 = 12.5 -> B1.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(0, 0, "0"),
            2, eval(15, 15, "15"),
            3, eval(15, 15, "15"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void bilan_tout_hors_sujet_donne_A1_NON_ATTEINT() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(0, 0, "0"),
            2, eval(0, 0, "0"),
            3, eval(0, 0, "0"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    @Test
    void bilan_plafonne_a_B2() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"),
            3, eval(20, 20, "20"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void bilan_evals_inexploitables_fallback_plancher_des_niveaux_persistes() {
        AiEvaluation sansScores = new AiEvaluation();
        sansScores.setNiveauCecrl(NiveauCecrl.B1);
        AiEvaluation sansScores2 = new AiEvaluation();
        sansScores2.setNiveauCecrl(NiveauCecrl.A2);
        Map<Integer, AiEvaluation> evals = Map.of(1, sansScores, 2, sansScores2);
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void bilan_termine_tache_manquante_compte_zero() {
        // T1 absente (jamais rendue, examen terminé), T2/T3 a 15.
        // (0×1 + 15×2 + 15×3)/6 = 12.5 -> B1 (au lieu de null en cours d'examen).
        Map<Integer, AiEvaluation> evals = Map.of(
            2, eval(15, 15, "15"),
            3, eval(15, 15, "15"));
        assertThat(service.bilanEpreuveTerminee(evals)).isEqualTo(NiveauCecrl.B1);
        assertThat(service.bilanEpreuve(evals)).isNotEqualTo(NiveauCecrl.B1); // partiel ≠ terminé
    }

    @Test
    void bilan_termine_sans_aucune_tache_donne_A1_NON_ATTEINT() {
        assertThat(service.bilanEpreuveTerminee(Map.of())).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    // ------------------------------------------------------------------------
    // Phase 3 — coherence du bilan (drapeau coherence-bilan.enabled, false)
    // ------------------------------------------------------------------------

    /** T1/T2 excellentes, T3 effondree : (20×1 + 20×2 + 11×3)/6 = 15.5 → B2. */
    private static Map<Integer, AiEvaluation> epreuveB2AvecT3Faible() {
        return Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"),
            3, eval(11, 11, "11")); // competence 11 -> A2, sous B1
    }

    /**
     * VERROU : drapeau eteint, la math est strictement celle d'aujourd'hui —
     * un B2 porte par les deux premieres taches reste un B2.
     */
    @Test
    void coherence_eteinte_laisse_le_bilan_intact() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        assertThat(props.getCoherenceBilan().isEnabled()).isFalse();
        ProductionBilanService svc = new ProductionBilanService(
            mock(AiEvaluationManager.class), new TcfLevelEstimatorService(), props);

        assertThat(svc.bilanEpreuve(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B2);
        assertThat(svc.bilanEpreuveTerminee(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void coherence_allumee_pas_de_B2_si_la_tache_3_est_sous_B1() {
        ProductionBilanService svc = serviceAvecCoherence();

        assertThat(svc.bilanEpreuve(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B1);
        assertThat(svc.bilanEpreuveTerminee(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void coherence_allumee_ne_plafonne_pas_une_tache_3_a_B1() {
        // (20×1 + 20×2 + 12×3)/6 = 16 -> B2, T3 competence 12 -> B1 : aucun plafond.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"),
            3, eval(12, 12, "12"));

        assertThat(serviceAvecCoherence().bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void coherence_allumee_ne_conclut_pas_d_une_tache_3_pas_encore_rendue() {
        // Epreuve EN COURS : T3 absente n'est pas une T3 ratee.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"));

        assertThat(serviceAvecCoherence().bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void coherence_allumee_ne_releve_jamais_un_bilan() {
        // Bilan deja sous le plafond : le garde-fou ne doit pas le remonter.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(8, 8, "8"),
            2, eval(8, 8, "8"),
            3, eval(8, 8, "8"));

        assertThat(serviceAvecCoherence().bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    private static ProductionBilanService serviceAvecCoherence() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.getCoherenceBilan().setEnabled(true);
        return new ProductionBilanService(
            mock(AiEvaluationManager.class), new TcfLevelEstimatorService(), props);
    }

    @Test
    void moyenneNotes_arrondit_a_une_decimale() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(10, 10, "10"),
            2, eval(12, 12, "12"),
            3, eval(15, 15, "15"));
        assertThat(service.moyenneNotes(evals)).isEqualByComparingTo(new BigDecimal("12.3"));
    }
}
