package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Stripe lue depuis application.yaml (clé sejourfr.stripe).
 *
 * <p>Depuis le lot 4 (passage en abonnements récurrents), les Stripe Price IDs
 * vivent en base (colonne {@code plans.stripe_price_id}) et non plus dans
 * cette config. Cette classe ne porte plus que les secrets et l'URL d'app :
 * <ul>
 *   <li><b>secretKey</b> : clé serveur Stripe (sk_test_xxx ou sk_live_xxx).</li>
 *   <li><b>webhookSecret</b> : secret de signature HMAC du webhook
 *       (whsec_xxx).</li>
 *   <li><b>appBaseUrl</b> : URL de base de l'app web utilisée pour
 *       construire les success_url / cancel_url des Checkout Sessions.</li>
 * </ul>
 *
 * <p>Si {@link #isConfigured()} renvoie false, les endpoints billing répondent
 * 503 — l'app reste démarrable sans config Stripe.
 */
@ConfigurationProperties(prefix = "sejourfr.stripe")
public class StripeProperties {

    private String secretKey = "";
    private String webhookSecret = "";

    /**
     * URL de base de l'app web utilisée pour construire success_url et
     * cancel_url des Checkout Sessions. Ex: {@code http://localhost:3000} en
     * dev, {@code https://sejourfr.fr} en prod.
     */
    private String appBaseUrl = "http://localhost:3000";

    /** Stripe est-il assez configuré pour servir des paiements ? */
    public boolean isConfigured() {
        return !secretKey.isBlank();
    }

    public String getSecretKey() { return secretKey; }
    public void setSecretKey(String v) { this.secretKey = v; }

    public String getWebhookSecret() { return webhookSecret; }
    public void setWebhookSecret(String v) { this.webhookSecret = v; }

    public String getAppBaseUrl() { return appBaseUrl; }
    public void setAppBaseUrl(String v) { this.appBaseUrl = v; }
}
