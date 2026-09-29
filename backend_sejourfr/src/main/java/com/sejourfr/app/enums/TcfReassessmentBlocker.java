package com.sejourfr.app.enums;

/**
 * Ce qui empeche <b>aujourd'hui</b> de relancer un diagnostic TCF (10_ §4.6).
 *
 * <p>🛑 <b>Le front lit ce code, il ne le devine pas.</b> Avant L7, la seule
 * facon de savoir si une reevaluation etait possible etait de la tenter et de
 * recevoir un 400 : l'ecran ne pouvait donc rien annoncer sans recalculer
 * lui-meme la regle des 14 jours, ce que le depot interdit (« derive serveur
 * &rArr; jamais recalcule par un front »).
 *
 * <p>{@code null} sur l'eligibilite = rien ne bloque. Il n'existe pas de valeur
 * {@code NONE} : un « aucun blocage » representable a deux endroits finit par
 * diverger de {@code canStart}.
 */
public enum TcfReassessmentBlocker {

    /**
     * Le diagnostic offert a deja ete consomme et le candidat n'a pas d'acces
     * TCF. C'est la <b>porte commerciale</b> : l'ecran ouvre le paywall.
     *
     * <p>🛑 Il ne verrouille <b>jamais</b> le resultat deja obtenu (10_ §4.5) :
     * le paywall porte sur la nouvelle mesure, pas sur le constat acquis.
     */
    PREMIUM_REQUIRED,

    /**
     * Le delai minimal entre deux diagnostics n'est pas ecoule. Ce n'est pas
     * une porte commerciale : payer ne l'ouvre pas, seul le temps — ou une
     * priorite terminee (10_ §4.6) — l'ouvre.
     */
    INTERVAL_NOT_ELAPSED
}
