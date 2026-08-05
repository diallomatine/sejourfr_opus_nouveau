package com.sejourfr.app.enums;

import java.math.BigDecimal;

/**
 * Bande qualitative d'un critere d'evaluation, derivee de sa {@code note_sur_20}.
 *
 * <p>Decision produit : une IA ne distingue pas honnetement un 13 d'un 14 —
 * afficher « Lexique : 13/20 » suggere une precision qui n'existe pas. Le
 * {@code note_sur_20} reste dans le JSON (calcul de la note globale, du niveau,
 * banc de mesure, admin) mais les fronts affichent la BANDE. Elle est calculee
 * <b>cote serveur</b> pour que les 3 fronts ne reimplementent pas 3 mappings
 * divergents.
 *
 * <p>Les bornes sont celles des bandes CECRL <b>de la grille active</b> : elles
 * changent avec l'echelle. 16-20 / 11-15 / 6-10 / 1-5 / 0 pour les grilles v3 a
 * v5 ; 10-20 / 6-9 / 2-5 / 1 / 0 pour v6, qui note sur l'echelle du TCF. Les
 * lire dans la grille (via {@code ProductionRubricsProvider#bandesCriteres()})
 * evite qu'un bon B1 s'affiche « en cours d'acquisition » apres un changement
 * d'echelle.
 *
 * <p><b>La note globale /20 reste, elle, affichee</b> : la fausse precision est
 * un probleme au niveau du critere, pas du resultat d'ensemble.
 */
public enum BandeCritere {
    TRES_BONNE_MAITRISE,
    SATISFAISANT,
    EN_COURS_ACQUISITION,
    FRAGILE,
    NON_EVALUABLE;

    /**
     * Bande d'une note /20 selon les bornes de la grille active ; null si la
     * note est absente. Un 0 vaut toujours {@code NON_EVALUABLE} : c'est le
     * hors-sujet (et, sur l'echelle du TCF, le « en deca du A1 »).
     */
    public static BandeCritere of(BigDecimal note,
                                  com.sejourfr.app.config.ProductionEvaluationProperties.BandesCriteres bornes) {
        if (note == null) return null;
        if (note.compareTo(BigDecimal.ZERO) <= 0) return NON_EVALUABLE;
        if (note.compareTo(BigDecimal.valueOf(bornes.getTresBonneMaitrise())) >= 0) return TRES_BONNE_MAITRISE;
        if (note.compareTo(BigDecimal.valueOf(bornes.getSatisfaisant())) >= 0) return SATISFAISANT;
        if (note.compareTo(BigDecimal.valueOf(bornes.getEnCoursAcquisition())) >= 0) return EN_COURS_ACQUISITION;
        return FRAGILE;
    }
}
