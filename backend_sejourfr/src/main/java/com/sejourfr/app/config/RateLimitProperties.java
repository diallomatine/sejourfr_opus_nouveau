package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Limites anti-abus / anti-brute-force par IP ou par utilisateur, appliquees
 * en memoire (cf. {@code ratelimit.InMemoryRateLimiter}) sur les surfaces
 * publiques sensibles (auth, contact, demo guest) et sur les endpoints
 * couteux en LLM (soumissions production EE/EO).
 *
 * <p>Garde-fou volontairement <strong>genereux</strong> : l'objectif est de
 * couper l'abus automatise (bot, credential stuffing, boucle de notation),
 * pas de gener un utilisateur reel. Toutes les valeurs sont surchargeables
 * par environnement ; {@code enabled=false} desactive globalement le
 * mecanisme (soupape de securite si un faux positif apparait en prod).
 *
 * <p>Un {@code max <= 0} sur une limite donnee la desactive individuellement.
 */
@ConfigurationProperties(prefix = "sejourfr.rate-limit")
public class RateLimitProperties {

    /** Interrupteur global. {@code false} = aucune limite appliquee. */
    private boolean enabled = true;

    /** Connexion : par IP (credential stuffing multi-comptes). */
    private Limit login = new Limit(30, 300);
    /** Connexion : par compte/email (brute force cible). */
    private Limit loginPerAccount = new Limit(10, 900);
    /** Creation de compte : par IP (creation de masse). */
    private Limit register = new Limit(10, 3600);
    /** Mot de passe oublie : par IP (flood d'emails). */
    private Limit forgotPassword = new Limit(5, 3600);
    /** Reinitialisation : par IP. */
    private Limit resetPassword = new Limit(10, 3600);
    /** Formulaire de contact : par IP (flood d'emails). */
    private Limit contact = new Limit(5, 3600);
    /** Demo guest : par IP (inflation de la table attempts par bot). */
    private Limit demo = new Limit(60, 600);
    /** Soumission production EE/EO : burst par utilisateur (cout LLM). */
    private Limit productionBurst = new Limit(20, 600);
    /** Soumission production EE/EO : plafond journalier par utilisateur. */
    private Limit productionDaily = new Limit(200, 86400);
    /**
     * Tentative sur un petit sujet de competence : burst par utilisateur. Plus
     * genereux que la production complete — un micro-exercice se traite en une
     * minute, enchainer les cinq sujets d'une competence est le comportement
     * NORMAL qu'on ne doit surtout pas freiner.
     */
    private Limit skillAttemptBurst = new Limit(40, 600);
    /** Tentative sur un petit sujet : plafond journalier par utilisateur. */
    private Limit skillAttemptDaily = new Limit(400, 86400);

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public Limit getLogin() { return login; }
    public void setLogin(Limit login) { this.login = login; }

    public Limit getLoginPerAccount() { return loginPerAccount; }
    public void setLoginPerAccount(Limit loginPerAccount) { this.loginPerAccount = loginPerAccount; }

    public Limit getRegister() { return register; }
    public void setRegister(Limit register) { this.register = register; }

    public Limit getForgotPassword() { return forgotPassword; }
    public void setForgotPassword(Limit forgotPassword) { this.forgotPassword = forgotPassword; }

    public Limit getResetPassword() { return resetPassword; }
    public void setResetPassword(Limit resetPassword) { this.resetPassword = resetPassword; }

    public Limit getContact() { return contact; }
    public void setContact(Limit contact) { this.contact = contact; }

    public Limit getDemo() { return demo; }
    public void setDemo(Limit demo) { this.demo = demo; }

    public Limit getProductionBurst() { return productionBurst; }
    public void setProductionBurst(Limit productionBurst) { this.productionBurst = productionBurst; }

    public Limit getProductionDaily() { return productionDaily; }
    public void setProductionDaily(Limit productionDaily) { this.productionDaily = productionDaily; }

    public Limit getSkillAttemptBurst() { return skillAttemptBurst; }
    public void setSkillAttemptBurst(Limit skillAttemptBurst) { this.skillAttemptBurst = skillAttemptBurst; }

    public Limit getSkillAttemptDaily() { return skillAttemptDaily; }
    public void setSkillAttemptDaily(Limit skillAttemptDaily) { this.skillAttemptDaily = skillAttemptDaily; }

    /** Une limite = {@code max} requetes autorisees par fenetre de {@code windowSeconds}. */
    public static class Limit {
        private int max;
        private int windowSeconds;

        public Limit() {
        }

        public Limit(int max, int windowSeconds) {
            this.max = max;
            this.windowSeconds = windowSeconds;
        }

        public int getMax() { return max; }
        public void setMax(int max) { this.max = max; }

        public int getWindowSeconds() { return windowSeconds; }
        public void setWindowSeconds(int windowSeconds) { this.windowSeconds = windowSeconds; }
    }
}
