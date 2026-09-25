package com.sejourfr.app.enums;

/**
 * <b>Chaque email que SejourFR envoie</b>, sa categorie et sa politique de relance.
 *
 * <p>La categorie et la relance sont des <b>regles</b>, pas des reglages : elles
 * vivent ici. Les delais, fenetres et plafonds vivent dans
 * {@code email/email-automation-config-v{n}.json}.
 *
 * <p>🛑 Vocabulaire : un pass est un <b>achat unique sans reconduction</b>. Les
 * types et les textes parlent d'« acces Premium » ou de « pass », jamais
 * d'« abonnement » — sauf {@link #PREMIUM_SUBSCRIPTION_CANCELED}, qui ne sert
 * qu'au mode recurrent dormant (reversibilite, docs/regles/paiements.md).
 */
public enum EmailType {

    WELCOME(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    PREMIUM_ACCESS_STARTED(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    PREMIUM_ACCESS_EXTENDED(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    /** Flux abonnement recurrent DORMANT : conserve pour la reversibilite. */
    PREMIUM_SUBSCRIPTION_CANCELED(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    /**
     * 🛑 Aucune relance differee : l'URL porte un jeton stocke seulement HACHE.
     * Le renvoyer imposerait de le garder en clair. Le candidat refait sa demande.
     */
    PASSWORD_RESET(EmailCategory.REQUIRED, DeferredRetry.NONE, false),
    PASSWORD_CHANGED(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    /** 🛑 Meme regle que {@link #PASSWORD_RESET} : jeton hache, aucune relance differee. */
    EMAIL_CHANGE_CONFIRMATION(EmailCategory.REQUIRED, DeferredRetry.NONE, false),
    /** Prevenir l'ANCIENNE adresse apres un changement effectif (arbitrage n°10). */
    EMAIL_CHANGED(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),
    /**
     * Accuse de reception du formulaire de contact. Aucune relance differee : son
     * numero de suivi n'est persiste nulle part, on ne sait pas le reconstruire.
     */
    CONTACT_RECEIVED(EmailCategory.REQUIRED, DeferredRetry.NONE, false),
    SUPPORT_REPLY(EmailCategory.REQUIRED, DeferredRetry.EVENT_WINDOW, false),

    /**
     * Provoque par une action du candidat : <b>jamais bloque par le plafond</b>,
     * mais il le CONSOMME (arbitrage n°18).
     */
    DIAGNOSTIC_PLAN_READY(EmailCategory.ENGAGEMENT, DeferredRetry.EVENT_WINDOW, true),

    NO_PREMIUM_AFTER_7_DAYS(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false),
    NO_TRAINING_7_DAYS(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false),
    PREMIUM_INACTIVE_2_DAYS(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false),
    PREMIUM_ENDING_7_DAYS(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false),
    PREMIUM_ENDING_2_DAYS(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false),
    PREMIUM_ENDED(EmailCategory.ENGAGEMENT, DeferredRetry.SCENARIO, false);

    /**
     * Comment une ligne {@code FAILED} de ce type est retentee plus tard.
     *
     * <ul>
     *   <li>{@code NONE} — jamais.</li>
     *   <li>{@code EVENT_WINDOW} — par la passe de maintenance, pendant la fenetre
     *       evenementielle de la configuration (24 h), variables reconstruites
     *       depuis la source.</li>
     *   <li>{@code SCENARIO} — par le scenario lui-meme, tant qu'il reste eligible
     *       dans sa fenetre : la cle FAILED ne bloque pas le prochain passage.</li>
     * </ul>
     */
    public enum DeferredRetry { NONE, EVENT_WINDOW, SCENARIO }

    private final EmailCategory category;
    private final DeferredRetry deferredRetry;
    private final boolean capExempt;

    EmailType(EmailCategory category, DeferredRetry deferredRetry, boolean capExempt) {
        this.category = category;
        this.deferredRetry = deferredRetry;
        this.capExempt = capExempt;
    }

    public EmailCategory category() {
        return category;
    }

    public DeferredRetry deferredRetry() {
        return deferredRetry;
    }

    /** Vrai si ce mail ENGAGEMENT part meme quand le plafond du jour est atteint. */
    public boolean capExempt() {
        return capExempt;
    }
}
