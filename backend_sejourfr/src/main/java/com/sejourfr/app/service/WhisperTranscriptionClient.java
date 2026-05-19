package com.sejourfr.app.service;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.exception.TranscriptionTransientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.JsonNode;

import java.net.http.HttpClient;
import java.time.Duration;

/**
 * Client REST pour OpenAI Whisper (transcription). Pousse l'audio en multipart
 * sur {@code POST /v1/audio/transcriptions} et recupere la transcription en
 * verbose_json (pour avoir la duree detectee).
 * <p>
 * Le {@code prompt} de transcription litterale est passe systematiquement pour
 * limiter l'auto-correction des fautes des apprenants (cf. spec section 2.4).
 */
@Service
public class WhisperTranscriptionClient {

    private static final Logger log = LoggerFactory.getLogger(WhisperTranscriptionClient.class);

    private final OpenAiProperties props;
    private final RestClient restClient;

    public WhisperTranscriptionClient(OpenAiProperties props) {
        this.props = props;
        this.restClient = RestClient.builder()
            .baseUrl(props.getApiUrl())
            .requestFactory(buildRequestFactory(props.getWhisper().getTimeoutSec()))
            .build();
    }

    // Retry strategie : 3 tentatives totales (1 initiale + 2 retries) avec
    // backoff exponentiel + jitter, conforme spec section 2.3.a.
    @Retryable(
        retryFor = TranscriptionTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public WhisperResult transcribe(byte[] audioBytes, String fileName) {
        if (!props.isConfigured()) {
            throw new TranscriptionException(
                "OPENAI_API_KEY non configuree. Renseignez-la dans l'environnement."
            );
        }
        OpenAiProperties.Whisper w = props.getWhisper();
        String safeFileName = (fileName == null || fileName.isBlank()) ? "audio.webm" : fileName;

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new NamedByteArrayResource(audioBytes, safeFileName));
        body.add("model", w.getModel());
        if (w.getLanguage() != null && !w.getLanguage().isBlank()) body.add("language", w.getLanguage());
        if (w.getLiteralModePrompt() != null && !w.getLiteralModePrompt().isBlank()) {
            body.add("prompt", w.getLiteralModePrompt());
        }
        body.add("response_format", "verbose_json");

        long start = System.currentTimeMillis();
        JsonNode response;
        try {
            response = restClient.post()
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .header("Authorization", "Bearer " + props.getApiKey())
                .body(body)
                .retrieve()
                .body(JsonNode.class);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new TranscriptionTransientException("Whisper 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new TranscriptionTransientException("Whisper 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("Whisper 4xx : {} body={}", e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new TranscriptionException("Whisper 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new TranscriptionTransientException("Whisper timeout ou erreur reseau", e);
        }
        long duration = System.currentTimeMillis() - start;

        if (response == null) {
            throw new TranscriptionException("Reponse Whisper vide");
        }

        String texte = response.hasNonNull("text") ? response.get("text").asString() : null;
        if (texte == null || texte.isBlank()) {
            throw new TranscriptionException("Whisper : champ 'text' absent ou vide");
        }
        String language = response.hasNonNull("language") ? response.get("language").asString() : null;
        Double durationSec = response.hasNonNull("duration") ? response.get("duration").asDouble() : null;

        log.info("Whisper OK fileName={} size={}B durationDetected={}s httpDuration={}ms",
            safeFileName, audioBytes.length, durationSec, duration);

        return new WhisperResult(
            texte,
            language,
            durationSec == null ? null : (int) Math.round(durationSec)
        );
    }

    @Recover
    public WhisperResult recover(TranscriptionTransientException ex, byte[] audioBytes, String fileName) {
        log.error("Whisper indisponible apres retries : {}", ex.getMessage());
        throw new TranscriptionException("Whisper indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public WhisperResult recoverPassthrough(TranscriptionException ex, byte[] audioBytes, String fileName) {
        throw ex;
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

    /** Resource avec un nom de fichier explicite pour le multipart. */
    private static final class NamedByteArrayResource extends ByteArrayResource {
        private final String fileName;
        NamedByteArrayResource(byte[] bytes, String fileName) {
            super(bytes);
            this.fileName = fileName;
        }
        @Override
        public String getFilename() { return fileName; }
    }

    public record WhisperResult(String texte, String languageDetected, Integer durationSec) {}
}
