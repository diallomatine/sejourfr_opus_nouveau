package com.sejourfr.app.enums;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/** {@code min} = plafonnement serveur ; {@code parse} = lecture tolerante du JSON LLM. */
class ConfianceEvaluationTest {

    @Test
    void min_retourneLaPlusFaible() {
        assertThat(ConfianceEvaluation.min(ConfianceEvaluation.HAUTE, ConfianceEvaluation.MOYENNE))
            .isEqualTo(ConfianceEvaluation.MOYENNE);
        assertThat(ConfianceEvaluation.min(ConfianceEvaluation.FAIBLE, ConfianceEvaluation.MOYENNE))
            .isEqualTo(ConfianceEvaluation.FAIBLE);
        assertThat(ConfianceEvaluation.min(ConfianceEvaluation.HAUTE, ConfianceEvaluation.HAUTE))
            .isEqualTo(ConfianceEvaluation.HAUTE);
    }

    @Test
    void min_ignoreLesPlafondsInconnus() {
        assertThat(ConfianceEvaluation.min(ConfianceEvaluation.HAUTE, null))
            .isEqualTo(ConfianceEvaluation.HAUTE);
        assertThat(ConfianceEvaluation.min(null, ConfianceEvaluation.FAIBLE))
            .isEqualTo(ConfianceEvaluation.FAIBLE);
        assertThat(ConfianceEvaluation.min(null, null)).isNull();
    }

    @Test
    void parse_tolereCasseEtEspaces_refuseLeReste() {
        assertThat(ConfianceEvaluation.parse(" moyenne ")).isEqualTo(ConfianceEvaluation.MOYENNE);
        assertThat(ConfianceEvaluation.parse("HAUTE")).isEqualTo(ConfianceEvaluation.HAUTE);
        assertThat(ConfianceEvaluation.parse("TOTALE")).isNull();
        assertThat(ConfianceEvaluation.parse("")).isNull();
        assertThat(ConfianceEvaluation.parse(null)).isNull();
    }
}
