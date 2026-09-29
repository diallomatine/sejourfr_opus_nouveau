package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties.ChatCompletionSettings;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.util.CoutAppelLlm;
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
 * Client « pour viser X » pour tout fournisseur compatible OpenAI (Chat
 * Completions + function calling) : OpenAI, DeepSeek, ou tout endpoint
 * equivalent. Une instance = un fournisseur, choisi par les
 * {@link ChatCompletionSettings} injectes (cf.
 * {@code CompetenceNiveauViseLlmConfig}).
 *
 * <p><b>Deux sources de reglages, volontairement.</b> La CONNEXION (URL, cle,
 * modele, timeout, tarifs, mode thinking) vient de
 * {@code sejourfr.production-evaluation.<provider>} : c'est le meme correcteur
 * que partout ailleurs. Le CONTRAT DE SORTIE et le budget de tokens viennent de
 * {@code sejourfr.competences.niveau-vise} : la sortie attendue ici tient en
 * trois leviers courts, un texte de quelques phrases et une tournure.
 *
 * <p><b>Aucun rejeu.</b> Toute erreur — 4xx, 5xx, timeout, reponse malformee —
 * remonte en {@link AiEvaluationException} et le service appelant l'avale. Seule
 * la NEGOCIATION DE FORME est rejouee (un 400 ou le fournisseur dit lui-meme
 * quel champ il refuse) : c'est ce qui permet de changer de modele sans toucher
 * une ligne de Java.
 */
public class CompetenceNiveauViseOpenAiCompatibleClient implements CompetenceNiveauViseLlmClient {

    private static final Logger log =
        LoggerFactory.getLogger(CompetenceNiveauViseOpenAiCompatibleClient.class);

    private final ChatCompletionSettings connection;
    private final CompetenceProperties.NiveauVise reglages;
    private final String label;
    /** Seul endroit qui sait ce que coute un appel : trois tarifs + heures pleines. */
    private final CoutAppelLlm tarification;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final ChatCompletionDialectNegotiator dialecte;
    private final Map<String, Object> toolSchema;

    public CompetenceNiveauViseOpenAiCompatibleClient(ChatCompletionSettings connection,
                                                      CompetenceProperties.NiveauVise reglages,
                                                      Map<String, Object> toolSchema,
                                                      String label, ObjectMapper objectMapper) {
        this.connection = connection;
        this.tarification = new CoutAppelLlm(connection);
        this.reglages = reglages;
        this.toolSchema = toolSchema;
        this.label = label;
        this.objectMapper = objectMapper;
        this.dialecte = new ChatCompletionDialectNegotiator(
            label + " competence niveau vise", connection.getModel(),
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
                label + " : cle API non configuree — bloc « pour viser » ignore.");
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
                    label + " niveau vise 4xx (" + e.getStatusCode() + ")", e);
            } catch (RuntimeException e) {
                throw new AiEvaluationException(
                    label + " niveau vise indisponible : " + e.getMessage(), e);
            }
        }
        if (response == null) {
            throw new AiEvaluationException("Reponse " + label + " niveau vise vide");
        }

        Outcome outcome = parseFunctionCallOutcome(response);
        log.info("{} competence niveau vise OK input={} output={} duration={}ms",
            label, outcome.inputTokens(), outcome.outputTokens(),
            System.currentTimeMillis() - start);
        return outcome;
    }

    Map<String, Object> buildRequestBody(String systemPrompt, String userPrompt,
                                         ChatCompletionDialect forme) {
        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", CompetenceNiveauViseFields.TOOL_NAME);
        function.put("description", CompetenceNiveauViseFields.TOOL_DESCRIPTION);
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
            Map.of("name", CompetenceNiveauViseFields.TOOL_NAME)));
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
            throw new AiEvaluationException("Reponse " + label + " niveau vise sans bloc choices");
        }
        JsonNode toolCalls = choices.get(0).path("message").path("tool_calls");
        if (!toolCalls.isArray() || toolCalls.isEmpty()) {
            String finishReason = choices.get(0).hasNonNull("finish_reason")
                ? choices.get(0).get("finish_reason").asString() : "unknown";
            throw new AiEvaluationException(
                "Pas de tool_calls " + label + " niveau vise (finish_reason=" + finishReason + ")");
        }
        JsonNode call = null;
        for (JsonNode c : toolCalls) {
            if (CompetenceNiveauViseFields.TOOL_NAME.equals(
                    c.path("function").path("name").asString())) {
                call = c;
                break;
            }
        }
        if (call == null) {
            throw new AiEvaluationException(
                "Aucune tool_call " + CompetenceNiveauViseFields.TOOL_NAME + " dans la reponse");
        }

        // OpenAI/DeepSeek renvoient les arguments sous forme de STRING JSON,
        // contrairement a Anthropic qui renvoie un objet directement.
        String argsJson = call.path("function").path("arguments").asString();
        if (argsJson == null || argsJson.isBlank()) {
            throw new AiEvaluationException("tool_call.arguments vide (niveau vise)");
        }
        Map<String, Object> parsed;
        try {
            parsed = objectMapper.readValue(argsJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new AiEvaluationException(
                "tool_call.arguments non deserialisable (niveau vise) : " + e.getMessage(), e);
        }

        JsonNode usage = response.path("usage");
        Integer in = usage.hasNonNull("prompt_tokens") ? usage.get("prompt_tokens").asInt() : null;
        Integer out = usage.hasNonNull("completion_tokens")
            ? usage.get("completion_tokens").asInt() : null;
        // Le decoupage cache hit / cache miss est RENVOYE par le fournisseur :
        // on le lit, on ne le devine pas. Absent -> tout au plein tarif.
        Integer cacheHit = CoutAppelLlm.lireCacheHitTokens(usage);
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
