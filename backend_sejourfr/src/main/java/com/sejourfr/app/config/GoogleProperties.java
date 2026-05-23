package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Google Play Billing lue depuis application.yaml
 * (clé {@code sejourfr.google}). Tant qu'un champ critique est vide,
 * {@link #isConfigured()} renvoie false et les endpoints IAP Android
 * répondent 503.
 *
 * <p>Comment obtenir les valeurs :
 * <ul>
 *   <li><b>serviceAccountJson</b> : contenu (raw JSON) de la clé Service Account
 *       générée dans Google Cloud Console → IAM → Service Accounts → "+ Create
 *       Key" → JSON. Le compte doit avoir le rôle "Service Account User" et
 *       être linké à Google Play Console (Setup → API access → Grant access
 *       à ce SA avec la permission "View financial data" et "Manage orders
 *       and subscriptions"). Stocké en variable d'env, jamais commité.</li>
 *   <li><b>packageName</b> : application id Android (ex: {@code com.sejourfr.app}).
 *       Doit matcher exactement celui de la fiche Play Console.</li>
 *   <li><b>pubSubAudience</b> : valeur attendue dans le claim {@code aud} du
 *       JWT Bearer Pub/Sub. Posée lors de la création de la push subscription
 *       (Cloud Console → Pub/Sub → Subscription → Authentication → Audience).
 *       Convention : URL de l'endpoint (ex: {@code https://api.sejourfr.fr/api/billing/webhooks/google}).</li>
 *   <li><b>pubSubServiceAccountEmail</b> : email du service account qui signe
 *       le JWT Pub/Sub. Doit matcher le claim {@code email} du JWT (et donc
 *       l'auth-service-account de la push subscription).</li>
 * </ul>
 *
 * <p>Le RTDN topic doit être créé côté Google Cloud (Pub/Sub) et déclaré dans
 * Play Console → l'app → Monetization setup → Real-time developer notifications.
 */
@ConfigurationProperties(prefix = "sejourfr.google")
public class GoogleProperties {

    private String serviceAccountJson = "";
    private String packageName = "";
    /** URL exacte du webhook (= valeur du claim {@code aud}). */
    private String pubSubAudience = "";
    /** Email du service account configuré sur la push subscription Pub/Sub. */
    private String pubSubServiceAccountEmail = "";

    public boolean isConfigured() {
        return !serviceAccountJson.isBlank()
                && !packageName.isBlank()
                && !pubSubAudience.isBlank()
                && !pubSubServiceAccountEmail.isBlank();
    }

    public String getServiceAccountJson() { return serviceAccountJson; }
    public void setServiceAccountJson(String serviceAccountJson) { this.serviceAccountJson = serviceAccountJson; }

    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }

    public String getPubSubAudience() { return pubSubAudience; }
    public void setPubSubAudience(String pubSubAudience) { this.pubSubAudience = pubSubAudience; }

    public String getPubSubServiceAccountEmail() { return pubSubServiceAccountEmail; }
    public void setPubSubServiceAccountEmail(String pubSubServiceAccountEmail) { this.pubSubServiceAccountEmail = pubSubServiceAccountEmail; }
}
