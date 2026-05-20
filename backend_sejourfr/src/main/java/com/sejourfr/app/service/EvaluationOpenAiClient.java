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
 * Client REST OpenAI (Chat Completions + function calling) dedie a l'evaluation
 * des productions (EO/EE). Implementation alternative a {@link EvaluationAnthropicClient},
 * activable via {@code sejourfr.production-evaluation.provider=openai}.
 *
 * <p>Le tool schema utilise est strictement le meme que celui d'Anthropic
 * ({@code prompts/production-evaluation-tool-schema.json}) — seule l'enveloppe
 * de la requete change :
 * <ul>
 *   <li>Anthropic : {@code tool_use} dans le content + {@code tool_choice} typeT</li>
 *   <li>OpenAI    : {@code tool_calls} dans le message + {@code tool_choice} function</li>
 * </ul>
 */
@Service("evaluationOpenAiClient")
public class EvaluationOpenAiClient implements EvaluationLlmClient {

    private static final Logger log = LoggerFactory.getLogger(EvaluationOpenAiClient.class);
    private static final String TOOL_NAME = "submit_evaluation";
    private static final String TOOL_SCHEMA_PATH = "prompts/production-evaluation-tool-schema.json";

    private final ProductionEvaluationProperties props;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public EvaluationOpenAiClient(ProductionEvaluationProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
            .baseUrl(props.getOpenai().getApiUrl())
            .requestFactory(buildRequestFactory(props.getOpenai().getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        try (InputStream is = new ClassPathResource(TOOL_SCHEMA_PATH).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("OpenAI eval : tool schema {} charge", TOOL_NAME);
    }

    @Override
    public String getModelName() {
        return props.getOpenai().getModel();
    }

    @Override
    public String getPromptVersion() {
        return props.getOpenai().getPromptVersion();
    }

    @Override
    @Retryable(
        retryFor = AiEvaluationTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public Outcome evaluate(String systemPrompt, String userPrompt) {
        ProductionEvaluationProperties.OpenAi o = props.getOpenai();
        if (!o.isConfigured()) {
            throw new AiEvaluationException(
                "OPENAI_API_KEY non configuree (sejourfr.production-evaluation.openai.api-key)."
            );
        }

        Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt);
        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("Authorization", "Bearer " + o.getApiKey())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException("OpenAI eval 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AiEvaluationTransientException("OpenAI eval 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("OpenAI eval 4xx : {} body={}", e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new AiEvaluationException("OpenAI eval 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AiEvaluationTransientException("OpenAI eval timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AiEvaluationException("Reponse OpenAI eval vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info(
            "OpenAI eval OK input={} output={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), duration
        );
        return outcome;
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException ex, String systemPrompt, String userPrompt) {
        log.error("OpenAI eval indisponible apres retries : {}", ex.getMessage());
        throw new AiEvaluationException("OpenAI eval indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException ex, String systemPrompt, String userPrompt) {
        throw ex;
    }

    private Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
        ProductionEvaluationProperties.OpenAi o = props.getOpenai();

        // function = { name, description, parameters: <JSON Schema> }
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", TOOL_NAME);
        function.put("description",
            "Soumet l'evaluation structuree d'une production TCF IRN : note globale, niveau CECRL, "
            + "scores detailles par critere, points forts, points a ameliorer, suggestions et "
            + "exemples corriges. Utilise systematiquement cette fonction, jamais de texte libre.");
        function.put("parameters", toolSchema);

        Map<String, Object> tool = Map.of(
            "type", "function",
            "function", function
        );

        Map<String, Object> toolChoice = Map.of(
            "type", "function",
            "function", Map.of("name", TOOL_NAME)
        );

        Map<String, Object> systemMessage = Map.of("role", "system", "content", systemPrompt);
        Map<String, Object> userMessage = Map.of("role", "user", "content", userPrompt);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", o.getModel());
        body.put("max_tokens", o.getMaxTokens());
        body.put("messages", List.of(systemMessage, userMessage));
        body.put("tools", List.of(tool));
        body.put("tool_choice", toolChoice);
        return body;
    }

    private Outcome parseFunctionCallOutcome(JsonNode response) {
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiEvaluationException("Reponse OpenAI eval sans bloc choices");
        }
        JsonNode message = choices.get(0).path("message");
        JsonNode toolCalls = message.path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls dans la reponse OpenAI (finish_reason=" + finishReason + ")"
            );
        }

        // On prend la 1ere tool_call qui match notre fonction (en pratique il
        // n'y en aura qu'une, vu qu'on force tool_choice).
        JsonNode call = null;
        for (JsonNode c : toolCalls) {
            String name = c.path("function").path("name").asString();
            if (TOOL_NAME.equals(name)) { call = c; break; }
        }
        if (call == null) {
            throw new AiEvaluationException("Aucune tool_call " + TOOL_NAME + " dans la reponse");
        }

        // OpenAI renvoie les arguments sous forme de STRING JSON, contrairement
        // a Anthropic qui renvoie un objet directement.
        String argsJson = call.path("function").path("arguments").asString();
        if (argsJson == null || argsJson.isBlank()) {
            throw new AiEvaluationException("tool_call.arguments vide");
        }

        Map<String, Object> parsed;
        try {
            parsed = objectMapper.readValue(argsJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "tool_call.arguments non desorialisable : " + e.getMessage(), e
            );
        }

        JsonNode usage = response.path("usage");
        Integer inputTokens  = usage.hasNonNull("prompt_tokens")     ? usage.get("prompt_tokens").asInt()     : null;
        Integer outputTokens = usage.hasNonNull("completion_tokens") ? usage.get("completion_tokens").asInt() : null;
        Integer cost = estimateCostCents(inputTokens, outputTokens);

        return new Outcome(parsed, inputTokens, outputTokens, cost);
    }

    private Integer estimateCostCents(Integer in, Integer out) {
        ProductionEvaluationProperties.OpenAi o = props.getOpenai();
        double usd = 0;
        if (in != null)  usd += in  * (o.getCostPerMillionInputTokens()  / 1_000_000.0);
        if (out != null) usd += out * (o.getCostPerMillionOutputTokens() / 1_000_000.0);
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

    private static String preview(String s) {
        if (s == null) return "";
        return s.length() > 200 ? s.substring(0, 200) + "..." : s;
    }
}
