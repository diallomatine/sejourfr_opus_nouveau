package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.util.CoutAppelLlm;
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
 * Client d'analyse ciblee Anthropic ({@code tool_use} force sur
 * {@code submit_competence_analysis}).
 *
 * <p>Meme partage de reglages que le client compatible OpenAI : la CONNEXION
 * vient de {@code sejourfr.production-evaluation.anthropic}, le CONTRAT DE
 * SORTIE et le budget de tokens de {@code sejourfr.competences.analysis}.
 */
public class CompetenceAnthropicClient implements CompetenceAnalysisLlmClient {

    private static final Logger log = LoggerFactory.getLogger(CompetenceAnthropicClient.class);

    private final ProductionEvaluationProperties.Anthropic connection;
    private final CompetenceProperties.Analysis analysis;
    /** Seul endroit qui sait ce que coute un appel : trois tarifs + heures pleines. */
    private final CoutAppelLlm tarification;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public CompetenceAnthropicClient(ProductionEvaluationProperties.Anthropic connection,
                                     CompetenceProperties.Analysis analysis,
                                     ObjectMapper objectMapper) {
        this.connection = connection;
        this.tarification = new CoutAppelLlm(connection);
        this.analysis = analysis;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
            .baseUrl(connection.getApiUrl())
            .requestFactory(buildRequestFactory(connection.getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        String version = analysis.getToolSchemaVersion();
        String path = String.format(
            CompetenceOpenAiCompatibleClient.TOOL_SCHEMA_PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("Anthropic analyse competence : tool schema {} charge ({})",
            CompetenceOpenAiCompatibleClient.TOOL_NAME, version);
    }

    @Override
    public String getModelName() {
        return connection.getModel();
    }

    @Override
    public String getToolSchemaVersion() {
        return analysis.getToolSchemaVersion();
    }

    @Override
    @Retryable(
        retryFor = AiEvaluationTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public Outcome analyse(String systemPrompt, String userPrompt) {
        if (!connection.isConfigured()) {
            throw new AiEvaluationException(
                "ANTHROPIC_API_KEY non configuree (sejourfr.production-evaluation.anthropic.api-key).");
        }

        Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt);
        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("x-api-key", connection.getApiKey())
                .header("anthropic-version", connection.getAnthropicVersion())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException("Anthropic analyse 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AiEvaluationTransientException(
                "Anthropic analyse 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("Anthropic analyse 4xx : {} body={}", e.getStatusCode(),
                preview(e.getResponseBodyAsString()));
            throw new AiEvaluationException("Anthropic analyse 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AiEvaluationTransientException("Anthropic analyse timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AiEvaluationException("Reponse Anthropic analyse vide");
        }

        Outcome outcome = parseToolUseOutcome(response);
        log.info("Anthropic analyse competence OK input={} output={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), duration);
        return outcome;
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException ex, String systemPrompt, String userPrompt) {
        log.error("Anthropic analyse competence indisponible apres retries : {}", ex.getMessage());
        throw new AiEvaluationException(
            "Anthropic analyse indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException ex, String systemPrompt, String userPrompt) {
        throw ex;
    }

    private Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", CompetenceOpenAiCompatibleClient.TOOL_NAME);
        tool.put("description", CompetenceOpenAiCompatibleClient.TOOL_DESCRIPTION);
        tool.put("input_schema", toolSchema);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        body.put("max_tokens", analysis.getMaxTokens());
        body.put("temperature", analysis.getTemperature());
        // Le system prompt est identique pour tous les sujets : il est cachable.
        body.put("system", List.of(Map.of(
            "type", "text",
            "text", systemPrompt,
            "cache_control", Map.of("type", "ephemeral"))));
        body.put("messages", List.of(Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(tool));
        body.put("tool_choice", Map.of(
            "type", "tool", "name", CompetenceOpenAiCompatibleClient.TOOL_NAME));
        return body;
    }

    private Outcome parseToolUseOutcome(JsonNode response) {
        JsonNode content = response.path("content");
        if (!content.isArray() || content.isEmpty()) {
            throw new AiEvaluationException("Reponse Anthropic analyse sans bloc content");
        }
        JsonNode toolBlock = null;
        for (JsonNode block : content) {
            String type = block.hasNonNull("type") ? block.get("type").asString() : null;
            String name = block.hasNonNull("name") ? block.get("name").asString() : null;
            if ("tool_use".equals(type)
                    && CompetenceOpenAiCompatibleClient.TOOL_NAME.equals(name)) {
                toolBlock = block;
                break;
            }
        }
        if (toolBlock == null) {
            String stopReason = response.hasNonNull("stop_reason")
                ? response.get("stop_reason").asString() : "unknown";
            throw new AiEvaluationException("Pas de bloc tool_use "
                + CompetenceOpenAiCompatibleClient.TOOL_NAME + " (stop_reason=" + stopReason + ")");
        }
        JsonNode input = toolBlock.path("input");
        if (input.isMissingNode() || input.isNull()) {
            throw new AiEvaluationException("Bloc tool_use sans champ input");
        }

        Map<String, Object> parsed;
        try {
            parsed = objectMapper.treeToValue(input, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "Input du tool_use non deserialisable : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer inputTokens = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : null;
        Integer outputTokens = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;
        // Anthropic ne sert du cache que si la requete le demande (`cache_control`),
        // ce que nous ne faisons pas : aucun token n'est jamais servi par le cache.
        Integer cacheHit = null;
        return new Outcome(parsed, inputTokens, cacheHit, outputTokens,
            tarification.microDollars(inputTokens, cacheHit, outputTokens));
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
}
