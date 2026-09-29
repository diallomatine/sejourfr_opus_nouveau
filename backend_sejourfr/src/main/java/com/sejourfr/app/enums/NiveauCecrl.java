package com.sejourfr.app.enums;

/**
 * Niveau CECRL utilise pour les evaluations des epreuves productives.
 * Distinct de {@link TargetLevel} qui represente le palier vise par l'utilisateur
 * (A2 / B1 / B2) et qui n'inclut pas A1, C1, C2.
 * <p>
 * A1_NON_ATTEINT : production en dessous du seuil A1 (cas plancher du TCF).
 */
public enum NiveauCecrl {
    A1_NON_ATTEINT,
    A1,
    A2,
    B1,
    B2,
    C1,
    C2
}
