package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
import com.sejourfr.app.config.ProductionEvaluationProperties.VersionCiblee;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.util.ChatCompletionDialect;
import com.sejourfr.app.util.ChatCompletionDialectNegotiator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Client « version au niveau visé » pour tout fournisseur compatible OpenAI
 * (Chat Completions + function calling) : OpenAI, DeepSeek, ou tout endpoint
 * équivalent. Une instance = un fournisseur, choisi par les
 * {@link ChatCompletionSettings} injectés (cf. {@code VersionCibleeLlmConfig}).
 *
 * <p><b>Deux sources de réglages, volontairement.</b> La CONNEXION (URL, clé,
 * modèle, timeout, tarifs, mode thinking) vient de
 * {@code sejourfr.production-evaluation.<provider>} : c'est le même correcteur
 * que celui des productions complètes. Le CONTRAT DE SORTIE et le budget de
 * tokens viennent de {@code sejourfr.production-evaluation.version-ciblee} : la
 * sortie attendue ici tient en un texte court et deux ou trois phrases.
 *
 * <p><b>Aucun rejeu.</b> Toute erreur — 4xx, 5xx, timeout, réponse malformée —
 * remonte en {@link AiEvaluationException} et le service appelant l'avale.
 * Seule la NÉGOCIATION DE FORME est rejouée (un 400 où le fournisseur dit
 * lui-même quel champ il refuse) : c'est ce qui permet de changer de modèle sans
 * toucher une ligne de Java.
 */
public class VersionCibleeOpenAiCompatibleClient implements VersionCibleeLlmClient {

    private static final Logger log =
        LoggerFactory.getLogger(VersionCibleeOpenAiCompatibleClient.class);

    private final ChatCompletionSettings connection;
    private final VersionCiblee reglages;
    private final String label;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final ChatCompletionDialectNegotiator dialecte;
    private final VersionCibleeTools tools;

    public VersionCibleeOpenAiCompatibleClient(ChatCompletionSettings connection,
                                               VersionCiblee reglages,
                                               VersionCibleeTools tools,
                                               String label, ObjectMapper objectMapper) {
        this.connection = connection;
        this.reglages = reglages;
        this.tools = tools;
        this.label = label;
        this.objectMapper = objectMapper;
        this.dialecte = new ChatCompletionDialectNegotiator(
            label + " version ciblee", connection.getModel(),
            connection.getMaxTokensParam(), connection.getSendTemperature());
        this.restClient = RestClient.builder()
            .baseUrl(connection.getApiUrl())
            .requestFactory(buildRequestFactory(connection.getTimeoutSec()))
            .build();
    }

    @Override
    public String getModelName() {
        return connection.getModel();
    }

    @Override
    public String getToolSchemaVersion() {
        return reglages.getToolSchemaVersion();
    }

    @Override
    public Outcome produire(String systemPrompt, String userPrompt,
                            VersionCibleeVariante variante) {
        if (!connection.isConfigured()) {
            throw new AiEvaluationException(
                label + " : cle API non configuree — version ciblee ignoree.");
        }

        long start = System.currentTimeMillis();
        JsonNode response = null;
        // Négociation de forme, PAS un rejeu : elle ne se rejoue que sur un 400
        // où le fournisseur nomme le champ qu'il refuse.
        for (int tentative = 0; response == null; tentative++) {
            ChatCompletionDialect forme = dialecte.forme();
            Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt, forme, variante);
            try {
                response = restClient.post()
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + connection.getApiKey())
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
            } catch (HttpClientErrorException e) {
                String corps = e.getResponseBodyAsString();
                if (tentative < ChatCompletionDialectNegotiator.MAX_RENEGOCIATIONS
                        && dialecte.adapte(forme, corps)) {
                    continue;
                }
                throw new AiEvaluationException(
                    label + " version ciblee 4xx (" + e.getStatusCode() + ")", e);
            } catch (RuntimeException e) {
                throw new AiEvaluationException(
                    label + " version ciblee indisponible : " + e.getMessage(), e);
            }
        }
        if (response == null) {
            throw new AiEvaluationException("Reponse " + label + " version ciblee vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info("{} version ciblee OK input={} output={} duration={}ms",
            label, outcome.inputTokens(), outcome.outputTokens(),
            System.currentTimeMillis() - start);
        return outcome;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt,
                                         ChatCompletionDialect forme,
                                         VersionCibleeVariante variante) {
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", VersionCibleeFields.TOOL_NAME);
        function.put("description", tools.description(variante));
        function.put("parameters", tools.schema(variante));

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        // Budget PROPRE à cet appel, pas les 4000 d'une correction complète. Le
        // NOM du champ, lui, est négocié avec le fournisseur.
        body.put(forme.maxTokensParam(), reglages.getMaxTokens());
        if (forme.sendTemperature()) {
            body.put("temperature", reglages.getTemperature());
        }
        body.put("messages", List.of(
            Map.of("role", "system", "content", systemPrompt),
            Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(Map.of("type", "function", "function", function)));
        body.put("tool_choice", Map.of(
            "type", "function", "function", Map.of("name", VersionCibleeFields.TOOL_NAME)));
        if (connection.isDisableThinking()) {
            body.put("thinking", Map.of("type", "disabled"));
        }
        return body;
    }

    private Outcome parseFunctionCallOutcome(JsonNode response) {
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiEvaluationException("Reponse " + label + " version ciblee sans bloc choices");
        }
        JsonNode toolCalls = choices.get(0).path("message").path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls " + label + " version ciblee (finish_reason=" + finishReason + ")");
        }
        JsonNode call = null;
        for (JsonNode c : toolCalls) {
            if (VersionCibleeFields.TOOL_NAME.equals(c.path("function").path("name").asString())) {
                call = c;
                break;
            }
        }
        if (call == null) {
            throw new AiEvaluationException(
                "Aucune tool_call " + VersionCibleeFields.TOOL_NAME + " dans la reponse");
        }

        // OpenAI/DeepSeek renvoient les arguments sous forme de STRING JSON,
        // contrairement a Anthropic qui renvoie un objet directement.
        String argsJson = call.path("function").path("arguments").asString();
        if (argsJson == null || argsJson.isBlank()) {
            throw new AiEvaluationException("tool_call.arguments vide (version ciblee)");
        }
        Map<String, Object> parsed;
        try {
            parsed = objectMapper.readValue(argsJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "tool_call.arguments non deserialisable (version ciblee) : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer in = usage.hasNonNull("prompt_tokens") ? usage.get("prompt_tokens").asInt() : null;
        Integer out = usage.hasNonNull("completion_tokens")
            ? usage.get("completion_tokens").asInt() : null;
        return new Outcome(parsed, in, out, estimateCostCents(in, out));
    }

    private Integer estimateCostCents(Integer in, Integer out) {
        double usd = 0;
        if (in != null) usd += in * (connection.getCostPerMillionInputTokens() / 1_000_000.0);
        if (out != null) usd += out * (connection.getCostPerMillionOutputTokens() / 1_000_000.0);
        if (usd <= 0) return null;
        return (int) Math.ceil(usd * 100.0);
    }

    private static ClientHttpRequestFactory buildRequestFactory(int timeoutSec) {
        HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)))
            .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }
}
