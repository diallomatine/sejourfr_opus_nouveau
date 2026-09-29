package com.sejourfr.app.service.versionciblee;

/**
 * Les deux formes de sortie du second appel, et donc les deux tool-schemas.
 *
 * <p>Ce n'est pas un détail de nommage : à l'écrit on rend au candidat sa
 * réponse RÉÉCRITE, à l'oral on ne rend que des passages REFORMULÉS. Un seul
 * contrat pour les deux aurait supposé des champs facultatifs, c'est-à-dire un
 * contrat qui n'en est plus un — or ce qui tient la qualité ici, ce sont les
 * contraintes dures.
 */
public enum VersionCibleeVariante {

    /** Production écrite : {@code exemple_cible {texte, segments}}. */
    ECRIT,

    /** Production orale : {@code reformulations [{segment_numero, reformule, apport}]}. */
    ORAL
}
