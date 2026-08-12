package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/** Contrat transport : une réponse HTTP vide est rejouable, jamais terminale. */
class ConfiguredDiagnosticAnalysisLlmClientTest {

    private static final String URL = "https://llm.test/v1/messages";

    @Test
    void openAiReponseVideEstTransitoireSansBoucleHttp() {
        ProductionEvaluationProperties properties = baseProperties("openai");
        configure(properties.getOpenai());
        var client = new ConfiguredDiagnosticAnalysisLlmClient(
                properties, new DiagnosticProperties(), new ObjectMapper());
        client.initialize();
        MockRestServiceServer server = replaceRestClient(client);
        server.expect(requestTo(URL)).andRespond(withSuccess("", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.analyse("système", "production"))
                .isInstanceOf(AiEvaluationTransientException.class)
                .hasMessageContaining("Réponse diagnostic vide");
        server.verify();
    }

    @Test
    void anthropicReponseVideEstTransitoire() {
        ProductionEvaluationProperties properties = baseProperties("anthropic");
        var anthropic = properties.getAnthropic();
        anthropic.setApiKey("test-key");
        anthropic.setApiUrl(URL);
        anthropic.setModel("test-model");
        anthropic.setAnthropicVersion("2023-06-01");
        anthropic.setTimeoutSec(1);
        var client = new ConfiguredDiagnosticAnalysisLlmClient(
                properties, new DiagnosticProperties(), new ObjectMapper());
        client.initialize();
        MockRestServiceServer server = replaceRestClient(client);
        server.expect(requestTo(URL)).andRespond(withSuccess("", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> client.analyse("système", "production"))
                .isInstanceOf(AiEvaluationTransientException.class)
                .hasMessageContaining("Réponse Anthropic diagnostic vide");
        server.verify();
    }

    private static ProductionEvaluationProperties baseProperties(String provider) {
        ProductionEvaluationProperties properties = new ProductionEvaluationProperties();
        properties.setProvider(provider);
        return properties;
    }

    private static void configure(ProductionEvaluationProperties.OpenAi openAi) {
        openAi.setApiKey("test-key");
        openAi.setApiUrl(URL);
        openAi.setModel("test-model");
        openAi.setTimeoutSec(1);
        openAi.setMaxTokensParam("max_tokens");
        openAi.setSendTemperature("false");
    }

    private static MockRestServiceServer replaceRestClient(
            ConfiguredDiagnosticAnalysisLlmClient client) {
        RestClient.Builder builder = RestClient.builder().baseUrl(URL);
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        ReflectionTestUtils.setField(client, "restClient", builder.build());
        return server;
    }
}
