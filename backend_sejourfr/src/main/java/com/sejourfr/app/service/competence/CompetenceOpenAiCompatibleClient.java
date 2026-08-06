package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.AiEvaluationTransientException;
import com.sejourfr.app.util.ChatCompletionDialect;
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
 * Client d'analyse ciblee pour tout fournisseur compatible OpenAI (Chat
 * Completions + function calling) : OpenAI, DeepSeek, ou tout endpoint
 * equivalent. Une instance = un fournisseur, choisi par les
 * {@link ChatCompletionSettings} injectes — voir {@code CompetenceLlmConfig}.
 *
 * <p><b>Deux sources de reglages, volontairement.</b> La CONNEXION (URL, cle,
 * modele, timeout, tarifs, mode thinking) vient de
 * {@code sejourfr.production-evaluation.<provider>} : c'est le meme correcteur
 * que celui des productions completes. Le CONTRAT DE SORTIE (tool-schema) et le
 * budget de tokens viennent de {@code sejourfr.competences.analysis} : la sortie
 * attendue ici tient en cinq champs courts, elle n'a rien a voir avec une
 * correction complete.
 */
public class CompetenceOpenAiCompatibleClient implements CompetenceAnalysisLlmClient {

    private static final Logger log = LoggerFactory.getLogger(CompetenceOpenAiCompatibleClient.class);
    static final String TOOL_NAME = "submit_competence_analysis";
    static final String TOOL_SCHEMA_PATH_FORMAT = "prompts/competence-analysis-tool-schema-%s.json";
    static final String TOOL_DESCRIPTION =
        "Soumet l'analyse ciblee d'une production de competence TCF IRN : verdict sur le critere "
        + "unique, point reussi, priorite d'amelioration unique et reformulation. Aucune note, "
        + "aucun niveau CECRL. Utilise systematiquement cette fonction, jamais de texte libre.";

    private final ChatCompletionSettings connection;
    private final CompetenceProperties.Analysis analysis;
    /** Libelle lisible du fournisseur ("OpenAI", "DeepSeek") pour logs + erreurs. */
    private final String label;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public CompetenceOpenAiCompatibleClient(ChatCompletionSettings connection,
                                            CompetenceProperties.Analysis analysis,
                                            String label, ObjectMapper objectMapper) {
        this.connection = connection;
        this.analysis = analysis;
        this.label = label;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
            .baseUrl(connection.getApiUrl())
            .requestFactory(buildRequestFactory(connection.getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        String version = analysis.getToolSchemaVersion();
        String path = String.format(TOOL_SCHEMA_PATH_FORMAT, version);
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("{} analyse competence : tool schema {} charge ({})", label, TOOL_NAME, version);
        log.info("{} analyse competence : {}", label, ChatCompletionDialect.resume(
            connection.getMaxTokensParam(), connection.getSendTemperature(), connection.getModel()));
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
                .header("Authorization", "Bearer " + connection.getApiKey())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AiEvaluationTransientException(label + " analyse 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AiEvaluationTransientException(label + " analyse 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("{} analyse 4xx : {} body={}", label, e.getStatusCode(),
                preview(e.getResponseBodyAsString()));
            throw new AiEvaluationException(label + " analyse 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AiEvaluationTransientException(label + " analyse timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AiEvaluationException("Reponse " + label + " analyse vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info("{} analyse competence OK input={} output={} duration={}ms",
            label, outcome.inputTokens(), outcome.outputTokens(), duration);
        return outcome;
    }

    @Recover
    public Outcome recover(AiEvaluationTransientException ex, String systemPrompt, String userPrompt) {
        log.error("{} analyse competence indisponible apres retries : {}", label, ex.getMessage());
        throw new AiEvaluationException(
            label + " analyse indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public Outcome recoverPassthrough(AiEvaluationException ex, String systemPrompt, String userPrompt) {
        throw ex;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", TOOL_NAME);
        function.put("description", TOOL_DESCRIPTION);
        function.put("parameters", toolSchema);

        Map<String, Object> tool = Map.of("type", "function", "function", function);
        Map<String, Object> toolChoice = Map.of(
            "type", "function", "function", Map.of("name", TOOL_NAME));

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        // Budget PROPRE a l'analyse ciblee, pas celui des corrections completes.
        // Le NOM du champ, lui, depend du modele : les gpt-5.x refusent
        // max_tokens en 400 (cf. ChatCompletionDialect). L'analyse ciblee et les
        // corrections completes partagent le meme provider (regle « un seul
        // correcteur configurable ») : elles doivent parler le meme dialecte.
        body.put(
            ChatCompletionDialect.maxTokensParam(connection.getMaxTokensParam(), connection.getModel()),
            analysis.getMaxTokens());
        if (ChatCompletionDialect.sendTemperature(connection.getSendTemperature(), connection.getModel())) {
            body.put("temperature", analysis.getTemperature());
        }
        body.put("messages", List.of(
            Map.of("role", "system", "content", systemPrompt),
            Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(tool));
        body.put("tool_choice", toolChoice);
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
            throw new AiEvaluationException("Reponse " + label + " analyse sans bloc choices");
        }
        JsonNode toolCalls = choices.get(0).path("message").path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls dans la reponse " + label + " (finish_reason=" + finishReason + ")");
        }

        JsonNode call = null;
        for (JsonNode c : toolCalls) {
            if (TOOL_NAME.equals(c.path("function").path("name").asString())) { call = c; break; }
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
                "tool_call.arguments non deserialisable : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer inputTokens = usage.hasNonNull("prompt_tokens") ? usage.get("prompt_tokens").asInt() : null;
        Integer outputTokens = usage.hasNonNull("completion_tokens")
            ? usage.get("completion_tokens").asInt() : null;
        return new Outcome(parsed, inputTokens, outputTokens, estimateCostCents(inputTokens, outputTokens));
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

    private static String preview(String s) {
        if (s == null) return "";
        return s.length() > 200 ? s.substring(0, 200) + "..." : s;
    }
}
