package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'analyse ciblee partage le PROVIDER des corrections completes (regle « un
 * seul correcteur configurable ») : elle doit donc parler le meme dialecte. Sans
 * ce test, basculer {@code EVAL_LLM_PROVIDER} sur un gpt-5.x aurait repare les
 * corrections completes et casse silencieusement le module Competences, qui
 * envoyait encore {@code max_tokens}.
 *
 * <p>Ce qui reste PROPRE au module et ne doit pas deriver : le budget de tokens
 * (600, pas 4000) et la temperature viennent de
 * {@code sejourfr.competences.analysis}, jamais du bloc production-evaluation.
 */
class CompetenceOpenAiCompatibleClientRequestBodyTest {

    private static final ObjectMapper OM = new ObjectMapper();

    private static CompetenceProperties.Analysis analysis() {
        return new CompetenceProperties.Analysis();
    }

    private static ProductionEvaluationProperties.OpenAi openAi(String modele) {
        ProductionEvaluationProperties.OpenAi s = new ProductionEvaluationProperties.OpenAi();
        s.setApiKey("cle-de-test");
        s.setApiUrl("https://api.openai.com/v1/chat/completions");
        s.setModel(modele);
        s.setTimeoutSec(60);
        return s;
    }

    private static ProductionEvaluationProperties.DeepSeek deepSeek() {
        ProductionEvaluationProperties.DeepSeek s = new ProductionEvaluationProperties.DeepSeek();
        s.setApiKey("cle-de-test");
        s.setApiUrl("https://api.deepseek.com/chat/completions");
        s.setModel("deepseek-v4-flash");
        s.setTimeoutSec(60);
        s.setDisableThinking(true);
        return s;
    }

    private static Map<String, Object> corps(
            ProductionEvaluationProperties.ChatCompletionSettings connexion, String label) {
        CompetenceProperties.Analysis a = analysis();
        CompetenceOpenAiCompatibleClient client =
            new CompetenceOpenAiCompatibleClient(connexion, a, label, OM);
        try {
            client.loadToolSchema();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
        return client.buildRequestBody("system", "user");
    }

    @Test
    void deepseek_reste_sur_max_tokens() {
        Map<String, Object> body = corps(deepSeek(), "DeepSeek");

        assertThat(body).containsEntry("max_tokens", analysis().getMaxTokens());
        assertThat(body).doesNotContainKey("max_completion_tokens");
        assertThat(body.get("thinking")).isEqualTo(Map.of("type", "disabled"));
    }

    @Test
    void openai_moderne_bascule_sur_max_completion_tokens() {
        Map<String, Object> body = corps(openAi("gpt-5.4"), "OpenAI");

        assertThat(body).containsEntry("max_completion_tokens", analysis().getMaxTokens());
        assertThat(body).doesNotContainKey("max_tokens");
        assertThat(body).containsEntry("temperature", analysis().getTemperature());
    }

    @Test
    void le_budget_reste_celui_de_l_analyse_ciblee_pas_celui_des_corrections_completes() {
        Object plafond = corps(openAi("gpt-5.4"), "OpenAI").get("max_completion_tokens");

        assertThat(plafond).isEqualTo(analysis().getMaxTokens());
        assertThat((Integer) plafond).isLessThan(4000);
    }

    @Test
    void temperature_omise_sur_un_modele_a_temperature_figee() {
        assertThat(corps(openAi("gpt-5.5"), "OpenAI")).doesNotContainKey("temperature");
    }
}
