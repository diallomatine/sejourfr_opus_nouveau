package com.sejourfr.app.calibration;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CalibrationEnvTest {

    @Test
    void banc_et_runtime_partagent_le_correcteur_canonique() {
        ProductionEvaluationProperties props = CalibrationEnv.properties(null, null);

        assertThat(props.getProvider()).isEqualTo("deepseek");
        assertThat(props.getDeepseek().getModel()).isEqualTo("deepseek-v4-flash");
        assertThat(props.getDeepseek().getPromptVersion()).isEqualTo("v5");
        assertThat(props.getRubricsVersion()).isEqualTo("v8");
    }
}
