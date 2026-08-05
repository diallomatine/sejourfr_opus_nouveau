package com.sejourfr.app.ratelimit;

import com.sejourfr.app.config.RateLimitProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Facade metier du rate-limiting : expose une methode par surface protegee,
 * appelee en bord d'entree (controllers) ou en tete de cas d'usage (service
 * production). Centralise la lecture de la config et le choix des cles, pour
 * que les appelants restent declaratifs.
 *
 * <p>Chaque methode est un no-op si le mecanisme est globalement desactive
 * ({@code sejourfr.rate-limit.enabled=false}).
 */
@Component
@RequiredArgsConstructor
public class RateLimitGuard {

    private final RateLimitProperties props;
    private final InMemoryRateLimiter limiter;

    /** Connexion : limite par IP (stuffing) ET par compte (brute force cible). */
    public void checkLogin(String ip, String email) {
        if (!props.isEnabled()) return;
        limiter.check("login:ip", ip, props.getLogin());
        limiter.check("login:account", normalizeEmail(email), props.getLoginPerAccount());
    }

    /**
     * Authentification reussie : on efface les compteurs IP et compte. Sans ce
     * reset, quelques connexions legitimes d'affilee (reconnexion, plusieurs
     * appareils, tests) epuisaient la fenetre et renvoyaient 429 pendant un
     * quart d'heure. Ce qu'on veut freiner, c'est l'ENCHAINEMENT D'ECHECS.
     */
    public void onLoginSuccess(String ip, String email) {
        if (!props.isEnabled()) return;
        limiter.reset("login:ip", ip);
        limiter.reset("login:account", normalizeEmail(email));
    }

    public void checkRegister(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("register", ip, props.getRegister());
    }

    public void checkForgotPassword(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("forgot-password", ip, props.getForgotPassword());
    }

    public void checkResetPassword(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("reset-password", ip, props.getResetPassword());
    }

    public void checkContact(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("contact", ip, props.getContact());
    }

    public void checkDemo(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("demo", ip, props.getDemo());
    }

    /**
     * Soumission production EE/EO (Whisper + Claude/OpenAI) : double garde-fou
     * par utilisateur — burst court (anti-boucle) + plafond journalier
     * (anti-facture). Applique a tous les tiers : le quota freemium reste gere
     * separement, ceci ne borne que le volume absolu.
     */
    public void checkProductionSubmission(UUID userId) {
        if (!props.isEnabled() || userId == null) return;
        String key = userId.toString();
        limiter.check("production:burst", key, props.getProductionBurst());
        limiter.check("production:daily", key, props.getProductionDaily());
    }

    private String normalizeEmail(String email) {
        return email == null ? null : email.trim().toLowerCase();
    }
}
