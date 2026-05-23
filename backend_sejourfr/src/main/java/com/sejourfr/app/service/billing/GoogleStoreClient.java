package com.sejourfr.app.service.billing;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.androidpublisher.AndroidPublisher;
import com.google.api.services.androidpublisher.AndroidPublisherScopes;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseV2;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import com.sejourfr.app.config.GoogleProperties;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.Collections;

/**
 * Wrapper unique sur l'API Google Play Developer (AndroidPublisher) + vérif
 * d'authenticité des notifications Pub/Sub. Centralise :
 * <ul>
 *   <li>{@link #getSubscriptionV2(String)} — état autoritatif d'un achat IAP
 *       Android (statut, expiry, auto-renew) à partir d'un {@code purchaseToken}.</li>
 *   <li>{@link #verifyPubSubBearer(String)} — valide le JWT Bearer envoyé par
 *       Pub/Sub dans le header {@code Authorization}. Vérifie la signature
 *       Google, l'audience attendue, et l'email du service account.</li>
 * </ul>
 *
 * <p>Si {@link GoogleProperties#isConfigured()} = false, le bean reste créé
 * mais {@link #isReady()} renvoie false et toutes les méthodes lèvent 503.
 * Permet à l'app de démarrer en local sans config Google.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GoogleStoreClient {

    /**
     * Issuer Google standard pour les ID tokens signés par un Service Account
     * (utilisés pour signer le JWT Pub/Sub).
     */
    private static final String GOOGLE_ISSUER = "https://accounts.google.com";

    private static final String APP_NAME = "SejourFR backend";

    private final GoogleProperties properties;

    private AndroidPublisher androidPublisher;
    private GoogleIdTokenVerifier pubSubVerifier;

    @PostConstruct
    public void init() {
        if (!properties.isConfigured()) {
            log.warn(
                    "Google Play non configuré (sejourfr.google.*) — endpoints IAP Android renverront 503."
            );
            return;
        }
        try {
            NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
            GsonFactory jsonFactory = GsonFactory.getDefaultInstance();

            GoogleCredentials credentials = GoogleCredentials
                    .fromStream(new ByteArrayInputStream(
                            properties.getServiceAccountJson().getBytes(StandardCharsets.UTF_8)))
                    .createScoped(Collections.singletonList(AndroidPublisherScopes.ANDROIDPUBLISHER));

            this.androidPublisher = new AndroidPublisher.Builder(
                    httpTransport, jsonFactory, new HttpCredentialsAdapter(credentials))
                    .setApplicationName(APP_NAME)
                    .build();

            this.pubSubVerifier = new GoogleIdTokenVerifier.Builder(httpTransport, jsonFactory)
                    .setAudience(Collections.singletonList(properties.getPubSubAudience()))
                    .setIssuer(GOOGLE_ISSUER)
                    .build();

            log.info(
                    "Google Play prêt — package={} pubSubAudience={}",
                    properties.getPackageName(), properties.getPubSubAudience()
            );
        } catch (IOException | GeneralSecurityException e) {
            log.error("Échec init Google Play : {}", e.getMessage());
        }
    }

    public boolean isReady() {
        return androidPublisher != null && pubSubVerifier != null;
    }

    /**
     * Récupère l'état autoritatif d'un achat IAP Android. Le {@code
     * purchaseToken} sert à la fois de paramètre d'appel ET de clé de
     * réconciliation côté backend (= {@code originalTransactionId} dans
     * notre schéma multi-source).
     *
     * @throws IOException si l'appel API Play échoue.
     */
    public SubscriptionPurchaseV2 getSubscriptionV2(String purchaseToken) throws IOException {
        ensureReady();
        return androidPublisher.purchases().subscriptionsv2()
                .get(properties.getPackageName(), purchaseToken)
                .execute();
    }

    /**
     * Valide le JWT Bearer Pub/Sub envoyé dans {@code Authorization: Bearer <jwt>}.
     * Le JWT est signé par le Service Account configuré sur la push subscription
     * Pub/Sub. On vérifie :
     * <ol>
     *   <li>Signature contre les clés publiques Google.</li>
     *   <li>Claim {@code aud} = {@link GoogleProperties#getPubSubAudience()}.</li>
     *   <li>Claim {@code email} = {@link GoogleProperties#getPubSubServiceAccountEmail()}.</li>
     * </ol>
     *
     * @return l'email du service account (loggé pour audit).
     * @throws ResponseStatusException 401 si une vérification échoue.
     */
    public String verifyPubSubBearer(String authorizationHeader) {
        ensureReady();
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Header Authorization Bearer manquant sur webhook Google."
            );
        }
        String jwt = authorizationHeader.substring("Bearer ".length()).trim();
        try {
            GoogleIdToken token = pubSubVerifier.verify(jwt);
            if (token == null) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "JWT Pub/Sub invalide (signature, audience ou expiration)."
                );
            }
            String email = (String) token.getPayload().get("email");
            if (email == null || !email.equalsIgnoreCase(properties.getPubSubServiceAccountEmail())) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "JWT Pub/Sub : email service account inattendu (" + email + ")."
                );
            }
            return email;
        } catch (GeneralSecurityException | IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Échec vérification JWT Pub/Sub : " + e.getMessage(),
                    e
            );
        }
    }

    private void ensureReady() {
        if (!isReady()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Google Play non configuré côté backend (sejourfr.google.*)."
            );
        }
    }

    /** Expose le package name configuré (utilisé pour les acks et logs). */
    public String getPackageName() {
        return properties.getPackageName();
    }
}
