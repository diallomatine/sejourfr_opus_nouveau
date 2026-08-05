package com.sejourfr.app.config;

import com.sejourfr.app.service.EvaluationLlmClient;
import com.sejourfr.app.service.OpenAiCompatibleEvalClient;
import com.sejourfr.app.service.ProductionRubricsProvider;
import com.sejourfr.app.service.ProductionSecondePasseService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class EvaluationLlmConfigTest {

    @Test
    void deepseek_est_le_defaut_et_la_seconde_passe_reutilise_le_meme_client() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        EvaluationLlmClient anthropic = mock(EvaluationLlmClient.class);
        OpenAiCompatibleEvalClient openai = mock(OpenAiCompatibleEvalClient.class);
        OpenAiCompatibleEvalClient deepseek = mock(OpenAiCompatibleEvalClient.class);

        EvaluationLlmClient selected = new EvaluationLlmConfig().evaluationLlmClient(
            props, anthropic, openai, deepseek);
        ProductionRubricsProvider rubrics = mock(ProductionRubricsProvider.class);
        ProductionSecondePasseService secondePasse =
            new ProductionSecondePasseService(props, selected, rubrics);

        assertThat(props.getProvider()).isEqualTo("deepseek");
        assertThat(selected).isSameAs(deepseek);
        assertThat(secondePasse.client()).isSameAs(selected);
    }
}
