package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifie le calcul SERVEUR de {@code note_globale} = {@code round(Σ note×poids)}
 * (cf. {@link AiEvaluationService#weightedNote}). Le {@code niveau_cecrl} derive
 * de lexique+morphosyntaxe est teste dans {@link ProductionBilanServiceTest}.
 */
class AiEvaluationServiceTest {

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
        // 16*0.35 + 12*0.25 + 8*0.25 + 10*0.15 = 5.6 + 3.0 + 2.0 + 1.5 = 12.1
        // Une DECIMALE depuis v5 : le niveau se lit sur la note, arrondir a
        // l'entier ferait diverger la note affichee et le niveau calcule.
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 16),
            score("lexique", 12),
            score("morphosyntaxe", 8),
            score("coherence", 10)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(new BigDecimal("12.1"));
    }

    @Test
    void weightedNote_arrondit_au_plus_proche_HALF_UP() {
        // Tous a 13.5 -> Σ = 13.5, conserve tel quel (une decimale).
        List<Map<String, Object>> scores = List.of(
            score("pertinence", 13.5),
            score("lexique", 13.5),
            score("morphosyntaxe", 13.5),
            score("coherence", 13.5)
        );
        assertThat(AiEvaluationService.weightedNote(criteresEeT1(), scores))
            .isEqualByComparingTo(new BigDecimal("13.5"));
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
}
