package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Stripe lue depuis application.yaml (clé sejourfr.stripe).
 * Les clés sont volontairement String vides par défaut : le backend démarre
 * sans Stripe configuré, mais l'endpoint create-checkout-session renverra
 * 503 tant que la secret key n'est pas définie.
 */
@ConfigurationProperties(prefix = "sejourfr.stripe")
public class StripeProperties {

    private String secretKey = "";
    private String webhookSecret = "";
    private String priceMonthly = "";
    private String priceYearly = "";
    private String successUrl = "";
    private String cancelUrl = "";

    public boolean isConfigured() {
        return !secretKey.isBlank() && !priceMonthly.isBlank() && !priceYearly.isBlank();
    }

    public String getSecretKey() { return secretKey; }
    public void setSecretKey(String v) { this.secretKey = v; }

    public String getWebhookSecret() { return webhookSecret; }
    public void setWebhookSecret(String v) { this.webhookSecret = v; }

    public String getPriceMonthly() { return priceMonthly; }
    public void setPriceMonthly(String v) { this.priceMonthly = v; }

    public String getPriceYearly() { return priceYearly; }
    public void setPriceYearly(String v) { this.priceYearly = v; }

    public String getSuccessUrl() { return successUrl; }
    public void setSuccessUrl(String v) { this.successUrl = v; }

    public String getCancelUrl() { return cancelUrl; }
    public void setCancelUrl(String v) { this.cancelUrl = v; }
}
