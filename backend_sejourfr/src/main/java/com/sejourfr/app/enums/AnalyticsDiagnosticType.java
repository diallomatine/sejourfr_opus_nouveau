package com.sejourfr.app.enums;

/**
 * Variante de diagnostic suivie par le candidat.
 *
 * <p><b>Ce n'est pas persiste sur {@code diagnostic_sessions}</b>, et c'est
 * volontaire : la seule difference entre les deux variantes est ce que le front
 * enchaine apres l'analyse, et le profil reel se lit sur les <i>domaines
 * mesures</i>. Une colonne aurait affirme « complet » sur un candidat arrete
 * apres l'oral — et au moment du choix, le candidat est encore invite, aucune
 * ligne ne pourrait la porter. Ici c'est une propriete d'evenement : ce que le
 * visiteur a <i>choisi</i>, pas ce qu'il a <i>accompli</i>.
 */
public enum AnalyticsDiagnosticType {

    /** EE + EO seulement. */
    RAPID,

    /** Les quatre domaines : EE, EO, CO, CE. */
    COMPLETE,

    /** Le front n'a pas su dire. Jamais devine a sa place. */
    UNKNOWN
}
