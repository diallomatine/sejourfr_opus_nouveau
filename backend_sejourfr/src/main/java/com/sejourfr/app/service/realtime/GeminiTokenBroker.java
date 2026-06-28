package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Adaptateur Gemini Live. Emet un token ephemere via l'endpoint REST
 * {@code v1alpha/auth_tokens} en VERROUILLANT, dans les
 * {@code liveConnectConstraints}, le modele, la sortie {@code AUDIO}, la
 * transcription d'entree ET de sortie (indispensable pour rapatrier le
 * transcript dialogue), la voix et la persona (system instruction). Le client
 * recoit uniquement {@code token.name} et ouvre le WebSocket
 * {@code BidiGenerateContent} avec ce token en {@code access_token}.
 *
 * <p>Si la cle n'est pas configuree, {@link #isConfigured()} renvoie false et le
 * service appelant bascule silencieusement en async (jamais de 503 cote client).
 */
@Slf4j
@Component
public class GeminiTokenBroker implements RealtimeTokenBroker {

    private final RealtimeProperties props;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public GeminiTokenBroker(RealtimeProperties props, ObjectMapper objectMapper) {
        this.props = props;
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
                .requestFactory(buildRequestFactory(props.getGemini().getTimeoutSec()))
                .build();
    }

    @Override
    public String provider() {
        return "gemini";
    }

    @Override
    public boolean isConfigured() {
        return props.getGemini().isConfigured();
    }

    @Override
    public MintedSession mint(String systemInstruction) {
        RealtimeProperties.Gemini g = props.getGemini();
        Instant now = Instant.now();
        Map<String, Object> body = buildRequestBody(g, systemInstruction, now);
        try {
            String json = restClient.post()
                    .uri(g.getAuthTokensUrl())
                    .header("x-goog-api-key", g.getApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(objectMapper.writeValueAsString(body))
                    .retrieve()
                    .body(String.class);
            JsonNode root = objectMapper.readTree(json);
            String name = root.hasNonNull("name") ? root.get("name").asString() : null;
            if (name == null || name.isBlank()) {
                throw new BusinessException("Reponse Gemini auth_tokens sans champ name.");
            }
            return new MintedSession(name, g.getWsEndpoint(), normalizedModel(g.getModel()));
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            // Remonte comme erreur metier : le service appelant la traite comme
            // un echec de mint et bascule en async plutot que de bloquer.
            log.warn("Echec emission token ephemere Gemini : {}", e.getMessage());
            throw new BusinessException("Impossible d'ouvrir une session temps reel : " + e.getMessage());
        }
    }

    private Map<String, Object> buildRequestBody(RealtimeProperties.Gemini g, String systemInstruction, Instant now) {
        // Sous-message generationConfig : modalite de sortie + voix + temperature.
        Map<String, Object> generationConfig = new LinkedHashMap<>();
        generationConfig.put("responseModalities", List.of("AUDIO"));
        generationConfig.put("temperature", g.getTemperature());
        if (g.getVoice() != null && !g.getVoice().isBlank()) {
            generationConfig.put("speechConfig", Map.of(
                    "voiceConfig", Map.of(
                            "prebuiltVoiceConfig", Map.of("voiceName", g.getVoice()))));
        }

        // BidiGenerateContentSetup : la config verrouillee dans le token. Le
        // modele, la persona (systemInstruction) et la transcription in/out y
        // vivent cote serveur ; la transcription des deux cotes est ce qui
        // permet de capturer le dialogue (candidat + examinateur) pour la notation.
        Map<String, Object> setup = new LinkedHashMap<>();
        setup.put("model", normalizedModel(g.getModel()));
        setup.put("generationConfig", generationConfig);
        setup.put("systemInstruction", Map.of("parts", List.of(Map.of("text", systemInstruction))));
        setup.put("inputAudioTranscription", Map.of());
        setup.put("outputAudioTranscription", Map.of());

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("uses", g.getTokenUses());
        body.put("expireTime", now.plusSeconds(g.getSessionExpireSeconds()).toString());
        body.put("newSessionExpireTime", now.plusSeconds(g.getNewSessionExpireSeconds()).toString());
        body.put("bidiGenerateContentSetup", setup);
        return body;
    }

    /** Gemini attend le modele prefixe par {@code models/}. */
    private static String normalizedModel(String model) {
        return model.startsWith("models/") ? model : "models/" + model;
    }

    private static ClientHttpRequestFactory buildRequestFactory(int timeoutSec) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }
}
