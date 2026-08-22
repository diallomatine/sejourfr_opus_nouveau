package com.sejourfr.app.enums;

import java.util.Arrays;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Registre <b>ferme</b> des evenements d'analytics, et de ce que chacun a le
 * droit de porter.
 *
 * <p><b>Un evenement n'existe ici que pour ce qui n'existe QUE dans le
 * navigateur.</b> C'est la doctrine de V036, et elle prime sur le §100 du brief
 * qui recommande une liste plus large. Ne figurent donc PAS dans cet enum, et
 * ne doivent jamais y etre ajoutes :
 * <ul>
 *   <li>{@code USER_REGISTERED} — se lit sur {@code users.created_at} ;</li>
 *   <li>{@code PAYMENT_SUCCEEDED} / {@code SUBSCRIPTION_*} — se lisent sur
 *       {@code user_subscriptions} ;</li>
 *   <li>{@code DIAGNOSTIC_COMPLETED} — se lit sur
 *       {@code diagnostic_sessions.status = COMPLETED} ;</li>
 *   <li>{@code PAYMENT_FAILED} — c'est un statut {@code PENDING} ou une absence
 *       de ligne.</li>
 * </ul>
 * Chacun de ces faits a deja une source exacte, deja purgee avec le compte. En
 * doubler un ici creerait deux compteurs pour une meme chose, et c'est celui
 * qu'on regarde le moins qui finirait par mentir.
 *
 * <p><b>Origine.</b> {@link Origine#CLIENT} = emis par un front.
 * {@link Origine#SERVEUR} = pose par le serveur, et <b>refuse sur l'endpoint
 * public</b> : venant d'un client, {@code CHECKOUT_STARTED} serait une
 * <i>intention</i>, pas un fait, et la derniere marche de l'entonnoir ne
 * voudrait plus rien dire (meme arbitrage que {@code FunnelEvent}).
 */
public enum AnalyticsEvent {

    // ------------------------------------------------------------------------
    // Acquisition / landing
    // ------------------------------------------------------------------------

    /** Une landing a ete affichee. */
    LANDING_VIEWED(Origine.CLIENT, AnalyticsProperty.LANDING_PATH, AnalyticsProperty.LANDING_VARIANT),

    /** Clic sur « Faire mon diagnostic ». */
    DIAGNOSTIC_CTA_CLICKED(Origine.CLIENT, AnalyticsProperty.CTA_LOCATION, AnalyticsProperty.DIAGNOSTIC_TYPE),

    /**
     * Clic sur « Passer l'examen découverte » — la <b>seconde</b> porte
     * d'entrée de {@code /reussir}.
     *
     * <p>🛑 <b>Distinct de {@link #DIAGNOSTIC_CTA_CLICKED}, et il doit le
     * rester.</b> Le civique n'a ni production, ni niveau CECRL, ni diagnostic :
     * confondre les deux gonflerait la mesure du diagnostic de clics qui n'y
     * mènent pas. Les deux comptent comme des <i>clics</i> dans l'agrégat et
     * restent séparés dans le détail — même arbitrage que
     * {@code SOCIAL_LANDING_CIVIQUE_CLICKED} sur {@code page_views}, dont il
     * prend la suite.
     */
    CIVIQUE_CTA_CLICKED(Origine.CLIENT, AnalyticsProperty.CTA_LOCATION),

    /** Ecran de prix affiche. */
    PRICING_VIEWED(Origine.CLIENT),

    /** Clic sur un pass depuis l'ecran de prix. */
    PRICING_CTA_CLICKED(Origine.CLIENT, AnalyticsProperty.PLAN_CODE),

    /** Clic sur « S'inscrire ». */
    SIGNUP_CTA_CLICKED(Origine.CLIENT, AnalyticsProperty.CTA_LOCATION),

    /** Clic sur « Se connecter ». */
    LOGIN_CLICKED(Origine.CLIENT),

    /**
     * Le formulaire d'inscription a ete ouvert / commence. L'inscription
     * <i>reussie</i>, elle, se lit sur {@code users}.
     */
    SIGNUP_STARTED(Origine.CLIENT, AnalyticsProperty.REGISTRATION_CONTEXT),

    // ------------------------------------------------------------------------
    // Diagnostic — les etapes INTERMEDIAIRES seulement.
    //
    // Le debut et la fin d'une session sont sur `diagnostic_sessions`. Ce qui
    // n'y est pas, ce sont les quatre domaines pris un par un : c'est la que
    // se voient les abandons, et nulle part ailleurs.
    // ------------------------------------------------------------------------

    /** Le visiteur entre dans le parcours (encore invite : aucune ligne en base). */
    DIAGNOSTIC_STARTED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),

    DIAGNOSTIC_EE_STARTED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_EE_COMPLETED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_EO_STARTED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_EO_COMPLETED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_CO_STARTED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_CO_COMPLETED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_CE_STARTED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),
    DIAGNOSTIC_CE_COMPLETED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),

    /**
     * Le compte est demandé : les deux productions sont faites, l'analyse
     * attend une inscription.
     *
     * <p>🛑 <b>C'est LA mesure de conversion du parcours invité</b>, et ce n'est
     * pas le même fait que {@link #DIAGNOSTIC_EO_COMPLETED} (« l'oral est
     * terminé »). Entre les deux se joue précisément la décision de créer un
     * compte, donc tout l'entonnoir d'inscription du diagnostic. Tout ce qui
     * précède se passe hors base : sans cet événement, cette marche-là n'est
     * mesurée nulle part.
     */
    DIAGNOSTIC_ACCOUNT_REQUIRED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),

    /** Le rapport a ete affiche — l'ecran ou se decide l'abonnement. */
    DIAGNOSTIC_REPORT_VIEWED(Origine.CLIENT, AnalyticsProperty.DIAGNOSTIC_TYPE),

    // ------------------------------------------------------------------------
    // Plan personnalise
    //
    // Ces deux-la ne servent AUCUN bloc de la maquette. Ils existent pour ne pas
    // PERDRE une mesure en migrant depuis `page_views`, qui les portait deja :
    // retirer un compteur en changeant d'outil, c'est effacer l'historique de
    // l'usage reel du Plan sans que personne s'en apercoive.
    // ------------------------------------------------------------------------

    /** Le Plan personnalisé a été ouvert. */
    PLAN_OPENED(Origine.CLIENT),

    /** Un exercice recommandé par le Plan a été lancé. */
    PLAN_EXERCISE_STARTED(Origine.CLIENT, AnalyticsProperty.EXERCISE_KIND),

    // ------------------------------------------------------------------------
    // Premium
    // ------------------------------------------------------------------------

    /** Clic sur un CTA qui engage l'achat. */
    PREMIUM_CTA_CLICKED(Origine.CLIENT,
            AnalyticsProperty.CTA_LOCATION, AnalyticsProperty.PLAN_CODE, AnalyticsProperty.SCREEN),

    /**
     * Depart reel d'un paiement. <b>Pose par le serveur</b>
     * ({@code BillingService}, apres creation effective de la session de
     * paiement) et refuse sur l'endpoint public.
     */
    CHECKOUT_STARTED(Origine.SERVEUR, AnalyticsProperty.PLAN_CODE);

    /** Qui a le droit d'emettre cet evenement. */
    public enum Origine {
        /** Emis par un front. */
        CLIENT,
        /** Pose par le serveur, jamais accepte d'un client. */
        SERVEUR
    }

    private final Origine origine;
    private final Set<AnalyticsProperty> allowed;

    AnalyticsEvent(Origine origine, AnalyticsProperty... allowed) {
        this.origine = origine;
        this.allowed = allowed.length == 0
                ? Collections.unmodifiableSet(EnumSet.noneOf(AnalyticsProperty.class))
                : Collections.unmodifiableSet(EnumSet.copyOf(Arrays.asList(allowed)));
    }

    public Origine getOrigine() {
        return origine;
    }

    /** Vrai si un front peut emettre cet evenement. */
    public boolean isEmisParLeClient() {
        return origine == Origine.CLIENT;
    }

    /** Les seules proprietes admises sur cet evenement. Jamais nul, parfois vide. */
    public Set<AnalyticsProperty> getAllowedProperties() {
        return allowed;
    }

    /** Vrai si cette propriete est admise ici. */
    public boolean allows(AnalyticsProperty property) {
        return property != null && allowed.contains(property);
    }

    /** Les cles admises, pour un message de refus lisible. */
    public String allowedKeys() {
        if (allowed.isEmpty()) return "[] (aucune propriété n'est admise sur cet événement)";
        return allowed.stream()
                .map(AnalyticsProperty::getKey)
                .sorted()
                .collect(Collectors.joining(", ", "[", "]"));
    }
}
