package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.util.StreamUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Client REST Anthropic dedie a l'evaluation des productions (EO/EE).
 * Utilise un outil {@code submit_evaluation} via {@code tool_use} pour forcer
 * un JSON valide. Distinct de {@code AnthropicClient} (audioquestion/) qui sert
 * a generer des questions audio CO.
 */
@Service
public class EvaluationAnthropicClient {

    private static final Logger log = LoggerFactory.getLogger(EvaluationAnthropicClient.class);
    private static final String TOOL_NAME = "submit_evaluation";
    private static final String TOOL_SCHEMA_PATH = "prompts/production-evaluation-tool-schema.json";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public EvaluationAnthropicClient(ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
            .baseUrl(props.getAnthropic().getApiUrl())
            .requestFactory(buildRequestFactory(props.getAnthropic().getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        try (InputStream is = new ClassPathResource(TOOL_SCHEMA_PATH).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("Tool schema submit_evaluation charge ({} cles)", toolSchema.size());
    }

    // Retry strategie : 3 tentatives totales (1 initiale + 2 retries) avec
    // backoff exponentiel + jitter, conforme spec section 2.3.a.
    @Retryable(
        retryFor = AiEvaluationTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public Outcome evaluate(String systemPrompt, String userPrompt) {
        ProductionEvaluationProperties.Anthropic a = props.getAnthropic();
        if (!a.isConfigured()) {
            throw new AiEvaluationException(
                "ANTHROPIC_API_KEY non configuree (sejourfr.production-evaluation.anthropic.api-key)."
            );
        }

        Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt);
        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("x-api-key", a.getApiKey())
                .header("anthropic-version", a.getAnthropicVersion())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException("Anthropic eval 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AiEvaluationTransientException("Anthropic eval 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("Anthropic eval 4xx : {} body={}", e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new AiEvaluationException("Anthropic eval 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AiEvaluationTransientException("Anthropic eval timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AiEvaluationException("Reponse Anthropic eval vide");
        }

        Outcome outcome = parseToolUseOutcome(response);
        log.info(
            "Anthropic eval OK input={} output={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), duration
        );
        return outcome;
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException ex, String systemPrompt, String userPrompt) {
        log.error("Anthropic eval indisponible apres retries : {}", ex.getMessage());
        throw new AiEvaluationException("Anthropic eval indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException ex, String systemPrompt, String userPrompt) {
        throw ex;
    }

    private Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
        ProductionEvaluationProperties.Anthropic a = props.getAnthropic();
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", TOOL_NAME);
        tool.put("description",
            "Soumet l'evaluation structuree d'une production TCF IRN : note globale, niveau CECRL, "
            + "scores detailles par critere, points forts, points a ameliorer, suggestions et "
            + "exemples corriges. Utilise systematiquement cet outil, jamais de texte libre.");
        tool.put("input_schema", toolSchema);

        Map<String, Object> systemBlock = Map.of(
            "type", "text",
            "text", systemPrompt,
            "cache_control", Map.of("type", "ephemeral")
        );

        Map<String, Object> userMessage = Map.of(
            "role", "user",
            "content", userPrompt
        );

        Map<String, Object> toolChoice = Map.of("type", "tool", "name", TOOL_NAME);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", a.getModel());
        body.put("max_tokens", a.getMaxTokens());
        body.put("system", List.of(systemBlock));
        body.put("messages", List.of(userMessage));
        body.put("tools", List.of(tool));
        body.put("tool_choice", toolChoice);
        return body;
    }

    private Outcome parseToolUseOutcome(JsonNode response) {
        JsonNode content = response.path("content");
        if (!content.isArray() || content.isEmpty()) {
            throw new AiEvaluationException("Reponse Anthropic eval sans bloc content");
        }
        JsonNode toolBlock = null;
        for (JsonNode block : content) {
            String type = block.hasNonNull("type") ? block.get("type").asString() : null;
            String name = block.hasNonNull("name") ? block.get("name").asString() : null;
            if ("tool_use".equals(type) && TOOL_NAME.equals(name)) {
                toolBlock = block;
                break;
            }
        }
        if (toolBlock == null) {
            String stopReason = response.hasNonNull("stop_reason") ? response.get("stop_reason").asString() : "unknown";
            throw new AiEvaluationException("Pas de bloc tool_use " + TOOL_NAME + " (stop_reason=" + stopReason + ")");
        }
        JsonNode input = toolBlock.path("input");
        if (input.isMissingNode() || input.isNull()) {
            throw new AiEvaluationException("Bloc tool_use sans champ input");
        }

        Map<String, Object> parsed;
        try {
            parsed = objectMapper.treeToValue(input, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException("Input du tool_use non desorialisable : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer inputTokens = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : null;
        Integer outputTokens = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;

        return new Outcome(parsed, inputTokens, outputTokens);
    }

    private static ClientHttpRequestFactory buildRequestFactory(int timeoutSec) {
        HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)))
            .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }

    private static String preview(String s) {
        if (s == null) return "";
        return s.length() > 200 ? s.substring(0, 200) + "..." : s;
    }

    public record Outcome(Map<String, Object> feedback, Integer inputTokens, Integer outputTokens) {}
}
