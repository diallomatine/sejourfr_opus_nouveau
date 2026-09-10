package com.sejourfr.app.service.plancivique;

import java.time.Instant;

/**
 * Ce que l'historique dit d'une cible civique (une notion, ou un thème en mode
 * dégradé) — <b>entièrement dérivé</b>, jamais persisté.
 *
 * @param boite             la boîte Leitner, repliée sur l'historique
 * @param reponses          nombre de réponses enregistrées
 * @param correctes         dont justes
 * @param consecutivesJustes série de bonnes réponses en cours
 * @param derniereVue       dernière présentation, {@code null} si jamais vue
 * @param derniereErreur    dernière erreur, {@code null} s'il n'y en a jamais eu
 * @param erreursRecentes   erreurs sur la fenêtre courte du score ({@code 20_}
 *                          §5.3). Comptées ici parce que seul le repli connaît
 *                          les réponses : un score qui les recompterait
 *                          ailleurs relirait le même historique deux fois
 * @param prochaineRevue    l'échéance Leitner, {@code null} si jamais vue
 * @param maitrise          l'état pédagogique servi
 */
public record CivicEtatCible(
        int boite,
        int reponses,
        int correctes,
        int consecutivesJustes,
        Instant derniereVue,
        Instant derniereErreur,
        int erreursRecentes,
        Instant prochaineRevue,
        CivicMaitrise maitrise
) {

    /** Une cible sur laquelle rien n'a jamais été répondu. */
    public static CivicEtatCible vierge() {
        return new CivicEtatCible(
                CivicLeitner.PREMIERE, 0, 0, 0, null, null, 0, null,
                CivicMaitrise.NON_EVALUEE);
    }

    public int erreurs() {
        return reponses - correctes;
    }

    /** L'échéance est-elle franchie ? Jamais vue ⇒ non : elle n'est pas en retard. */
    public boolean aRevoir(Instant maintenant) {
        return prochaineRevue != null && !prochaineRevue.isAfter(maintenant);
    }
}
