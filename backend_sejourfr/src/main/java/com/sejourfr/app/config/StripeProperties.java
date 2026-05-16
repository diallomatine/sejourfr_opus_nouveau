package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Stripe lue depuis application.yaml (clé sejourfr.stripe).
 *
 * Deux modes supportés :
 *
 *  1. **Checkout Sessions** (recommandé, mode par défaut si configuré) :
 *     on fournit les Stripe Price IDs (price-civique / price-integral) et
 *     l'app-base-url. Le backend crée dynamiquement une Session par paiement
 *     avec success_url et cancel_url construits en code → pas de config
 *     dashboard nécessaire, l'URL de retour reste cohérente avec le
 *     déploiement courant.
 *
 *  2. **Payment Links statiques** (fallback historique) : on fournit
 *     payment-link-civique / payment-link-integral (URLs déjà créées dans le
 *     dashboard Stripe). Pas de redirection automatique sauf si configurée
 *     côté dashboard.
 *
 *  Si les deux sont définis, les Checkout Sessions priment.
 *
 * Le backend reste fonctionnel sans Stripe configuré (les endpoints
 * /api/billing renverront 503).
 */
@ConfigurationProperties(prefix = "sejourfr.stripe")
public class StripeProperties {

    private String secretKey = "";
    private String webhookSecret = "";

    /** Payment Link Stripe pour le plan Civique 3 mois (fallback). */
    private String paymentLinkCivique = "";
    /** Payment Link Stripe pour le plan Intégral 3 mois (fallback). */
    private String paymentLinkIntegral = "";

    /** Stripe Price ID (format `price_xxx`) du plan Civique 3 mois. */
    private String priceCivique = "";
    /** Stripe Price ID (format `price_xxx`) du plan Intégral 3 mois. */
    private String priceIntegral = "";

    /**
     * URL de base de l'app web utilisée pour construire success_url et
     * cancel_url des Checkout Sessions. Ex: "http://localhost:3000" en dev,
     * "https://sejourfr.fr" en prod.
     */
    private String appBaseUrl = "http://localhost:3000";

    /** Le mode Checkout Session (recommandé) est-il utilisable ? */
    public boolean isCheckoutSessionConfigured() {
        return !secretKey.isBlank()
                && !priceCivique.isBlank()
                && !priceIntegral.isBlank();
    }

    /** Le mode Payment Link statique (fallback) est-il utilisable ? */
    public boolean isPaymentLinkConfigured() {
        return !secretKey.isBlank()
                && !paymentLinkCivique.isBlank()
                && !paymentLinkIntegral.isBlank();
    }

    /** Stripe est-il assez configuré pour servir des paiements (un mode au moins) ? */
    public boolean isConfigured() {
        return isCheckoutSessionConfigured() || isPaymentLinkConfigured();
    }

    public String getSecretKey() { return secretKey; }
    public void setSecretKey(String v) { this.secretKey = v; }

    public String getWebhookSecret() { return webhookSecret; }
    public void setWebhookSecret(String v) { this.webhookSecret = v; }

    public String getPaymentLinkCivique() { return paymentLinkCivique; }
    public void setPaymentLinkCivique(String v) { this.paymentLinkCivique = v; }

    public String getPaymentLinkIntegral() { return paymentLinkIntegral; }
    public void setPaymentLinkIntegral(String v) { this.paymentLinkIntegral = v; }

    public String getPriceCivique() { return priceCivique; }
    public void setPriceCivique(String v) { this.priceCivique = v; }

    public String getPriceIntegral() { return priceIntegral; }
    public void setPriceIntegral(String v) { this.priceIntegral = v; }

    public String getAppBaseUrl() { return appBaseUrl; }
    public void setAppBaseUrl(String v) { this.appBaseUrl = v; }
}
