package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifie les calculs SERVEUR : {@code note_globale} = {@code round(Σ note×poids)}
 * (cf. {@link AiEvaluationService#weightedNote}) et le {@code niveau_cecrl} derive
 * de lexique+morphosyntaxe (cf. {@link AiEvaluationService#computeNiveau}).
 */
class AiEvaluationServiceTest {

    private static final List<String> SOURCE = List.of("lexique", "morphosyntaxe");
    /** Seuils par defaut : B2≥15, B1≥12, A2≥7. */
    private static final ProductionEvaluationProperties.NiveauCecrl SEUILS =
        new ProductionEvaluationProperties.NiveauCecrl();

    /** Rubrique EE_T1 (poids canoniques : 0.35 / 0.25 / 0.25 / 0.15, Σ = 1.0). */
    private static List<Map<String, Object>> criteresEeT1() {
        return List.of(
            Map.of("code", "pertinence", "poids", 0.35),
            Map.of("code", "lexique", "poids", 0.25),
            Map.of("code", "morphosyntaxe", "poids", 0.25),
            Map.of("code", "coherence", "poids", 0.15)
        );
    }

    private static Map<String, Object> score(String code, Number note) {
        return Map.of("code", code, "note_sur_20", note, "commentaire", "x");
    }

    @Test
    void weightedNote_arrondit_la_somme_ponderee() {
        // 16*0.35 + 12*0.25 + 8*0.25 + 10*0.15 = 5.6 + 3.0 + 2.0 + 1.5 = 12.1 -> 12
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 16),
            score("lexique", 12),
            score("morphosyntaxe", 8),
            score("coherence", 10)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(new BigDecimal("12"));
    }

    @Test
    void weightedNote_arrondit_au_plus_proche_HALF_UP() {
        // Tous a 13.5 -> Σ = 13.5 -> 14 (HALF_UP).
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 13.5),
            score("lexique", 13.5),
            score("morphosyntaxe", 13.5),
            score("coherence", 13.5)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(new BigDecimal("14"));
    }

    @Test
    void weightedNote_hors_sujet_tous_a_zero_donne_zero() {
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 0),
            score("lexique", 0),
            score("morphosyntaxe", 0),
            score("coherence", 0)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void weightedNote_sans_rubrique_retourne_null() {
        List<Map<String, Object>> scores = List.of(score("pertinence", 16));
        assertThat(AiEvaluationService.weightedNote(null, scores)).isNull();
    }

    @Test
    void weightedNote_sans_scores_exploitables_retourne_null() {
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), List.of())).isNull();
        // Codes inconnus de la rubrique -> aucun critere pondere -> null.
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), List.of(score("inconnu", 18))))
            .isNull();
    }

    @Test
    void weightedNote_borne_a_20() {
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 20),
            score("lexique", 20),
            score("morphosyntaxe", 20),
            score("coherence", 20)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(new BigDecimal("20"));
    }

    // ------------------------------------------------------------------------
    // niveau_cecrl calcule serveur (lexique + morphosyntaxe)
    // ------------------------------------------------------------------------

    private static NiveauCecrl niveau(List<Map<String, Object>> scores, BigDecimal note) {
        return AiEvaluationService.computeNiveau(scores, SOURCE, note, SEUILS);
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
}
