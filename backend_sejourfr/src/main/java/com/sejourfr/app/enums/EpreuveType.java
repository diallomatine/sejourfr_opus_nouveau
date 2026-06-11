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
    CIVIQUE("Examen civique"),
    TCF_CO("Compréhension orale"),
    TCF_CE("Compréhension écrite"),
    TCF_STRUCTURE("Structure de la langue"),
    TCF_EO("Expression orale"),
    TCF_EE("Expression écrite"),
    TCF_COMPLET("Examen blanc TCF complet");

    private final String label;

    EpreuveType(String label) {
        this.label = label;
    }

    /** Libellé lisible côté utilisateur (messages d'erreur, UI). */
    public String getLabel() {
        return label;
    }
}
