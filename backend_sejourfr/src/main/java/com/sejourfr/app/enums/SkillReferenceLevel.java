package com.sejourfr.app.enums;

/**
 * Les 3 productions de reference d'un petit sujet, revelees APRES la production
 * du candidat.
 *
 * <p>L'ordre de declaration est l'ordre d'affichage impose (insuffisante ->
 * attendue -> tres reussie) : c'est une progression pedagogique, on montre
 * d'abord ce qui ne suffit pas, puis ce qui suffit. Les tris s'appuient sur
 * l'ordinal.
 *
 * <p>Ce n'est PAS un niveau CECRL et cela ne se convertit en aucune note : une
 * reference « tres reussie » sur un micro-exercice ne dit rien du niveau global
 * du candidat.
 */
public enum SkillReferenceLevel {
    INSUFFICIENT("Insuffisant"),
    EXPECTED("Attendu"),
    EXCELLENT("Très réussi");

    private final String label;

    SkillReferenceLevel(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
