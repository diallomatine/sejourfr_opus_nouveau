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
     * Lecture publique des sujets du diagnostic : borne large par IP. Cet
     * endpoint ne fait qu'ecrire zero ligne et lire du contenu seede, mais il
     * est ouvert : la limite existe pour couper une boucle automatisee, pas
     * pour compter les consultations d'un visiteur reel.
     */
    public void checkPublicDiagnostic(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("public-diagnostic", ip, props.getPublicDiagnostic());
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

    /**
     * Tentative sur un petit sujet de competence : meme double garde-fou que la
     * production complete (burst anti-boucle + plafond journalier anti-facture),
     * mais avec des seuils plus larges, un micro-exercice etant beaucoup plus
     * court. S'applique a TOUTES les tentatives, analysees ou non : une
     * production sans analyse ne coute pas de LLM mais insere quand meme une
     * ligne, et c'est le seul frein a une boucle automatisee. Le quota freemium
     * des analyses, lui, est gere ailleurs
     * ({@code SkillAnalysisAccessService}) — ceci ne borne que le volume absolu.
     */
    public void checkSkillAttempt(UUID userId) {
        if (!props.isEnabled() || userId == null) return;
        String key = userId.toString();
        limiter.check("skill-attempt:burst", key, props.getSkillAttemptBurst());
        limiter.check("skill-attempt:daily", key, props.getSkillAttemptDaily());
    }

    /**
     * Ingestion d'un evenement d'analytics : double garde-fou par IP.
     *
     * <p>C'est le seul frein a l'inflation d'{@code analytics_event}, route
     * publique qui ecrit une ligne par appel. Le trou laisse sur
     * {@code /api/public/page-views} (table agregee, donc bornee autrement) ne
     * se reproduit pas ici.
     *
     * <p>Volontairement genereux : on coupe la boucle automatisee, on ne gene
     * pas un visiteur qui parcourt le site.
     */
    public void checkAnalytics(String ip) {
        if (!props.isEnabled()) return;
        limiter.check("analytics:burst", ip, props.getAnalyticsBurst());
        limiter.check("analytics:daily", ip, props.getAnalyticsDaily());
    }

    private String normalizeEmail(String email) {
        return email == null ? null : email.trim().toLowerCase();
    }
}
