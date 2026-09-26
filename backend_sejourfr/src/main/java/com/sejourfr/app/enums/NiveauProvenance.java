package com.sejourfr.app.enums;

/**
 * <b>D'où vient le palier AFFICHÉ d'une épreuve</b> — l'Accueil
 * ({@code ProgressDto.Epreuve.provenance}, 2026-09-27).
 *
 * <p>🛑 <b>Servi, jamais deviné par un front</b> : c'est lui qui décide si la
 * carte d'épreuve propose « Évaluer mon niveau ». La règle du propriétaire :
 * le bouton est là dès que le niveau affiché <b>ne provient pas</b> d'un
 * examen blanc.
 *
 * <p>Autorité : {@code TcfProfileService.levelProfileAccueilDetaille}, le
 * <b>même</b> calcul que le palier affiché — la provenance ne peut donc pas
 * décrire un autre palier que celui de la carte. {@code null} = aucun palier.
 */
public enum NiveauProvenance {

    /**
     * La moyenne des derniers <b>examens qualifiants</b>
     * ({@code NiveauActuelEpreuveResolver}) : examen blanc de l'épreuve, seul
     * ou dans un examen blanc complet. ⚠️ Une sous-épreuve d'un ancien
     * diagnostic COMPLET (retiré le 2026-09-26) y compte aussi : c'est, ligne
     * pour ligne, la même épreuve qu'un examen blanc.
     */
    EXAMEN_BLANC,

    /**
     * Le repli sur la baseline du <b>diagnostic rapide</b> (EE/EO seulement) :
     * aucun examen blanc n'a encore mesuré l'épreuve.
     */
    DIAGNOSTIC
}
