package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
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
 * Client REST pour tout provider compatible OpenAI (Chat Completions + function
 * calling) : OpenAI, DeepSeek, ou n'importe quel endpoint OpenAI-compatible. Le
 * provider concret est choisi par les {@link ChatCompletionSettings} injectes a
 * la construction (base URL, modele, cle, tarifs, prompt-version) — voir les
 * {@code @Bean} de {@code EvaluationLlmConfig}. Une instance = un provider.
 *
 * <p>Le tool schema est strictement le meme que celui d'Anthropic
 * ({@code prompts/production-evaluation-tool-schema-<version>.json}) — seule
 * l'enveloppe de la requete change (OpenAI : {@code tool_calls} dans le message
 * + {@code tool_choice} function).
 */
public class OpenAiCompatibleEvalClient implements EvaluationLlmClient {

    private static final Logger log = LoggerFactory.getLogger(OpenAiCompatibleEvalClient.class);
    private static final String TOOL_NAME = "submit_evaluation";
    private static final String TOOL_SCHEMA_PATH_FORMAT = "prompts/production-evaluation-tool-schema-%s.json";

    private final ChatCompletionSettings settings;
    /** Libelle lisible du provider (ex: "OpenAI", "DeepSeek") pour logs + erreurs. */
    private final String label;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public OpenAiCompatibleEvalClient(
            ChatCompletionSettings settings, String label, ObjectMapper objectMapper) {
        this.settings = settings;
        this.label = label;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
            .baseUrl(settings.getApiUrl())
            .requestFactory(buildRequestFactory(settings.getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        String version = settings.getPromptVersion();
        String path = String.format(TOOL_SCHEMA_PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("{} eval : tool schema {} charge ({})", label, TOOL_NAME, version);
    }

    @Override
    public String getModelName() {
        return settings.getModel();
    }

    @Override
    public String getPromptVersion() {
        return settings.getPromptVersion();
    }

    @Override
    @Retryable(
        retryFor = AiEvaluationTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public Outcome evaluate(String systemPrompt, String userPrompt) {
        if (!settings.isConfigured()) {
            throw new AiEvaluationException(
                label + " : cle API non configuree (sejourfr.production-evaluation."
                    + label.toLowerCase() + ".api-key)."
            );
        }

        Map<String, Object> body = buildRequestBody(systemPrompt, userPrompt);
        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("Authorization", "Bearer " + settings.getApiKey())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException(label + " eval 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AiEvaluationTransientException(label + " eval 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("{} eval 4xx : {} body={}", label, e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new AiEvaluationException(label + " eval 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AiEvaluationTransientException(label + " eval timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AiEvaluationException("Reponse " + label + " eval vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info(
            "{} eval OK input={} output={} duration={}ms",
            label, outcome.inputTokens(), outcome.outputTokens(), duration
        );
        return outcome;
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException ex, String systemPrompt, String userPrompt) {
        log.error("{} eval indisponible apres retries : {}", label, ex.getMessage());
        throw new AiEvaluationException(label + " eval indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException ex, String systemPrompt, String userPrompt) {
        throw ex;
    }

    private Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
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
        body.put("model", settings.getModel());
        body.put("max_tokens", settings.getMaxTokens());
        // 0 = deterministe : une evaluation doit donner les memes notes d'un run
        // a l'autre sur le meme texte (au defaut ~1.0 les scores varient bcp).
        body.put("temperature", settings.getTemperature());
        body.put("messages", List.of(systemMessage, userMessage));
        body.put("tools", List.of(tool));
        body.put("tool_choice", toolChoice);
        // DeepSeek V4 : le thinking mode (actif par defaut) refuse le tool_choice
        // force (400). On le desactive pour obtenir un tool_call deterministe.
        if (settings.isDisableThinking()) {
            body.put("thinking", Map.of("type", "disabled"));
        }
        return body;
    }

    private Outcome parseFunctionCallOutcome(JsonNode response) {
        JsonNode choices = response.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            throw new AiEvaluationException("Reponse " + label + " eval sans bloc choices");
        }
        JsonNode message = choices.get(0).path("message");
        JsonNode toolCalls = message.path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls dans la reponse " + label + " (finish_reason=" + finishReason + ")"
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

        // OpenAI/DeepSeek renvoient les arguments sous forme de STRING JSON,
        // contrairement a Anthropic qui renvoie un objet directement.
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
        double usd = 0;
        if (in != null)  usd += in  * (settings.getCostPerMillionInputTokens()  / 1_000_000.0);
        if (out != null) usd += out * (settings.getCostPerMillionOutputTokens() / 1_000_000.0);
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
