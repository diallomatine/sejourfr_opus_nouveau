package com.sejourfr.app.audioquestion.service;

import com.sejourfr.app.audioquestion.config.AzureSpeechProperties;
import com.sejourfr.app.audioquestion.exception.AudioGenerationException;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import com.sejourfr.app.audioquestion.exception.AzureSpeechException;
import com.sejourfr.app.audioquestion.exception.AzureSpeechTransientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * Synthese vocale Azure Speech : POST SSML -> MP3 binaire.
 * Retry sur 401 (refresh token) / 429 / 5xx / timeout.
 */
@Service
public class AzureSpeechClient {

    private static final Logger log = LoggerFactory.getLogger(AzureSpeechClient.class);
    private static final MediaType SSML_MEDIA =
        MediaType.parseMediaType("application/ssml+xml;charset=UTF-8");

    private final AzureSpeechProperties props;
    private final AzureSpeechTokenService tokenService;
    private final RestClient restClient;

    public AzureSpeechClient(AzureSpeechProperties props, AzureSpeechTokenService tokenService) {
        this.props = props;
        this.tokenService = tokenService;
        this.restClient = RestClient.builder()
            .requestFactory(buildRequestFactory(props.getTimeoutSec()))
            .build();
    }

    @Retryable(
        retryFor = AzureSpeechTransientException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 1000, multiplier = 2, random = true)
    )
    public byte[] synthesize(String ssml) {
        if (!props.isConfigured()) {
            throw new AudioServicesUnavailableException("AZURE_SPEECH_KEY/REGION non configures");
        }
        String token = tokenService.getToken();
        long start = System.currentTimeMillis();
        if (log.isInfoEnabled()) {
            log.info("Azure TTS SSML ({} chars) : {}",
                ssml.length(),
                ssml.length() > 2000 ? ssml.substring(0, 2000) + "..." : ssml);
        }
        try {
            byte[] mp3 = restClient.post()
                .uri(props.getTtsEndpointUrl())
                .header("Authorization", "Bearer " + token)
                .header("X-Microsoft-OutputFormat", props.getOutputFormat())
                .header("User-Agent", "sejourfr-backend/0.1.0")
                .contentType(SSML_MEDIA)
                .body(ssml.getBytes(StandardCharsets.UTF_8))
                .retrieve()
                .body(byte[].class);
            if (mp3 == null || mp3.length == 0) {
                throw new AzureSpeechException("Azure a renvoye un MP3 vide");
            }
            long duration = System.currentTimeMillis() - start;
            log.info("Azure TTS OK size={}B duration={}ms", mp3.length, duration);
            return mp3;
        } catch (HttpClientErrorException.Unauthorized e) {
            tokenService.invalidate();
            throw new AzureSpeechTransientException("Azure TTS 401 (token expire ou rejete)", e);
        } catch (HttpClientErrorException.TooManyRequests e) {
            throw new AzureSpeechTransientException("Azure TTS 429 rate-limited", e);
        } catch (HttpServerErrorException e) {
            throw new AzureSpeechTransientException("Azure TTS 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            log.warn("Azure TTS 4xx : {} body={}", e.getStatusCode(), preview(e.getResponseBodyAsString()));
            throw new AzureSpeechException("Azure TTS 4xx (" + e.getStatusCode() + ") : " + e.getMessage(), e);
        } catch (ResourceAccessException e) {
            throw new AzureSpeechTransientException("Azure TTS timeout ou erreur reseau", e);
        }
    }

    @Recover
    public byte[] recover(AzureSpeechTransientException ex, String ssml) {
        log.error("Azure TTS indisponible apres retries : {}", ex.getMessage());
        throw new AzureSpeechException("Azure TTS indisponible apres plusieurs tentatives", ex);
    }

    @Recover
    public byte[] recoverPassthrough(AudioGenerationException ex, String ssml) {
        throw ex;
    }

    /** SimpleClientHttpRequestFactory : respecte User-Agent custom et Content-Length, contrairement au JDK HttpClient. */
    private static ClientHttpRequestFactory buildRequestFactory(int timeoutSec) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }

    private static String preview(String s) {
        if (s == null) return "";
        return s.length() > 200 ? s.substring(0, 200) + "..." : s;
    }
}
