package com.sejourfr.app.audioquestion.service;

import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.sejourfr.app.audioquestion.config.AnthropicProperties;
import com.sejourfr.app.audioquestion.dto.AnthropicGenerationResponse;
import com.sejourfr.app.audioquestion.dto.GenerateAudioQuestionRequest;
import com.sejourfr.app.audioquestion.exception.AnthropicContentInvalidException;
import com.sejourfr.app.audioquestion.exception.AnthropicGenerationException;
import com.sejourfr.app.audioquestion.exception.AnthropicTransientException;
import com.sejourfr.app.audioquestion.exception.AudioGenerationException;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import jakarta.annotation.PostConstruct;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
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

import java.io.InputStream;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Client REST pour l'API Anthropic Messages.
 * Utilise tool_use ({@code emit_audio_question}) pour forcer Claude a produire
 * un JSON strict (le schema est cote serveur).
 * Active le prompt caching ephemere (5 min) sur le system prompt pour reduire
 * le cout des generations en rafale.
 */
@Service
public class AnthropicClient {

    private static final Logger log = LoggerFactory.getLogger(AnthropicClient.class);
    private static final String TOOL_NAME = "emit_audio_question";
    private static final String TOOL_SCHEMA_PATH = "prompts/audio-question-tool-schema.json";

    private final AnthropicProperties props;
    private final PromptLoader promptLoader;
    private final ObjectMapper objectMapper;
    private final Validator validator;
    private final RestClient restClient;
    private Map<String, Object> toolSchema;

    public AnthropicClient(
            AnthropicProperties props,
            PromptLoader promptLoader,
            ObjectMapper objectMapper,
            Validator validator) {
        this.props = props;
        this.promptLoader = promptLoader;
        this.objectMapper = objectMapper;
        this.validator = validator;
        this.restClient = RestClient.builder()
            .baseUrl(props.getApiUrl())
            .requestFactory(buildRequestFactory(props.getTimeoutSec()))
            .build();
    }

    @PostConstruct
    void loadToolSchema() throws Exception {
        try (InputStream is = new ClassPathResource(TOOL_SCHEMA_PATH).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            this.toolSchema = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        }
        log.info("Tool schema audio charge ({} cles)", toolSchema.size());
    }

    @Retryable(
        retryFor = AnthropicTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public Outcome generate(GenerateAudioQuestionRequest request) {
        if (!props.isConfigured()) {
            throw new AudioServicesUnavailableException(
                "ANTHROPIC_API_KEY non configuree. Renseignez-la dans l'environnement."
            );
        }

        Map<String, Object> body = buildRequestBody(request);
        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("x-api-key", props.getApiKey())
                .header("anthropic-version", props.getAnthropicVersion())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AnthropicTransientException("Anthropic 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AnthropicTransientException("Anthropic 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("Anthropic 4xx : {} body={}", e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new AnthropicGenerationException("Anthropic 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AnthropicTransientException("Anthropic timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new AnthropicGenerationException("Reponse Anthropic vide");
        }

        Outcome outcome = parseToolUseOutcome(response);
        log.info(
            "Anthropic OK input={} output={} cacheRead={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), outcome.cacheReadTokens(), duration
        );
        return outcome;
    }

    @Recover
    public Outcome recover(AnthropicTransientException ex, GenerateAudioQuestionRequest request) {
        log.error("Anthropic indisponible apres retries : {}", ex.getMessage());
        throw new AnthropicGenerationException("Anthropic indisponible apres plusieurs tentatives", ex);
    }

    /**
     * Recovery passthrough : Spring Retry cherche un @Recover pour toute exception
     * sortant de la methode @Retryable, meme non listee dans retryFor.
     * On re-leve l'originale pour qu'elle remonte au controller telle quelle.
     */
    @Recover
    public Outcome recoverPassthrough(AudioGenerationException ex, GenerateAudioQuestionRequest request) {
        throw ex;
    }

    private Map<String, Object> buildRequestBody(GenerateAudioQuestionRequest request) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", TOOL_NAME);
        tool.put("description",
            "Emet la question audio CO complete (transcript, ssml, question, 4 choix, explication, voix, metadonnees). "
            + "Utilise systematiquement cet outil, jamais de texte libre.");
        tool.put("input_schema", toolSchema);

        Map<String, Object> systemBlock = Map.of(
            "type", "text",
            "text", promptLoader.getSystemPrompt(),
            "cache_control", Map.of("type", "ephemeral")
        );

        Map<String, Object> userMessage = Map.of(
            "role", "user",
            "content", serializeUserParams(request)
        );

        Map<String, Object> toolChoice = Map.of("type", "tool", "name", TOOL_NAME);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", props.getModel());
        body.put("max_tokens", props.getMaxTokens());
        body.put("system", List.of(systemBlock));
        body.put("messages", List.of(userMessage));
        body.put("tools", List.of(tool));
        body.put("tool_choice", toolChoice);
        return body;
    }

    private String serializeUserParams(GenerateAudioQuestionRequest request) {
        Map<String, Object> params = new LinkedHashMap<>();
        params.put("niveau", request.niveau());
        if (request.theme() != null) params.put("theme", request.theme());
        if (request.typeSouhaite() != null) params.put("typeSouhaite", request.typeSouhaite());
        if (request.competenceVisee() != null) params.put("competenceVisee", request.competenceVisee());
        if (request.consignesSpecifiques() != null) params.put("consignesSpecifiques", request.consignesSpecifiques());
        params.put("audioMode", request.audioModeOrDefault().name());
        try {
            return objectMapper.writeValueAsString(params);
        } catch (Exception e) {
            throw new AnthropicGenerationException("Serialisation des parametres utilisateur impossible", e);
        }
    }

    private Outcome parseToolUseOutcome(JsonNode response) {
        JsonNode content = response.path("content");
        if (!content.isArray() || content.isEmpty()) {
            throw new AnthropicContentInvalidException("Reponse Anthropic sans bloc content");
        }
        JsonNode toolBlock = null;
        for (JsonNode block : content) {
            if ("tool_use".equals(block.path("type").asString())
                    && TOOL_NAME.equals(block.path("name").asString())) {
                toolBlock = block;
                break;
            }
        }
        if (toolBlock == null) {
            throw new AnthropicContentInvalidException(
                "Pas de bloc tool_use " + TOOL_NAME + " (stop_reason=" + response.path("stop_reason").asString() + ")"
            );
        }
        JsonNode input = toolBlock.path("input");
        if (input.isMissingNode() || input.isNull()) {
            throw new AnthropicContentInvalidException("Bloc tool_use sans champ input");
        }

        AnthropicGenerationResponse dto;
        try {
            dto = objectMapper.treeToValue(input, AnthropicGenerationResponse.class);
        } catch (Exception e) {
            throw new AnthropicContentInvalidException("input du tool_use non desorialisable : " + e.getMessage(), e);
        }

        Set<ConstraintViolation<AnthropicGenerationResponse>> violations = validator.validate(dto);
        if (!violations.isEmpty()) {
            String summary = violations.stream()
                .map(v -> v.getPropertyPath() + " " + v.getMessage())
                .collect(Collectors.joining("; "));
            throw new AnthropicContentInvalidException(
                "input du tool_use ne respecte pas le schema metier : " + summary
            );
        }

        JsonNode usage = response.path("usage");
        Integer inputTokens = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : null;
        Integer outputTokens = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;
        Integer cacheReadTokens = usage.hasNonNull("cache_read_input_tokens")
            ? usage.get("cache_read_input_tokens").asInt() : null;

        return new Outcome(dto, inputTokens, outputTokens, cacheReadTokens);
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

    /** Resultat utile pour le service d'orchestration : contenu + metriques. */
    public record Outcome(
        AnthropicGenerationResponse content,
        Integer inputTokens,
        Integer outputTokens,
        Integer cacheReadTokens
    ) {}
}
