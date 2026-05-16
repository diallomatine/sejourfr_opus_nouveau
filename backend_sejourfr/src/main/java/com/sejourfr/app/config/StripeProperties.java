package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration Stripe lue depuis application.yaml (clé sejourfr.stripe).
 *
 * Modèle paiement : Stripe Payment Links (un lien pré-configuré dans le
 * Dashboard Stripe par plan). Le backend ne crée plus de Checkout Session,
 * il renvoie simplement l'URL du payment link enrichie d'un
 * client_reference_id (= user_id) pour retrouver l'utilisateur lors du
 * webhook checkout.session.completed.
 *
 * Les clés sont volontairement String vides par défaut : le backend démarre
 * sans Stripe configuré, mais les endpoints billing renverront 503 tant que
 * la secret key et les payment links ne sont pas définis.
 */
@ConfigurationProperties(prefix = "sejourfr.stripe")
public class StripeProperties {

    private String secretKey = "";
    private String webhookSecret = "";
    /** Payment Link Stripe pour le plan Civique 3 mois. */
    private String paymentLinkCivique = "";
    /** Payment Link Stripe pour le plan Intégral 3 mois. */
    private String paymentLinkIntegral = "";

    public boolean isConfigured() {
        return !secretKey.isBlank()
                && !paymentLinkCivique.isBlank()
                && !paymentLinkIntegral.isBlank();
    }

    public String getSecretKey() { return secretKey; }
    public void setSecretKey(String v) { this.secretKey = v; }

    public String getWebhookSecret() { return webhookSecret; }
    public void setWebhookSecret(String v) { this.webhookSecret = v; }

    public String getPaymentLinkCivique() { return paymentLinkCivique; }
    public void setPaymentLinkCivique(String v) { this.paymentLinkCivique = v; }

    public String getPaymentLinkIntegral() { return paymentLinkIntegral; }
    public void setPaymentLinkIntegral(String v) { this.paymentLinkIntegral = v; }
}
