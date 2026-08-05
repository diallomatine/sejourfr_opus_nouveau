package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.CorrespondanceTcfDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.enums.BandeNoteTcf;
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
 *       taches, poids EGAUX depuis v5 (cf.
 *       {@link ProductionBilanService#bilanEpreuve}) ;</li>
 *   <li>note d'epreuve et niveau d'epreuve calcules sur le MEME perimetre
 *       (cf. {@link ProductionBilanService#noteEpreuve}).</li>
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

    private final ProductionBilanService service = service(new ProductionEvaluationProperties());

    /**
     * Service cable sur les reglages de niveau de la config (grilles v3-v4.2 :
     * lexique + morphosyntaxe + coherence, seuils 15/12/7). Depuis v5 ces
     * reglages viennent du fichier de rubriques, d'ou le provider.
     */
    private static ProductionBilanService service(ProductionEvaluationProperties props) {
        ProductionRubricsProvider rubrics = mock(ProductionRubricsProvider.class);
        org.mockito.Mockito.lenient().when(rubrics.niveauCecrl()).thenReturn(props.getNiveauCecrl());
        return new ProductionBilanService(
            mock(AiEvaluationManager.class), new TcfLevelEstimatorService(), rubrics, props);
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
        // Plancher (ancien calcul) -> A2. Moyenne : (8 + 14 + 14)/3 = 12 -> B1.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(8, 8, "8"),
            2, eval(14, 14, "14"),
            3, eval(14, 14, "14"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * Poids EGAUX depuis v5 (le TCF publie une seule note d'epreuve et aucune
     * ponderation par tache) : (16 + 10 + 10)/3 = 12 -> B1.
     */
    @Test
    void bilan_poids_egaux_par_defaut() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(16, 16, "16"),
            2, eval(10, 10, "10"),
            3, eval(10, 10, "10"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * La ponderation reste REGLABLE sans redeploiement : avec les anciens poids
     * 1/2/3, (16x1 + 10x2 + 10x3)/6 = 11 -> A2. Verrouille la reversibilite.
     */
    @Test
    void bilan_poids_configurables_restent_honores() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.getNiveauCecrl().setPoidsTaches(List.of(1.0, 2.0, 3.0));
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(16, 16, "16"),
            2, eval(10, 10, "10"),
            3, eval(10, 10, "10"));
        assertThat(service(props).bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void bilan_hors_sujet_partiel_penalise_sans_annuler() {
        // T1 hors-sujet (note 0 -> competence 0), T2/T3 a 15.
        // (0 + 15 + 15)/3 = 10 -> A2 : penalise lourdement, sans annuler
        // l'epreuve (ce serait A1_NON_ATTEINT).
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(0, 0, "0"),
            2, eval(15, 15, "15"),
            3, eval(15, 15, "15"));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
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
        // (0 + 15 + 15)/3 = 10 -> A2, la ou l'epreuve en cours vaut B2.
        Map<Integer, AiEvaluation> evals = Map.of(
            2, eval(15, 15, "15"),
            3, eval(15, 15, "15"));
        assertThat(service.bilanEpreuveTerminee(evals)).isEqualTo(NiveauCecrl.A2);
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B2); // partiel ≠ terminé
    }

    @Test
    void bilan_termine_sans_aucune_tache_donne_A1_NON_ATTEINT() {
        assertThat(service.bilanEpreuveTerminee(Map.of())).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    // ------------------------------------------------------------------------
    // Coherence du bilan (drapeau coherence-bilan.enabled, ACTIF par defaut)
    // ------------------------------------------------------------------------

    /** T1/T2 excellentes, T3 effondree : (20 + 20 + 11)/3 = 17 → B2. */
    private static Map<Integer, AiEvaluation> epreuveB2AvecT3Faible() {
        return Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"),
            3, eval(11, 11, "11")); // competence 11 -> A2, sous B1
    }

    /**
     * VERROU DU RETOUR ARRIERE : drapeau ETEINT explicitement, la math
     * redevient strictement celle d'avant — un B2 porte par les deux premieres
     * taches reste un B2. C'est ce qui rend l'activation reversible en une
     * variable ({@code EVAL_COHERENCE_BILAN_ENABLED=false}).
     */
    @Test
    void coherence_eteinte_laisse_le_bilan_intact() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.getCoherenceBilan().setEnabled(false);
        ProductionBilanService svc = service(props);

        assertThat(svc.bilanEpreuve(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B2);
        assertThat(svc.bilanEpreuveTerminee(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B2);
    }

    /**
     * VERROU DU DEFAUT : le garde-fou est livre ACTIF. Les 3 taches ne sont pas
     * interchangeables — la T3 est la seule qui demande d'argumenter, donc la
     * seule qui puisse demontrer un B2.
     */
    @Test
    void coherence_est_active_par_defaut() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        assertThat(props.getCoherenceBilan().isEnabled()).isTrue();

        // Le service par defaut du test (construit sans surcharge) plafonne donc.
        assertThat(service.bilanEpreuve(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void coherence_allumee_pas_de_B2_si_la_tache_3_est_sous_B1() {
        ProductionBilanService svc = serviceAvecCoherence();

        assertThat(svc.bilanEpreuve(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B1);
        assertThat(svc.bilanEpreuveTerminee(epreuveB2AvecT3Faible())).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void coherence_allumee_ne_plafonne_pas_une_tache_3_a_B1() {
        // (20 + 20 + 12)/3 = 17,33 -> B2, T3 competence 12 -> B1 : aucun plafond.
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
        return service(props);
    }

    // ------------------------------------------------------------------------
    // Propagation du plafond de niveau au bilan
    // ------------------------------------------------------------------------

    /** Copie de {@code base} avec le plafond de niveau posé par l'évaluation. */
    private static AiEvaluation plafonnee(AiEvaluation base, NiveauCecrl plafond) {
        Map<String, Object> feedback = new LinkedHashMap<>(base.getFeedbackJson());
        feedback.put(AiEvaluationService.PLAFOND_NIVEAU_KEY, plafond.name());
        base.setFeedbackJson(feedback);
        return base;
    }

    /**
     * VERROU du défaut : le plafond n'abaissait que le niveau affiché par tâche.
     * Le bilan — seul niveau qui fait foi — repartait des {@code scores_criteres}
     * bruts, si bien qu'une tâche 3 plafonnée A2 ressortait B2.
     */
    @Test
    void bilan_tache3_plafonnee_A2_ne_ressort_plus_B2() {
        // Sans plafond : (16 + 16 + 16)/3 = 16 -> B2.
        Map<Integer, AiEvaluation> sansPlafond = Map.of(
            1, eval(16, 16, "16"),
            2, eval(16, 16, "16"),
            3, eval(16, 16, "16"));
        assertThat(service.bilanEpreuve(sansPlafond)).isEqualTo(NiveauCecrl.B2);

        // Avec le plafond A2 sur T3 : sa competence est ramenee sous le seuil B1
        // (11,9999), donc (16 + 16 + 11,9999)/3 = 14,67 -> B1.
        Map<Integer, AiEvaluation> avecPlafond = Map.of(
            1, eval(16, 16, "16"),
            2, eval(16, 16, "16"),
            3, plafonnee(eval(16, 16, "16"), NiveauCecrl.A2));
        assertThat(service.bilanEpreuve(avecPlafond)).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void bilan_plafond_A1_NON_ATTEINT_annule_la_contribution_de_la_tache() {
        // T3 plafonnee au plancher : competence 0, comme un hors-sujet.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(15, 15, "15"),
            2, eval(15, 15, "15"),
            3, plafonnee(eval(18, 18, "18"), NiveauCecrl.A1_NON_ATTEINT));

        // (15 + 15 + 0)/3 = 10 -> A2.
        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void bilan_plafond_au_dessus_du_niveau_observe_ne_change_rien() {
        // Plafond B1 sur une tache deja a competence 10 (A2) : aucun effet.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(10, 10, "10"),
            2, eval(10, 10, "10"),
            3, plafonnee(eval(10, 10, "10"), NiveauCecrl.B1));

        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void bilan_plafond_illisible_est_ignore_sans_crash() {
        AiEvaluation e = eval(16, 16, "16");
        Map<String, Object> feedback = new LinkedHashMap<>(e.getFeedbackJson());
        feedback.put(AiEvaluationService.PLAFOND_NIVEAU_KEY, "PAS_UN_NIVEAU");
        e.setFeedbackJson(feedback);
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(16, 16, "16"), 2, eval(16, 16, "16"), 3, e);

        assertThat(service.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void bilan_coherence_lit_le_niveau_plafonne_de_la_tache3() {
        // T3 notee 16 (B2 brut) mais plafonnee A2 : le garde-fou de coherence,
        // qui recalcule le niveau de T3, doit voir A2 et plafonner le bilan.
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(20, 20, "20"),
            2, eval(20, 20, "20"),
            3, plafonnee(eval(16, 16, "16"), NiveauCecrl.A2));

        assertThat(serviceAvecCoherence().bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void moyenneNotes_arrondit_a_une_decimale() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(10, 10, "10"),
            2, eval(12, 12, "12"),
            3, eval(15, 15, "15"));
        assertThat(service.moyenneNotes(evals)).isEqualByComparingTo(new BigDecimal("12.3"));
    }

    // ------------------------------------------------------------------------
    // note d'epreuve et niveau d'epreuve : la meme histoire (v5)
    // ------------------------------------------------------------------------

    /** Service cable comme la grille v5 : le niveau derive des quatre criteres. */
    private static ProductionBilanService serviceV5() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        ProductionEvaluationProperties.NiveauCecrl n = props.getNiveauCecrl();
        n.setSourceCriteres(List.of("communiquer", "interagir", "lexique", "morphosyntaxe"));
        n.setSeuilB2(16.0);
        n.setSeuilB1(13.0);
        n.setSeuilA2(9.0);
        return service(props);
    }

    private static AiEvaluation evalV5(int communiquer, int interagir, int lexique, int morpho) {
        AiEvaluation e = new AiEvaluation();
        BigDecimal note = new BigDecimal(communiquer + interagir + lexique + morpho)
            .divide(new BigDecimal("4"));
        e.setNoteSur20(note);
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("scores_criteres", List.of(
            score("communiquer", communiquer), score("interagir", interagir),
            score("lexique", lexique), score("morphosyntaxe", morpho)));
        e.setFeedbackJson(feedback);
        return e;
    }

    /**
     * LE defaut qui a declenche la refonte : une carte affichait « 11/20 » et
     * « proche du niveau A2 ». Avec la grille du TCF, la note d'epreuve et le
     * niveau d'epreuve sont deux lectures du MEME nombre.
     */
    @Test
    void v5_note_epreuve_et_niveau_epreuve_racontent_la_meme_histoire() {
        ProductionBilanService svc = serviceV5();
        Map<Integer, AiEvaluation> evals = Map.of(
            1, evalV5(15, 15, 13, 13),   // 14
            2, evalV5(13, 13, 11, 11),   // 12
            3, evalV5(14, 14, 12, 12));  // 13
        // moyenne des trois notes = 13 -> bande B1 (13 a 15).
        assertThat(svc.noteEpreuve(evals, false)).isEqualByComparingTo(new BigDecimal("13.0"));
        assertThat(svc.bilanEpreuve(evals)).isEqualTo(NiveauCecrl.B1);
        assertThat(svc.correspondanceTcf(svc.bilanEpreuve(evals)))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.B1, 6, 9));
    }

    /** Toute la plage : le niveau d'epreuve se lit sur la note d'epreuve. */
    @Test
    void v5_le_niveau_epreuve_se_lit_sur_la_note_epreuve() {
        ProductionBilanService svc = serviceV5();
        assertThat(svc.bilanEpreuve(troisTachesA(4, 4, 4, 4))).isEqualTo(NiveauCecrl.A1);     // 4
        assertThat(svc.bilanEpreuve(troisTachesA(11, 11, 8, 8))).isEqualTo(NiveauCecrl.A2);   // 9,5
        assertThat(svc.bilanEpreuve(troisTachesA(15, 15, 12, 12))).isEqualTo(NiveauCecrl.B1); // 13,5
        assertThat(svc.bilanEpreuve(troisTachesA(17, 17, 16, 16))).isEqualTo(NiveauCecrl.B2); // 16,5
    }

    private static Map<Integer, AiEvaluation> troisTachesA(int c, int i, int l, int m) {
        return Map.of(1, evalV5(c, i, l, m), 2, evalV5(c, i, l, m), 3, evalV5(c, i, l, m));
    }

    /**
     * L'accomplissement PESE desormais dans le niveau (25 % + 25 %, comme au
     * TCF) : a langue egale, une tache accomplie ne se lit plus comme une tache
     * ratee. C'est exactement ce que la config v4.2 excluait.
     */
    @Test
    void v5_accomplissement_compte_dans_le_niveau() {
        ProductionBilanService svc = serviceV5();
        Map<Integer, AiEvaluation> accomplie = troisTachesA(15, 15, 12, 12);   // 13,5 -> B1
        Map<Integer, AiEvaluation> ratee = troisTachesA(6, 6, 12, 12);         // 9    -> A2
        // Meme langue (12/12) des deux cotes : seul l'accomplissement change.
        assertThat(svc.bilanEpreuve(accomplie)).isEqualTo(NiveauCecrl.B1);
        assertThat(svc.bilanEpreuve(ratee)).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * ... mais un accomplissement parfait ne fabrique pas un B2 : avec une
     * langue A2 (10/10) et le garde-fou de couplage (+4, donc 14 au maximum),
     * la moyenne plafonne a 12 — B1, jamais B2.
     */
    @Test
    void v5_communiquer_eleve_sur_langue_A2_ne_fabrique_pas_de_B2() {
        ProductionBilanService svc = serviceV5();
        // langue A2 au maximum (10/10) + couplage (+4) -> moyenne 12 : A2, jamais B2.
        assertThat(svc.bilanEpreuve(troisTachesA(14, 14, 10, 10))).isEqualTo(NiveauCecrl.A2);
        // Meme en poussant communiquer/interagir au maximum autorise par le
        // couplage sur une langue A1 (5/5 -> plafond 9), on reste en A1 (7/20).
        assertThat(svc.bilanEpreuve(troisTachesA(9, 9, 5, 5))).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * Epreuve ecourtee : la note d'epreuve compte les taches jamais rendues
     * comme 0, exactement comme le niveau — sinon le bilan afficherait une note
     * calculee sur deux taches a cote d'un niveau calcule sur trois.
     */
    @Test
    void v5_note_epreuve_terminee_compte_les_taches_manquantes_a_zero() {
        ProductionBilanService svc = serviceV5();
        Map<Integer, AiEvaluation> deuxTaches = Map.of(
            2, evalV5(15, 15, 15, 15),
            3, evalV5(15, 15, 15, 15));

        assertThat(svc.noteEpreuve(deuxTaches, false)).isEqualByComparingTo(new BigDecimal("15.0"));
        assertThat(svc.bilanEpreuve(deuxTaches)).isEqualTo(NiveauCecrl.B1);
        assertThat(svc.noteEpreuve(deuxTaches, true)).isEqualByComparingTo(new BigDecimal("10.0"));
        assertThat(svc.bilanEpreuveTerminee(deuxTaches)).isEqualTo(NiveauCecrl.A2);
    }

    // ------------------------------------------------------------------------
    // correspondance avec la grille officielle du TCF IRN
    // ------------------------------------------------------------------------

    @Test
    void correspondanceTcf_reprend_la_grille_officielle_niveau_par_niveau() {
        assertThat(service.correspondanceTcf(NiveauCecrl.A1_NON_ATTEINT))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.A1_NON_ATTEINT, 0, 0));
        assertThat(service.correspondanceTcf(NiveauCecrl.A1))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.A1, 1, 1));
        assertThat(service.correspondanceTcf(NiveauCecrl.A2))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.A2, 2, 5));
        assertThat(service.correspondanceTcf(NiveauCecrl.B1))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.B1, 6, 9));
        assertThat(service.correspondanceTcf(NiveauCecrl.B2))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.B2, 10, 20));
    }

    @Test
    void correspondanceTcf_sans_niveau_ou_hors_echelle_tcf_reste_null() {
        assertThat(service.correspondanceTcf(null)).isNull();
        assertThat(service.correspondanceTcf(NiveauCecrl.C1)).isNull();
        assertThat(service.correspondanceTcf(NiveauCecrl.C2)).isNull();
    }

    @Test
    void bandes_officielles_contigues_et_couvrant_0_a_20() {
        BandeNoteTcf[] bandes = BandeNoteTcf.values();
        assertThat(bandes[0].getScoreMin()).isZero();
        assertThat(bandes[bandes.length - 1].getScoreMax()).isEqualTo(20);
        for (BandeNoteTcf bande : bandes) {
            assertThat(bande.getScoreMin()).isLessThanOrEqualTo(bande.getScoreMax());
        }
        for (int i = 1; i < bandes.length; i++) {
            assertThat(bandes[i].getScoreMin()).isEqualTo(bandes[i - 1].getScoreMax() + 1);
        }
    }

    /**
     * Garde-fou : la correspondance est un affichage derive, elle ne doit
     * toucher a aucune decision de notation. Meme entree, meme niveau qu'avant
     * — et une competence de 12,5/20 reste B1 chez nous alors qu'elle vaudrait
     * B2 sur la grille officielle. C'est exactement ce qu'on ne veut PAS
     * convertir.
     */
    @Test
    void correspondanceTcf_ne_change_pas_le_niveau_calcule() {
        Map<Integer, AiEvaluation> evals = Map.of(
            1, eval(12, 13, "12.5"),
            2, eval(12, 13, "12.5"),
            3, eval(12, 13, "12.5"));

        NiveauCecrl niveau = service.bilanEpreuve(evals);

        assertThat(niveau).isEqualTo(NiveauCecrl.B1);
        assertThat(service.correspondanceTcf(niveau))
            .isEqualTo(new CorrespondanceTcfDto(NiveauCecrl.B1, 6, 9));
        assertThat(service.bilanEpreuve(evals)).isEqualTo(niveau);
    }
}
