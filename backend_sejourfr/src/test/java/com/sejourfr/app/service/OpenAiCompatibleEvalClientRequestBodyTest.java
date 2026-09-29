package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le corps de requete envoye au correcteur, provider par provider.
 *
 * <p>Les deux voies passent par le MEME client ; ce qui les separe tient a deux
 * champs, et se tromper sur l'un des deux fait echouer 100 % des corrections en
 * 400 — pas « un peu moins bien », plus du tout. DeepSeek est la voie
 * actuellement en production : ce test est son filet.
 */
class OpenAiCompatibleEvalClientRequestBodyTest {

    private static final ObjectMapper OM = new ObjectMapper();

    private static ProductionEvaluationProperties.OpenAi openAi(String modele) {
        ProductionEvaluationProperties.OpenAi s = new ProductionEvaluationProperties.OpenAi();
        s.setApiKey("cle-de-test");
        s.setApiUrl("https://api.openai.com/v1/chat/completions");
        s.setModel(modele);
        s.setMaxTokens(4000);
        s.setTemperature(0);
        s.setTimeoutSec(60);
        s.setPromptVersion("v5");
        return s;
    }

    private static ProductionEvaluationProperties.DeepSeek deepSeek() {
        ProductionEvaluationProperties.DeepSeek s = new ProductionEvaluationProperties.DeepSeek();
        s.setApiKey("cle-de-test");
        s.setApiUrl("https://api.deepseek.com/chat/completions");
        s.setModel("deepseek-v4-flash");
        s.setMaxTokens(4000);
        s.setTemperature(0);
        s.setTimeoutSec(60);
        s.setDisableThinking(true);
        s.setPromptVersion("v5");
        return s;
    }

    private static Map<String, Object> corps(
            ProductionEvaluationProperties.ChatCompletionSettings settings, String label) {
        OpenAiCompatibleEvalClient client = new OpenAiCompatibleEvalClient(settings, label, OM);
        try {
            client.loadToolSchema();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
        return client.buildRequestBody("system", "user");
    }

    @Test
    void deepseek_garde_max_tokens_et_le_thinking_desactive() {
        Map<String, Object> body = corps(deepSeek(), "DeepSeek");

        assertThat(body).containsEntry("max_tokens", 4000);
        assertThat(body).doesNotContainKey("max_completion_tokens");
        assertThat(body).containsEntry("temperature", 0.0);
        assertThat(body).containsEntry("model", "deepseek-v4-flash");
        assertThat(body.get("thinking")).isEqualTo(Map.of("type", "disabled"));
    }

    @Test
    void openai_moderne_envoie_max_completion_tokens_et_jamais_max_tokens() {
        Map<String, Object> body = corps(openAi("gpt-5.4"), "OpenAI");

        // « Unsupported parameter: 'max_tokens' is not supported with this model.
        //   Use 'max_completion_tokens' instead. » — 400 sur tous les gpt-5.x.
        assertThat(body).containsEntry("max_completion_tokens", 4000);
        assertThat(body).doesNotContainKey("max_tokens");
        assertThat(body).containsEntry("temperature", 0.0);
        assertThat(body).doesNotContainKey("thinking");
    }

    @Test
    void openai_ancienne_generation_reste_sur_max_tokens() {
        Map<String, Object> body = corps(openAi("gpt-4o-mini"), "OpenAI");

        assertThat(body).containsEntry("max_tokens", 4000);
        assertThat(body).doesNotContainKey("max_completion_tokens");
    }

    @Test
    void le_plafond_de_sortie_ne_change_pas_avec_le_nom_du_champ() {
        // Regle figee par EvaluationTokenBudgetTest : changer de correcteur ne
        // doit jamais changer, en douce, la longueur de reponse autorisee.
        Object plafondOpenAi = corps(openAi("gpt-5.4"), "OpenAI").get("max_completion_tokens");
        Object plafondDeepSeek = corps(deepSeek(), "DeepSeek").get("max_tokens");

        assertThat(plafondOpenAi).isEqualTo(plafondDeepSeek).isEqualTo(4000);
    }

    @Test
    void temperature_omise_quand_la_config_le_demande() {
        // Valeur « ne pas envoyer », distincte de 0 et de 1. Le cas NORMAL est la
        // negociation avec l'API (cf. OpenAiCompatibleEvalClientNegotiationTest) :
        // cette cle n'est qu'une reprise de main sans code.
        ProductionEvaluationProperties.OpenAi s = openAi("gpt-5.4");
        s.setSendTemperature("false");

        Map<String, Object> body = corps(s, "OpenAI");

        assertThat(body).doesNotContainKey("temperature");
        assertThat(body).containsEntry("max_completion_tokens", 4000);
    }

    @Test
    void changer_de_modele_suffit_a_changer_de_dialecte() {
        // L'exigence produit : une seule ligne de .env (EVAL_OPENAI_MODEL) doit
        // suffire, sans toucher au code ni au YAML. Sur les familles connues, le
        // raccourci evite meme l'aller-retour rate ; sur les autres, c'est la
        // negociation qui s'en charge au premier appel.
        assertThat(corps(openAi("gpt-4.1"), "OpenAI"))
            .containsEntry("max_tokens", 4000).containsEntry("temperature", 0.0);
        assertThat(corps(openAi("gpt-5.2"), "OpenAI"))
            .containsEntry("max_completion_tokens", 4000).containsEntry("temperature", 0.0);
        assertThat(corps(openAi("gpt-5.4-mini"), "OpenAI"))
            .containsEntry("max_completion_tokens", 4000).containsEntry("temperature", 0.0);
        assertThat(corps(openAi("o3-mini"), "OpenAI"))
            .containsEntry("max_completion_tokens", 4000);
    }

    @Test
    void une_valeur_forcee_en_config_l_emporte_sur_la_detection() {
        ProductionEvaluationProperties.OpenAi s = openAi("gpt-5.4");
        s.setMaxTokensParam("max_tokens");
        s.setSendTemperature("false");

        assertThat(corps(s, "OpenAI"))
            .containsEntry("max_tokens", 4000)
            .doesNotContainKey("temperature");
    }

    @Test
    void le_tool_choice_force_reste_identique_sur_les_deux_providers() {
        Map<String, Object> openai = corps(openAi("gpt-5.4"), "OpenAI");
        Map<String, Object> deepseek = corps(deepSeek(), "DeepSeek");

        assertThat(openai.get("tool_choice")).isEqualTo(deepseek.get("tool_choice"));
        assertThat(openai.get("tools")).isEqualTo(deepseek.get("tools"));
    }
}
