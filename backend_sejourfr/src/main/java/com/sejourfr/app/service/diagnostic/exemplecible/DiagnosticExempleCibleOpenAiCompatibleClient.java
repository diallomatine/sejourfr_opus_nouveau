package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
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
 * Client « avant / apres » du diagnostic pour tout fournisseur compatible OpenAI
 * (Chat Completions + function calling) : OpenAI, DeepSeek, ou tout endpoint
 * equivalent. Une instance = un fournisseur, choisi par les
 * {@link ChatCompletionSettings} injectes (cf.
 * {@code DiagnosticExempleCibleLlmConfig}).
 *
 * <p><b>Deux sources de reglages, volontairement.</b> La CONNEXION (URL, cle,
 * modele, timeout, tarifs, mode thinking) vient de
 * {@code sejourfr.production-evaluation.<provider>} : c'est le meme correcteur
 * que partout ailleurs. Le CONTRAT DE SORTIE et le budget de tokens viennent de
 * {@code sejourfr.diagnostic.exemple-cible} : la sortie attendue ici tient en un
 * numero, une phrase reecrite et deux ou trois etiquettes.
 *
 * <p><b>Aucun rejeu.</b> Toute erreur — 4xx, 5xx, timeout, reponse malformee —
 * remonte en {@link AiEvaluationException} et le service appelant l'avale. Seule
 * la NEGOCIATION DE FORME est rejouee (un 400 ou le fournisseur dit lui-meme quel
 * champ il refuse) : c'est ce qui permet de changer de modele sans toucher une
 * ligne de Java.
 */
public class DiagnosticExempleCibleOpenAiCompatibleClient
        implements DiagnosticExempleCibleLlmClient {

    private static final Logger log =
        LoggerFactory.getLogger(DiagnosticExempleCibleOpenAiCompatibleClient.class);

    private final ChatCompletionSettings connection;
    private final DiagnosticProperties.ExempleCible reglages;
    private final String label;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final ChatCompletionDialectNegotiator dialecte;
    private final Map<String, Object> toolSchema;

    public DiagnosticExempleCibleOpenAiCompatibleClient(
            ChatCompletionSettings connection,
            DiagnosticProperties.ExempleCible reglages,
            Map<String, Object> toolSchema,
            String label, ObjectMapper objectMapper) {
        this.connection = connection;
        this.reglages = reglages;
        this.toolSchema = toolSchema;
        this.label = label;
        this.objectMapper = objectMapper;
        this.dialecte = new ChatCompletionDialectNegotiator(
            label + " diagnostic exemple cible", connection.getModel(),
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
    public Outcome produire(String systemPrompt, String userPrompt) {
        if (!connection.isConfigured()) {
            throw new AiEvaluationException(
                label + " : cle API non configuree — bloc « avant / apres » ignore.");
        }

        long start = System.currentTimeMillis();
        JsonNode response = null;
        // Negociation de forme, PAS un rejeu : elle ne se rejoue que sur un 400
        // ou le fournisseur nomme le champ qu'il refuse.
        for (int tentative = 0; response == null; tentative++) {
            ChatCompletionDialect forme = dialecte.forme();
            Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt, forme);
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
                    label + " exemple cible 4xx (" + e.getStatusCode() + ")", e);
            } catch (RuntimeException e) {
                throw new AiEvaluationException(
                    label + " exemple cible indisponible : " + e.getMessage(), e);
            }
        }
        if (response == null) {
            throw new AiEvaluationException("Reponse " + label + " exemple cible vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info("{} diagnostic exemple cible OK input={} output={} duration={}ms",
            label, outcome.inputTokens(), outcome.outputTokens(),
            System.currentTimeMillis() - start);
        return outcome;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt,
                                         ChatCompletionDialect forme) {
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", DiagnosticExempleCibleFields.TOOL_NAME);
        function.put("description", DiagnosticExempleCibleFields.TOOL_DESCRIPTION);
        function.put("parameters", toolSchema);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        // Budget PROPRE a cet appel. Le NOM du champ, lui, est negocie avec le
        // fournisseur (cf. ChatCompletionDialectNegotiator).
        body.put(forme.maxTokensParam(), reglages.getMaxTokens());
        if (forme.sendTemperature()) {
            body.put("temperature", reglages.getTemperature());
        }
        body.put("messages", List.of(
            Map.of("role", "system", "content", systemPrompt),
            Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(Map.of("type", "function", "function", function)));
        body.put("tool_choice", Map.of(
            "type", "function", "function",
            Map.of("name", DiagnosticExempleCibleFields.TOOL_NAME)));
        // DeepSeek V4 : le thinking mode (actif par defaut) refuse le tool_choice
        // force (400). On le desactive pour obtenir un tool_call deterministe.
        if (connection.isDisableThinking()) {
            body.put("thinking", Map.of("type", "disabled"));
        }
        return body;
    }

    private Outcome parseFunctionCallOutcome(JsonNode response) {
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiEvaluationException("Reponse " + label + " exemple cible sans bloc choices");
        }
        JsonNode toolCalls = choices.get(0).path("message").path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls " + label + " exemple cible (finish_reason="
                    + finishReason + ")");
        }
        JsonNode call = null;
        for (JsonNode c : toolCalls) {
            if (DiagnosticExempleCibleFields.TOOL_NAME.equals(
                    c.path("function").path("name").asString())) {
                call = c;
                break;
            }
        }
        if (call == null) {
            throw new AiEvaluationException(
                "Aucune tool_call " + DiagnosticExempleCibleFields.TOOL_NAME + " dans la reponse");
        }

        // OpenAI/DeepSeek renvoient les arguments sous forme de STRING JSON,
        // contrairement a Anthropic qui renvoie un objet directement.
        String argsJson = call.path("function").path("arguments").asString();
        if (argsJson == null || argsJson.isBlank()) {
            throw new AiEvaluationException("tool_call.arguments vide (exemple cible)");
        }
        Map<String, Object> parsed;
        try {
            parsed = objectMapper.readValue(argsJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "tool_call.arguments non deserialisable (exemple cible) : " + e.getMessage(), e);
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
