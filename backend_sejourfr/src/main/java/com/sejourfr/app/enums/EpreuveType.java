package com.sejourfr.app.enums;

/**
 * Nature fine d'une epreuve (orthogonale a {@link AttemptMode} et {@link Module}).
 * <p>
 * - CIVIQUE : examen civique (CSP / CR / NAT).
 * - TCF_CO : comprehension orale (25 QCM audio).
 * - TCF_CE : comprehension ecrite (25 QCM).
 * - TCF_STRUCTURE : structure de la langue (entrainement bonus, hors examen blanc IRN).
 * - TCF_EO : expression orale (3 taches evaluees par IA).
 * - TCF_EE : expression ecrite (3 taches evaluees par IA).
 * - TCF_COMPLET : conteneur d'un examen blanc TCF complet ; les sous-attempts portent
 * les 4 epreuves CO / CE / EO / EE.
 */
public enum EpreuveType {
    CIVIQUE,
    TCF_CO,
    TCF_CE,
    TCF_STRUCTURE,
    TCF_EO,
    TCF_EE,
    TCF_COMPLET
}
