package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties.VersionCiblee;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.util.CoutAppelLlm;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
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
 * Client « version au niveau visé » Anthropic ({@code tool_use}).
 *
 * <p>Il existe pour la même raison que son équivalent côté Compétences :
 * basculer {@code sejourfr.production-evaluation.provider} sur
 * {@code anthropic} ne doit pas éteindre en silence une fonctionnalité servie
 * au candidat. Sans lui, un changement de fournisseur ferait disparaître le bloc
 * « version au niveau visé » sans qu'aucune alerte ne le signale.
 *
 * <p>Aucun rejeu : cet appel est best-effort (cf. {@link VersionCibleeLlmClient}).
 */
public class VersionCibleeAnthropicClient implements VersionCibleeLlmClient {

    private static final Logger log = LoggerFactory.getLogger(VersionCibleeAnthropicClient.class);

    private final ProductionEvaluationProperties.Anthropic connection;
    private final VersionCiblee reglages;
    private final VersionCibleeTools tools;
    /** Seul endroit qui sait ce que coute un appel : trois tarifs + heures pleines. */
    private final CoutAppelLlm tarification;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public VersionCibleeAnthropicClient(ProductionEvaluationProperties.Anthropic connection,
                                        VersionCiblee reglages,
                                        VersionCibleeTools tools,
                                        ObjectMapper objectMapper) {
        this.connection = connection;
        this.tarification = new CoutAppelLlm(connection);
        this.reglages = reglages;
        this.tools = tools;
        this.objectMapper = objectMapper;
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
                "Anthropic : cle API non configuree — version ciblee ignoree.");
        }

        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("x-api-key", connection.getApiKey())
                .header("anthropic-version", connection.getAnthropicVersion())
                .body(buildRequestBody(systemPrompt, userPrompt, variante))
                .retrieve()
                .body(JsonNode.class);
        } catch (RuntimeException e) {
            throw new AiEvaluationException(
                "Anthropic version ciblee indisponible : " + e.getMessage(), e);
        }
        if (response == null) {
            throw new AiEvaluationException("Reponse Anthropic version ciblee vide");
        }

        Outcome outcome = parseToolUseOutcome(response);
        log.info("Anthropic version ciblee OK input={} output={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), System.currentTimeMillis() - start);
        return outcome;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt,
                                         VersionCibleeVariante variante) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", VersionCibleeFields.TOOL_NAME);
        tool.put("description", tools.description(variante));
        tool.put("input_schema", tools.schema(variante));

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        body.put("max_tokens", reglages.getMaxTokens());
        body.put("system", List.of(Map.of("type", "text", "text", systemPrompt)));
        body.put("messages", List.of(Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(tool));
        body.put("tool_choice", Map.of("type", "tool", "name", VersionCibleeFields.TOOL_NAME));
        return body;
    }

    private Outcome parseToolUseOutcome(JsonNode response) {
        JsonNode content = response.path("content");
        if (!content.isArray() || content.isEmpty()) {
            throw new AiEvaluationException("Reponse Anthropic version ciblee sans bloc content");
        }
        JsonNode toolBlock = null;
        for (JsonNode block : content) {
            String type = block.hasNonNull("type") ? block.get("type").asString() : null;
            String name = block.hasNonNull("name") ? block.get("name").asString() : null;
            if ("tool_use".equals(type) && VersionCibleeFields.TOOL_NAME.equals(name)) {
                toolBlock = block;
                break;
            }
        }
        if (toolBlock == null) {
            throw new AiEvaluationException(
                "Pas de bloc tool_use " + VersionCibleeFields.TOOL_NAME + " dans la reponse");
        }
        JsonNode input = toolBlock.path("input");
        if (input.isMissingNode() || input.isNull()) {
            throw new AiEvaluationException("Bloc tool_use sans champ input (version ciblee)");
        }

        Map<String, Object> parsed;
        try {
            parsed = objectMapper.treeToValue(input, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "Input du tool_use non deserialisable (version ciblee) : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer in = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : null;
        Integer out = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;
        // Anthropic ne sert du cache que si la requete le demande (`cache_control`),
        // ce que nous ne faisons pas : aucun token n'est jamais servi par le cache.
        Integer cacheHit = null;
        return new Outcome(parsed, in, cacheHit, out, tarification.microDollars(in, cacheHit, out));
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
