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
 * <p>Bornes alignees sur les bandes CECRL des rubriques :
 * 16-20 / 11-15 / 6-10 / 1-5 / 0.
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

    /** Bande d'une note /20 ; null si la note est absente ou non numerique. */
    public static BandeCritere of(BigDecimal note) {
        if (note == null) return null;
        if (note.compareTo(new BigDecimal("16")) >= 0) return TRES_BONNE_MAITRISE;
        if (note.compareTo(new BigDecimal("11")) >= 0) return SATISFAISANT;
        if (note.compareTo(new BigDecimal("6")) >= 0) return EN_COURS_ACQUISITION;
        if (note.compareTo(BigDecimal.ZERO) > 0) return FRAGILE;
        return NON_EVALUABLE;
    }
}
