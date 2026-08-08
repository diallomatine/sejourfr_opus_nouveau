package com.sejourfr.app.enums;

/**
 * Epreuve d'appartenance d'une competence : expression ecrite ou orale.
 *
 * <p>Volontairement distinct de {@link EpreuveType} (qui vaut {@code TCF_EE} /
 * {@code TCF_EO} et sert aux epreuves COMPLETES notees sur 20). Le module
 * competences est une voie parallele : melanger les deux enums inviterait a
 * reutiliser le pipeline de notation des productions, ce qu'on refuse
 * explicitement (pas de note, pas de niveau CECRL sur un micro-exercice).
 */
public enum SkillSection {
    EE("Expression écrite"),
    EO("Expression orale");

    private final String label;

    SkillSection(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
