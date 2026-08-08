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

        log.info("Whisper request -> fileName={} size={}B model={} lang={}",
            safeFileName, audioBytes.length, w.getModel(), w.getLanguage());
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

        SegmentQuality quality = readSegments(response);

        log.info("Whisper OK fileName={} size={}B durationDetected={}s httpDuration={}ms "
                + "segments={} avgLogprob={} noSpeechProbMax={} compressionRatioMax={}",
            safeFileName, audioBytes.length, durationSec, duration,
            quality.segmentsCount(), quality.avgLogprob(), quality.noSpeechProb(),
            quality.compressionRatio());

        return new WhisperResult(
            texte,
            language,
            durationSec == null ? null : (int) Math.round(durationSec),
            quality
        );
    }

    /**
     * INDICATEURS DE QUALITE DE {@code verbose_json}, demandes depuis toujours
     * (cf. {@code response_format} ci-dessus) et jetes jusqu'au 2026-08-09 : on
     * ne lisait que {@code text}, {@code language} et {@code duration}. Ils sont
     * factures dans la meme reponse, donc gratuits a lire.
     *
     * <p>Agregation choisie : {@code avg_logprob} en moyenne PONDEREE PAR LA
     * DUREE des segments (un segment d'une seconde ne pese pas comme un segment
     * de trente), {@code no_speech_prob} et {@code compression_ratio} au PIRE
     * segment — ce sont des alertes, et une alerte ne se moyenne pas : un seul
     * passage radote ou vide suffit a abimer la production.
     */
    private static SegmentQuality readSegments(JsonNode response) {
        JsonNode segments = response.get("segments");
        if (segments == null || !segments.isArray() || segments.isEmpty()) {
            return SegmentQuality.absente();
        }
        double sommePonderee = 0;
        double sommeDurees = 0;
        Double pireNoSpeech = null;
        Double pireCompression = null;
        int count = 0;
        for (JsonNode segment : segments) {
            count++;
            double debut = segment.hasNonNull("start") ? segment.get("start").asDouble() : 0;
            double fin = segment.hasNonNull("end") ? segment.get("end").asDouble() : 0;
            double duree = Math.max(fin - debut, 0.0);
            if (segment.hasNonNull("avg_logprob")) {
                double poids = duree > 0 ? duree : 1.0;
                sommePonderee += segment.get("avg_logprob").asDouble() * poids;
                sommeDurees += poids;
            }
            if (segment.hasNonNull("no_speech_prob")) {
                double v = segment.get("no_speech_prob").asDouble();
                if (pireNoSpeech == null || v > pireNoSpeech) pireNoSpeech = v;
            }
            if (segment.hasNonNull("compression_ratio")) {
                double v = segment.get("compression_ratio").asDouble();
                if (pireCompression == null || v > pireCompression) pireCompression = v;
            }
        }
        Double avgLogprob = sommeDurees > 0 ? sommePonderee / sommeDurees : null;
        return new SegmentQuality(avgLogprob, pireNoSpeech, pireCompression, count);
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

    /**
     * @param avgLogprob       moyenne ponderee par la duree (plus c'est bas, moins le modele est sur)
     * @param noSpeechProb     pire segment (probabilite qu'il n'y ait pas de parole)
     * @param compressionRatio pire segment (au-dela de ~2,4, Whisper radote)
     * @param segmentsCount    nombre de segments renvoyes
     */
    public record SegmentQuality(Double avgLogprob, Double noSpeechProb,
                                 Double compressionRatio, int segmentsCount) {

        static SegmentQuality absente() {
            return new SegmentQuality(null, null, null, 0);
        }
    }

    public record WhisperResult(String texte, String languageDetected, Integer durationSec,
                                SegmentQuality quality) {

        public WhisperResult(String texte, String languageDetected, Integer durationSec) {
            this(texte, languageDetected, durationSec, SegmentQuality.absente());
        }
    }
}
