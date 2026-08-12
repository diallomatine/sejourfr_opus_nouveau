package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.exception.AiEvaluationException;
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
 * Client « pour viser X » Anthropic ({@code tool_use}).
 *
 * <p>Il existe pour la meme raison que ses equivalents ailleurs dans le depot :
 * basculer {@code sejourfr.production-evaluation.provider} sur
 * {@code anthropic} ne doit pas eteindre en silence une fonctionnalite servie au
 * candidat. Sans lui, un changement de fournisseur ferait disparaitre le bloc
 * « pour viser » sans qu'aucune alerte ne le signale.
 *
 * <p>Aucun rejeu : cet appel est best-effort (cf.
 * {@link CompetenceNiveauViseLlmClient}).
 */
public class CompetenceNiveauViseAnthropicClient implements CompetenceNiveauViseLlmClient {

    private static final Logger log =
        LoggerFactory.getLogger(CompetenceNiveauViseAnthropicClient.class);

    private final ProductionEvaluationProperties.Anthropic connection;
    private final CompetenceProperties.NiveauVise reglages;
    private final Map<String, Object> toolSchema;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public CompetenceNiveauViseAnthropicClient(
            ProductionEvaluationProperties.Anthropic connection,
            CompetenceProperties.NiveauVise reglages,
            Map<String, Object> toolSchema,
            ObjectMapper objectMapper) {
        this.connection = connection;
        this.reglages = reglages;
        this.toolSchema = toolSchema;
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
    public Outcome produire(String systemPrompt, String userPrompt) {
        if (!connection.isConfigured()) {
            throw new AiEvaluationException(
                "Anthropic : cle API non configuree — bloc « pour viser » ignore.");
        }

        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.APPLICATION_JSON)
                .header("x-api-key", connection.getApiKey())
                .header("anthropic-version", connection.getAnthropicVersion())
                .body(buildRequestBody(systemPrompt, userPrompt))
                .retrieve()
                .body(JsonNode.class);
        } catch (RuntimeException e) {
            throw new AiEvaluationException(
                "Anthropic niveau vise indisponible : " + e.getMessage(), e);
        }
        if (response == null) {
            throw new AiEvaluationException("Reponse Anthropic niveau vise vide");
        }

        Outcome outcome = parseToolUseOutcome(response);
        log.info("Anthropic competence niveau vise OK input={} output={} duration={}ms",
            outcome.inputTokens(), outcome.outputTokens(), System.currentTimeMillis() - start);
        return outcome;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("name", CompetenceNiveauViseFields.TOOL_NAME);
        tool.put("description", CompetenceNiveauViseFields.TOOL_DESCRIPTION);
        tool.put("input_schema", toolSchema);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", connection.getModel());
        body.put("max_tokens", reglages.getMaxTokens());
        body.put("system", List.of(Map.of("type", "text", "text", systemPrompt)));
        body.put("messages", List.of(Map.of("role", "user", "content", userPrompt)));
        body.put("tools", List.of(tool));
        body.put("tool_choice",
            Map.of("type", "tool", "name", CompetenceNiveauViseFields.TOOL_NAME));
        return body;
    }

    private Outcome parseToolUseOutcome(JsonNode response) {
        JsonNode content = response.path("content");
        if (!content.isArray() || content.isEmpty()) {
            throw new AiEvaluationException("Reponse Anthropic niveau vise sans bloc content");
        }
        JsonNode toolBlock = null;
        for (JsonNode block : content) {
            String type = block.hasNonNull("type") ? block.get("type").asString() : null;
            String name = block.hasNonNull("name") ? block.get("name").asString() : null;
            if ("tool_use".equals(type) && CompetenceNiveauViseFields.TOOL_NAME.equals(name)) {
                toolBlock = block;
                break;
            }
        }
        if (toolBlock == null) {
            throw new AiEvaluationException(
                "Pas de bloc tool_use " + CompetenceNiveauViseFields.TOOL_NAME
                    + " dans la reponse");
        }
        JsonNode input = toolBlock.path("input");
        if (input.isMissingNode() || input.isNull()) {
            throw new AiEvaluationException("Bloc tool_use sans champ input (niveau vise)");
        }

        Map<String, Object> parsed;
        try {
            parsed = objectMapper.treeToValue(input, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "Input du tool_use non deserialisable (niveau vise) : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer in = usage.hasNonNull("input_tokens") ? usage.get("input_tokens").asInt() : null;
        Integer out = usage.hasNonNull("output_tokens") ? usage.get("output_tokens").asInt() : null;
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
