package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.Module;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Toutes les URLs que les emails citent, en un seul endroit.
 *
 * <p>Liens <b>web uniquement</b> (arbitrage n°14) : aucune universal link /
 * app link mobile dans ce chantier. Les bases viennent de
 * {@code sejourfr.app.base-url} / {@code sejourfr.backend.base-url}, declares dans
 * le YAML de base (cf. {@code MailLinkBaseUrlsTest}).
 */
@Component
public class EmailLinks {

    private final String appBaseUrl;
    private final String backendBaseUrl;

    public EmailLinks(@Value("${sejourfr.app.base-url:http://localhost:3000}") String appBaseUrl,
                      @Value("${sejourfr.backend.base-url:http://localhost:8080}") String backendBaseUrl) {
        this.appBaseUrl = stripSlash(appBaseUrl);
        this.backendBaseUrl = stripSlash(backendBaseUrl);
    }

    public String app() {
        return appBaseUrl;
    }

    public String dashboard() {
        return appBaseUrl + "/dashboard";
    }

    public String plan(Module module) {
        return appBaseUrl + "/plan?module=" + module.name();
    }

    /** « Mon pass » : la page de gestion de l'acces (arbitrage n°6), jamais /paiement. */
    public String manageAccess() {
        return appBaseUrl + "/profil/abonnement";
    }

    public String contact() {
        return appBaseUrl + "/contact";
    }

    public String notificationSettings() {
        return appBaseUrl + "/profil/notifications";
    }

    /** 🛑 Contient un jeton : ne jamais logguer. */
    public String passwordReset(String rawToken) {
        return appBaseUrl + "/reinitialiser-mot-de-passe?token=" + rawToken;
    }

    /** 🛑 Contient un jeton : ne jamais logguer. */
    public String emailChangeConfirmation(String rawToken) {
        return backendBaseUrl + "/api/auth/confirm-email-change?token=" + rawToken;
    }

    /** 🛑 Contient un jeton : ne jamais logguer. */
    public String unsubscribePage(String token) {
        return backendBaseUrl + "/api/public/email/unsubscribe?token=" + token;
    }

    /** 🛑 Contient un jeton : ne jamais logguer. */
    public String unsubscribeOneClick(String token) {
        return backendBaseUrl + "/api/public/email/unsubscribe/one-click?token=" + token;
    }

    public String unsubscribeFormAction() {
        return backendBaseUrl + "/api/public/email/unsubscribe";
    }

    private static String stripSlash(String url) {
        if (url == null) return "";
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
