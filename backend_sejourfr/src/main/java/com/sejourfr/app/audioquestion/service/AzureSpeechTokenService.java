package com.sejourfr.app.audioquestion.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.sejourfr.app.audioquestion.config.AzureSpeechProperties;
import com.sejourfr.app.audioquestion.exception.AudioServicesUnavailableException;
import com.sejourfr.app.audioquestion.exception.AzureSpeechException;
import com.sejourfr.app.audioquestion.exception.AzureSpeechTransientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/**
 * Recupere et cache le token Bearer Azure Speech.
 * Duree de vie cote Azure : 10 min. Nous cachons 9 min pour avoir une marge.
 * En cas de 401 sur l'API TTS, le client appelle {@link #invalidate()}
 * pour forcer un refresh.
 */
@Service
public class AzureSpeechTokenService {

    private static final Logger log = LoggerFactory.getLogger(AzureSpeechTokenService.class);
    private static final String CACHE_KEY = "token";

    private final AzureSpeechProperties props;
    private final RestClient restClient;
    private final Cache<String, String> cache;

    public AzureSpeechTokenService(AzureSpeechProperties props) {
        this.props = props;
        this.restClient = RestClient.builder()
            .requestFactory(buildRequestFactory(props.getTimeoutSec()))
            .build();
        this.cache = Caffeine.newBuilder()
            .expireAfterWrite(Duration.ofMinutes(9))
            .maximumSize(1)
            .build();
    }

    public String getToken() {
        if (!props.isConfigured()) {
            throw new AudioServicesUnavailableException(
                "AZURE_SPEECH_KEY/REGION non configures. Renseignez-les dans l'environnement."
            );
        }
        String cached = cache.getIfPresent(CACHE_KEY);
        if (cached != null) return cached;
        String fresh = fetchToken();
        cache.put(CACHE_KEY, fresh);
        return fresh;
    }

    public void invalidate() {
        cache.invalidate(CACHE_KEY);
    }

    private String fetchToken() {
        try {
            String token = restClient.post()
                .uri(props.getTokenEndpointUrl())
                .header("Ocp-Apim-Subscription-Key", props.getKey())
                .header("Content-Length", "0")
                .retrieve()
                .body(String.class);
            if (token == null || token.isBlank()) {
                throw new AzureSpeechException("Token Azure vide");
            }
            log.debug("Token Azure Speech obtenu ({} chars)", token.length());
            return token;
        } catch (HttpClientErrorException.Unauthorized e) {
            throw new AzureSpeechException("AZURE_SPEECH_KEY invalide (401)", e);
        } catch (HttpServerErrorException e) {
            throw new AzureSpeechTransientException("Azure token 5xx (" + e.getStatusCode() + ")", e);
        } catch (HttpClientErrorException e) {
            throw new AzureSpeechException("Azure token 4xx (" + e.getStatusCode() + ")", e);
        } catch (ResourceAccessException e) {
            throw new AzureSpeechTransientException("Azure token timeout ou erreur reseau", e);
        }
    }

    /**
     * SimpleClientHttpRequestFactory (HttpURLConnection) plutot que JdkClientHttpRequestFactory :
     * Azure exige un header Content-Length sur POST /issueToken, que le JDK HttpClient
     * supprime sur un body vide -> 411 LENGTH_REQUIRED. HttpURLConnection le respecte.
     */
    private static ClientHttpRequestFactory buildRequestFactory(int timeoutSec) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(Math.min(timeoutSec, 10)));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSec));
        return factory;
    }
}
