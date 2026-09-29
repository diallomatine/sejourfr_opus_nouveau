package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.util.CoutAppelLlm;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import com.sejourfr.app.util.ChatCompletionDialect;
import com.sejourfr.app.util.ChatCompletionDialectNegotiator;
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
import org.springframework.stereotype.Component;
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
 * Appelle le fournisseur déjà sélectionné pour les productions, avec un outil
 * dédié au diagnostic. Le modèle reste unique ; seul le contrat change.
 */
@Component
public class ConfiguredDiagnosticAnalysisLlmClient implements DiagnosticAnalysisLlmClient {

    static final String TOOL_NAME = "submit_diagnostic_analysis";
    static final String TOOL_DESCRIPTION =
            "Soumet une analyse diagnostique structurée sans note sur 20 : accomplissement, "
            + "communication, niveau prudent et verdicts sur l'allowlist de compétences.";
    private static final String SCHEMA_PATH = "prompts/diagnostic-analysis-tool-schema-%s.json";
    private static final Logger log = LoggerFactory.getLogger(ConfiguredDiagnosticAnalysisLlmClient.class);

    private final ProductionEvaluationProperties productionProps;
    private final DiagnosticProperties.Analysis analysisProps;
    private final ObjectMapper objectMapper;
    private RestClient restClient;
    private ChatCompletionDialectNegotiator dialect;
    private Map<String, Object> toolSchema;

    public ConfiguredDiagnosticAnalysisLlmClient(
            ProductionEvaluationProperties productionProps,
            DiagnosticProperties diagnosticProps,
            ObjectMapper objectMapper) {
        this.productionProps = productionProps;
        this.analysisProps = diagnosticProps.getAnalysis();
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void initialize() {
        String path = String.format(SCHEMA_PATH, analysisProps.getToolSchemaVersion());
        try (InputStream input = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(input, StandardCharsets.UTF_8);
            toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("Contrat diagnostic introuvable : " + path, e);
        }

        if (isAnthropic()) {
            ProductionEvaluationProperties.Anthropic connection = productionProps.getAnthropic();
            restClient = client(connection.getApiUrl(), connection.getTimeoutSec());
        } else {
            ChatCompletionSettings connection = openAiConnection();
            restClient = client(connection.getApiUrl(), connection.getTimeoutSec());
            dialect = new ChatCompletionDialectNegotiator(
                    providerLabel() + " diagnostic", connection.getModel(),
                    connection.getMaxTokensParam(), connection.getSendTemperature());
        }
        log.info("Client diagnostic actif : provider={} model={} schema={}",
                productionProps.getProvider(), getModelName(), getToolSchemaVersion());
    }

    @Override
    public String getModelName() {
        return isAnthropic()
                ? productionProps.getAnthropic().getModel()
                : openAiConnection().getModel();
    }

    @Override
    public String getToolSchemaVersion() { return analysisProps.getToolSchemaVersion(); }

    @Override
    @Retryable(
            retryFor = AiEvaluationTransientException.class,
            maxAttempts = 3,
            backoff = @Backoff(delay = 1000, multiplier = 2, random = true))
    public Outcome analyse(String systemPrompt, String userPrompt) {
        return isAnthropic()
                ? analyseAnthropic(systemPrompt, userPrompt)
                : analyseOpenAi(systemPrompt, userPrompt);
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException exception, String systemPrompt, String userPrompt) {
        throw new AiEvaluationException("Analyse diagnostic indisponible après plusieurs tentatives", exception);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException exception, String systemPrompt, String userPrompt) {
        throw exception;
    }

    private Outcome analyseOpenAi(String systemPrompt, String userPrompt) {
        ChatCompletionSettings connection = openAiConnection();
        if (!connection.isConfigured()) {
            throw new AiEvaluationException(providerLabel() + " : clé API non configurée pour le diagnostic");
        }

        JsonNode response;
        for (int tentative = 0; ; tentative++) {
            ChatCompletionDialect forme = dialect.forme();
            try {
                response = restClient.post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + connection.getApiKey())
                        .body(buildOpenAiBody(systemPrompt, userPrompt, connection, forme))
                        .retrieve()
                        .body(JsonNode.class);
                break;
            } catch (HttpClientErrorException.TooManyRequests e) {
                throw new AiEvaluationTransientException(providerLabel() + " diagnostic 429", e);
            } catch (HttpServerErrorException | ResourceAccessException e) {
                throw new AiEvaluationTransientException(providerLabel() + " diagnostic indisponible", e);
            } catch (HttpClientErrorException e) {
                if (tentative < ChatCompletionDialectNegotiator.MAX_RENEGOCIATIONS
                        && dialect.adapte(forme, e.getResponseBodyAsString())) {
                    continue;
                }
                throw new AiEvaluationException(
                        providerLabel() + " diagnostic 4xx (" + e.getStatusCode() + ")", e);
            }
        }
        if (response == null) {
            throw new AiEvaluationTransientException("Réponse diagnostic vide");
        }
        return parseOpenAi(response, connection);
    }

    private Map<String, Object> buildOpenAiBody(
            String systemPrompt, String userPrompt, ChatCompletionSettings connection,
            ChatCompletionDialect forme) {
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", TOOL_NAME);
        function.put("description", TOOL_DESCRIPTION);
        function.put("parameters", toolSchema);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        body.put(forme.maxTokensParam(), analysisProps.getMaxTokens());
        if (forme.sendTemperature()) body.put("temperature", analysisProps.getTemperature());
        body.put("messages", List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(Map.of("type", "function", "function", function)));
        body.put("tool_choice", Map.of(
                "type", "function", "function", Map.of("name", TOOL_NAME)));
        if (connection.isDisableThinking()) body.put("thinking", Map.of("type", "disabled"));
        return body;
    }

    private Outcome parseOpenAi(JsonNode response, ChatCompletionSettings connection) {
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiEvaluationTransientException("Réponse diagnostic sans choices");
        }
        JsonNode calls = choices.get(0).path("message").path("tool_calls");
        JsonNode selected = null;
        if (calls.isArray()) {
            for (JsonNode call : calls) {
                if (TOOL_NAME.equals(call.path("function").path("name").asString())) {
                    selected = call;
                    break;
                }
            }
        }
        if (selected == null) {
            throw new AiEvaluationTransientException("Réponse diagnostic sans " + TOOL_NAME);
        }
        String arguments = selected.path("function").path("arguments").asString();
        Map<String, Object> parsed;
        try {
            parsed = objectMapper.readValue(arguments, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationTransientException("Sortie diagnostic non désérialisable", e);
        }
        JsonNode usage = response.path("usage");
        Integer in = usage.hasNonNull("prompt_tokens") ? usage.get("prompt_tokens").asInt() : null;
        Integer out = usage.hasNonNull("completion_tokens") ? usage.get("completion_tokens").asInt() : null;
        // Le decoupage cache hit / cache miss est RENVOYE par le fournisseur :
        // on le lit, on ne le devine pas. Absent -> tout au plein tarif.
        Integer cacheHit = CoutAppelLlm.lireCacheHitTokens(usage);
        return new Outcome(parsed, in, cacheHit, out,
                new CoutAppelLlm(connection).microDollars(in, cacheHit, out));
    }

    private Outcome analyseAnthropic(String systemPrompt, String userPrompt) {
        ProductionEvaluationProperties.Anthropic connection = productionProps.getAnthropic();
        if (!connection.isConfigured()) {
            throw new AiEvaluationException("Anthropic : clé API non configurée pour le diagnostic");
        }
        JsonNode response;
        try {
            response = restClient.post()
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("x-api-key", connection.getApiKey())
                    .header("anthropic-version", connection.getAnthropicVersion())
                    .body(buildAnthropicBody(systemPrompt, userPrompt, connection))
                    .retrieve()
                    .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException("Anthropic diagnostic 429", e);
        } catch (HttpServerErrorException | ResourceAccessException e) {
            throw new AiEvaluationTransientException("Anthropic diagnostic indisponible", e);
        } catch (HttpClientErrorException e) {
            throw new AiEvaluationException("Anthropic diagnostic 4xx (" + e.getStatusCode() + ")", e);
        }
        if (response == null) {
            throw new AiEvaluationTransientException("Réponse Anthropic diagnostic vide");
        }
        return parseAnthropic(response, connection);
    }

    private Map<String, Object> buildAnthropicBody(
            String systemPrompt, String userPrompt, ProductionEvaluationProperties.Anthropic connection) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", TOOL_NAME);
        tool.put("description", TOOL_DESCRIPTION);
        tool.put("input_schema", toolSchema);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        body.put("max_tokens", analysisProps.getMaxTokens());
        body.put("temperature", analysisProps.getTemperature());
        body.put("system", List.of(Map.of("type", "text", "text", systemPrompt,
                "cache_control", Map.of("type", "ephemeral"))));
        body.put("messages", List.of(Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(tool));
        body.put("tool_choice", Map.of("type", "tool", "name", TOOL_NAME));
        return body;
    }

    private Outcome parseAnthropic(JsonNode response, ProductionEvaluationProperties.Anthropic connection) {
        JsonNode selected = null;
        JsonNode content = response.path("content");
        if (content.isArray()) {
            for (JsonNode block : content) {
                if ("tool_use".equals(block.path("type").asString())
                        && TOOL_NAME.equals(block.path("name").asString())) {
                    selected = block;
                    break;
                }
            }
        }
        if (selected == null) {
            throw new AiEvaluationTransientException("Réponse Anthropic sans " + TOOL_NAME);
        }
        Map<String, Object> parsed;
        try {
            parsed = objectMapper.treeToValue(
                    selected.path("input"), new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationTransientException("Sortie Anthropic diagnostic non désérialisable", e);
        }
        JsonNode usage = response.path("usage");
        Integer out = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;
        // Anthropic est le SEUL appel du depot qui demande vraiment du cache
        // (`cache_control: ephemeral` sur le bloc systeme, cf. buildAnthropicBody),
        // et il compte a part : `input_tokens` EXCLUT les tokens lus dans le
        // cache et ceux qui viennent de l'y ecrire. On recompose donc le total,
        // et on laisse la lecture de cache au tarif d'entree plein tant que le
        // bloc anthropic ne declare pas de tarif de cache : on surestime,
        // jamais l'inverse.
        int entreePleine = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : 0;
        int cacheLu = usage.hasNonNull("cache_read_input_tokens")
                ? usage.get("cache_read_input_tokens").asInt() : 0;
        int cacheEcrit = usage.hasNonNull("cache_creation_input_tokens")
                ? usage.get("cache_creation_input_tokens").asInt() : 0;
        Integer in = entreePleine + cacheLu + cacheEcrit == 0
                ? null : entreePleine + cacheLu + cacheEcrit;
        Integer cacheHit = cacheLu == 0 ? null : cacheLu;
        return new Outcome(parsed, in, cacheHit, out,
                new CoutAppelLlm(connection).microDollars(in, cacheHit, out));
    }

    private ChatCompletionSettings openAiConnection() {
        return switch (normalizedProvider()) {
            case "openai" -> productionProps.getOpenai();
            case "deepseek" -> productionProps.getDeepseek();
            default -> throw new IllegalStateException(
                    "Provider diagnostic non supporté : " + productionProps.getProvider());
        };
    }

    private boolean isAnthropic() { return "anthropic".equals(normalizedProvider()); }

    private String normalizedProvider() {
        return productionProps.getProvider() == null
                ? "" : productionProps.getProvider().trim().toLowerCase();
    }

    private String providerLabel() {
        return "openai".equals(normalizedProvider()) ? "OpenAI" : "DeepSeek";
    }

    private static RestClient client(String baseUrl, int timeoutSec) {
        return RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(requestFactory(timeoutSec))
                .build();
    }

    private static ClientHttpRequestFactory requestFactory(int timeoutSec) {
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)))
                .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }
}
