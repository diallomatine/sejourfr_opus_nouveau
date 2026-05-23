package com.sejourfr.app.config;

import com.apple.itunes.storekit.model.Environment;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Apple App Store Server lue depuis application.yaml
 * (clé {@code sejourfr.apple}). Tant qu'au moins un des champs critiques est
 * vide, {@link #isConfigured()} renvoie false et les endpoints IAP Apple
 * répondent 503.
 *
 * <p>Comment obtenir les valeurs côté App Store Connect :
 * <ul>
 *   <li><b>issuerId</b> : Users and Access → Integrations → App Store Server API.
 *       Format UUID.</li>
 *   <li><b>keyId</b> : généré côté App Store Connect (10 caractères).</li>
 *   <li><b>privateKey</b> : contenu du fichier P8 téléchargé une seule fois lors
 *       de la création de la clé. À stocker en variable d'env, pas commité.</li>
 *   <li><b>bundleId</b> : identifiant exact du bundle iOS de l'app (ex:
 *       {@code com.sejourfr.app}).</li>
 *   <li><b>appAppleId</b> : id numérique de l'app dans l'App Store (PRODUCTION
 *       uniquement, null en sandbox).</li>
 *   <li><b>environment</b> : {@code SANDBOX} en dev, {@code PRODUCTION} en prod.
 *       L'app mobile choisit en fonction de son build (TestFlight = sandbox,
 *       App Store = prod). Le backend doit suivre.</li>
 * </ul>
 *
 * <p>Les root certs Apple nécessaires à la vérification JWS sont chargés depuis
 * {@link #getRootCertsClasspath()} (par défaut {@code classpath:apple/*.cer}).
 * Cf. CLAUDE.md racine pour la procédure de téléchargement des certs (3
 * fichiers : AppleRootCA-G3.cer + AppleIncRootCertificate.cer + AppleComputerRootCertificate.cer).
 */
@ConfigurationProperties(prefix = "sejourfr.apple")
public class AppleProperties {

    private String issuerId = "";
    private String keyId = "";
    private String privateKey = "";
    private String bundleId = "";
    /** {@code null} en sandbox, requis en production. */
    private Long appAppleId;
    private Environment environment = Environment.SANDBOX;
    /**
     * Pattern Spring Resource pour charger les root certs Apple. Le bean
     * {@code AppleStoreClient} charge tous les .cer matchant ce pattern et les
     * passe au SignedDataVerifier.
     */
    private String rootCertsClasspath = "classpath:apple/*.cer";
    /**
     * Active les vérifications en ligne supplémentaires du verifier (vérif
     * OCSP/CRL de la chaîne de certifs). À true en prod, peut rester true en
     * sandbox.
     */
    private boolean enableOnlineChecks = true;

    /**
     * Vrai si la config minimale est présente pour valider des reçus et
     * traiter des notifications. {@code appAppleId} n'est requis qu'en
     * production — en sandbox le verifier accepte null.
     */
    public boolean isConfigured() {
        if (issuerId.isBlank() || keyId.isBlank() || privateKey.isBlank() || bundleId.isBlank()) {
            return false;
        }
        if (environment == Environment.PRODUCTION && appAppleId == null) {
            return false;
        }
        return true;
    }

    public String getIssuerId() { return issuerId; }
    public void setIssuerId(String issuerId) { this.issuerId = issuerId; }

    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }

    public String getPrivateKey() { return privateKey; }
    public void setPrivateKey(String privateKey) { this.privateKey = privateKey; }

    public String getBundleId() { return bundleId; }
    public void setBundleId(String bundleId) { this.bundleId = bundleId; }

    public Long getAppAppleId() { return appAppleId; }
    public void setAppAppleId(Long appAppleId) { this.appAppleId = appAppleId; }

    public Environment getEnvironment() { return environment; }
    public void setEnvironment(Environment environment) { this.environment = environment; }

    public String getRootCertsClasspath() { return rootCertsClasspath; }
    public void setRootCertsClasspath(String rootCertsClasspath) { this.rootCertsClasspath = rootCertsClasspath; }

    public boolean isEnableOnlineChecks() { return enableOnlineChecks; }
    public void setEnableOnlineChecks(boolean enableOnlineChecks) { this.enableOnlineChecks = enableOnlineChecks; }
}
