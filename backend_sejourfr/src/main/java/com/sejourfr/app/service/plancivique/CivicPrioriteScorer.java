package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.enums.CivicThemeState;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

/**
 * Le <b>score de priorité</b> d'une cible civique ({@code 20_} §5.3).
 *
 * <p>Pur, et c'est le seul endroit qui porte la formule. Elle mêle quatre
 * signaux qui ne disent pas la même chose : ce qui vient d'échouer, ce qui
 * échoue de façon répétée, ce que le diagnostic avait pointé, et ce que
 * l'oubli va reprendre.
 *
 * <pre>
 * score = 3 × (erreur dans les 7 derniers jours)
 *       + 2 × min(erreurs sur 30 jours, 3)
 *       + 2 × (pointé par le diagnostic)
 *       + 2 × (échéance Leitner franchie)
 *       + 1 × (poids du thème : FAIBLE 2, À_RENFORCER 1, sinon 0)
 *       − 3 × (maîtrisée)
 *       − 10 × (contenu insuffisant)
 * </pre>
 *
 * <p>🛑 <b>Le malus de contenu insuffisant est écrasant, et c'est voulu</b> :
 * une notion qui n'a pas de quoi remplir une série ne doit <b>jamais</b> être
 * proposée en priorité ({@code 20_} §3.4). −10 la sort du classement quoi qu'il
 * arrive, au lieu d'un filtre en amont qui la rendrait invisible aux mesures.
 *
 * <p>🛑 <b>{@code NON_EVALUE} pèse 0</b>, comme {@code SOLIDE} et pour la raison
 * inverse : un thème que le diagnostic n'a pas touché n'est pas faible, il n'est
 * pas mesuré. Lui donner le poids de {@code FAIBLE} inventerait une fragilité.
 */
@Component
public class CivicPrioriteScorer {

    /** {@code 20_} §5.3 : la fenêtre « erreur récente », qui pèse le plus lourd. */
    public static final Duration FENETRE_CHAUDE = Duration.ofDays(7);

    /** La fenêtre de répétition, plafonnée à 3 erreurs. */
    public static final Duration FENETRE_REPETEE = Duration.ofDays(30);

    private static final int PLAFOND_ERREURS_REPETEES = 3;

    public int score(
            CivicEtatCible etat,
            CivicThemeState etatDuTheme,
            boolean pointeeParLeDiagnostic,
            boolean contenuInsuffisant,
            Instant maintenant) {

        int score = 0;

        if (etat.derniereErreur() != null
                && etat.derniereErreur().isAfter(maintenant.minus(FENETRE_CHAUDE))) {
            score += 3;
        }
        score += 2 * Math.min(etat.erreursRecentes(), PLAFOND_ERREURS_REPETEES);
        if (pointeeParLeDiagnostic) score += 2;
        if (etat.aRevoir(maintenant)) score += 2;
        score += poidsDuTheme(etatDuTheme);
        if (etat.maitrise() == CivicMaitrise.MAITRISEE) score -= 3;
        if (contenuInsuffisant) score -= 10;

        return score;
    }

    /**
     * Le poids du thème d'appartenance.
     *
     * <p>🛑 {@code null} et {@code NON_EVALUE} valent <b>0</b> : « pas mesuré »
     * n'est pas « faible ».
     */
    private static int poidsDuTheme(CivicThemeState etat) {
        if (etat == null) return 0;
        return switch (etat) {
            case FAIBLE -> 2;
            case A_RENFORCER -> 1;
            case SOLIDE, NON_EVALUE -> 0;
        };
    }
}
