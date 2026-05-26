package com.sejourfr.app.service.billing;

import com.apple.itunes.storekit.client.AppStoreServerAPIClient;
import com.apple.itunes.storekit.client.APIException;
import com.apple.itunes.storekit.model.JWSRenewalInfoDecodedPayload;
import com.apple.itunes.storekit.model.JWSTransactionDecodedPayload;
import com.apple.itunes.storekit.model.ResponseBodyV2DecodedPayload;
import com.apple.itunes.storekit.model.TransactionInfoResponse;
import com.apple.itunes.storekit.verification.SignedDataVerifier;
import com.apple.itunes.storekit.verification.VerificationException;
import com.sejourfr.app.config.AppleProperties;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;

/**
 * Wrapper unique sur la lib Apple {@code app-store-server-library}. Centralise :
 * <ul>
 *   <li>Vérification JWS des transactions / notifications / renewal info
 *       (cf. {@link SignedDataVerifier}).</li>
 *   <li>Appels authentifiés à l'App Store Server API (cf.
 *       {@link AppStoreServerAPIClient}) — JWT signé p8.</li>
 * </ul>
 *
 * <p>Si {@link AppleProperties#isConfigured()} = false ou que les root certs
 * sont introuvables, le bean reste instancié mais {@link #isReady()} renvoie
 * false et toutes les méthodes lèvent 503. Permet à l'app de démarrer en local
 * sans config Apple, tout en signalant explicitement aux endpoints qu'ils ne
 * peuvent pas servir.
 *
 * <p>Les root certs Apple (.cer) doivent être placés dans
 * {@code src/main/resources/apple/} :
 * <ul>
 *   <li>AppleRootCA-G3.cer (obligatoire — signature actuelle des JWS Apple)</li>
 *   <li>AppleRootCA-G2.cer (par sécurité)</li>
 *   <li>AppleIncRootCertificate.cer (legacy, par sécurité)</li>
 * </ul>
 * Téléchargeables sur <a href="https://www.apple.com/certificateauthority/">apple.com/certificateauthority</a>.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AppleStoreClient {

    private final AppleProperties properties;
    private final ResourcePatternResolver resourceResolver = new PathMatchingResourcePatternResolver();

    private SignedDataVerifier verifier;
    private AppStoreServerAPIClient apiClient;

    @PostConstruct
    public void init() {
        if (!properties.isConfigured()) {
            log.warn(
                    "Apple App Store non configuré (sejourfr.apple.*) — endpoints IAP iOS renverront 503."
            );
            return;
        }
        try {
            Set<InputStream> rootCAs = loadRootCerts();
            if (rootCAs.isEmpty()) {
                log.warn(
                        "Aucun root cert Apple trouvé via '{}' — vérification JWS impossible, endpoints iOS en 503.",
                        properties.getRootCertsClasspath()
                );
                return;
            }
            this.verifier = new SignedDataVerifier(
                    rootCAs,
                    properties.getBundleId(),
                    properties.getAppAppleId(),
                    properties.getEnvironment(),
                    properties.isEnableOnlineChecks()
            );
            this.apiClient = new AppStoreServerAPIClient(
                    resolvePrivateKey(),
                    properties.getKeyId(),
                    properties.getIssuerId(),
                    properties.getBundleId(),
                    properties.getEnvironment()
            );
            log.info(
                    "Apple App Store prêt — env={} bundle={} roots={}",
                    properties.getEnvironment(),
                    properties.getBundleId(),
                    rootCAs.size()
            );
        } catch (IOException e) {
            log.error("Échec chargement root certs Apple : {}", e.getMessage(), e);
        } catch (RuntimeException e) {
            // Clé p8 malformée, certs invalides, etc. On ne casse pas le boot :
            // le bean reste non-ready (isReady() == false) → endpoints en 503.
            this.verifier = null;
            this.apiClient = null;
            log.error(
                    "Init Apple App Store échouée ({}) — endpoints IAP iOS en 503. "
                            + "Vérifie sejourfr.apple.private-key (contenu PEM du .p8 ou chemin vers le fichier).",
                    e.getMessage(), e
            );
        }
    }

    /**
     * La lib Apple attend le <b>contenu PEM</b> du .p8. On tolère aussi qu'on
     * lui passe un <b>chemin de fichier</b> (.p8) : pratique en dev pour pointer
     * directement sur la clé sans inliner le PEM dans une variable d'env.
     */
    private String resolvePrivateKey() {
        String raw = properties.getPrivateKey().trim();
        if (raw.contains("-----BEGIN")) {
            return raw;
        }
        Path path = Path.of(raw);
        if (Files.isRegularFile(path)) {
            try {
                return Files.readString(path);
            } catch (IOException e) {
                throw new IllegalStateException(
                        "Impossible de lire le fichier de clé privée Apple : " + raw, e
                );
            }
        }
        return raw;
    }

    /** Vrai si le client est utilisable (config + certs OK). */
    public boolean isReady() {
        return verifier != null && apiClient != null;
    }

    /**
     * Vérifie + décode un {@code signedTransactionInfo} (JWS remonté par
     * l'app mobile dans {@code verify-receipt}, ou intégré aux notifications).
     * Lève {@link VerificationException} si la signature ne valide pas.
     */
    public JWSTransactionDecodedPayload verifyTransaction(String signedTransactionInfo)
            throws VerificationException {
        ensureReady();
        return verifier.verifyAndDecodeTransaction(signedTransactionInfo);
    }

    /**
     * Vérifie + décode un payload d'App Store Server Notifications V2.
     */
    public ResponseBodyV2DecodedPayload verifyNotification(String signedPayload)
            throws VerificationException {
        ensureReady();
        return verifier.verifyAndDecodeNotification(signedPayload);
    }

    /**
     * Vérifie + décode un {@code signedRenewalInfo} (présent dans les
     * notifications de renouvellement / changement de statut).
     */
    public JWSRenewalInfoDecodedPayload verifyRenewalInfo(String signedRenewalInfo)
            throws VerificationException {
        ensureReady();
        return verifier.verifyAndDecodeRenewalInfo(signedRenewalInfo);
    }

    /**
     * Re-fetch l'état autoritatif d'une transaction côté Apple. Utile quand
     * un webhook nous dit "ça a changé" : on ne se fie pas à la valeur
     * remontée dans la notification, on la confirme via l'API.
     *
     * @param transactionId originalTransactionId ou transactionId courant.
     * @return le payload décodé, ou empty si l'API échoue.
     */
    public JWSTransactionDecodedPayload getTransactionInfo(String transactionId)
            throws APIException, IOException, VerificationException {
        ensureReady();
        TransactionInfoResponse response = apiClient.getTransactionInfo(transactionId);
        String signedTx = response.getSignedTransactionInfo();
        if (signedTx == null || signedTx.isBlank()) {
            throw new IllegalStateException(
                    "Apple getTransactionInfo a renvoyé un signedTransactionInfo vide pour " + transactionId
            );
        }
        return verifier.verifyAndDecodeTransaction(signedTx);
    }

    private void ensureReady() {
        if (!isReady()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Apple App Store non configuré côté backend (sejourfr.apple.* + root certs)."
            );
        }
    }

    private Set<InputStream> loadRootCerts() throws IOException {
        Resource[] certs = resourceResolver.getResources(properties.getRootCertsClasspath());
        Set<InputStream> streams = new HashSet<>();
        for (Resource c : certs) {
            streams.add(c.getInputStream());
        }
        return streams;
    }
}
