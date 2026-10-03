package com.sejourfr.app.enums;

/**
 * Peut-on rejouer le calcul du niveau d'une évaluation (bloc « Calcul
 * SejourFR » de la console « Productions IA », F-5 A) ?
 */
public enum AdminCalculStatut {
    /** La grille de l'évaluation est connue et livrée : le calcul est relu avec elle. */
    CALCULE("Calcul relu avec la grille de l'évaluation."),
    /**
     * Grille connue, mais une partie des paramètres (seuils de niveau, couplage,
     * plafonds ou poids) n'y est pas déclarée et vient de la configuration
     * ACTUELLE, non tracée historiquement : le calcul est montré, la cohérence
     * avec le niveau enregistré n'est JAMAIS conclue ({@code coherent = null}).
     */
    CALCUL_PARTIEL("Calcul partiel — paramètres historiques non traçables, cohérence non vérifiable."),
    /**
     * Version de grille inconnue (évaluation antérieure à la traçabilité des
     * versions) ou fichier de grille introuvable : rien n'est inventé, seul le
     * niveau persisté est servi.
     */
    REGLE_NON_TRACABLE("Règle historique non traçable : seul le niveau enregistré est disponible."),
    /** Production sans matière à observer : ni note, ni niveau, aucun calcul. */
    NON_EVALUABLE("Production non évaluable : aucune note ni aucun niveau n'a été calculé."),
    /** Aucune évaluation (en cours ou échec). */
    SANS_EVALUATION("Aucune évaluation enregistrée pour cette production.");

    private final String label;

    AdminCalculStatut(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
