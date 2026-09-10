package com.sejourfr.app.enums;

/**
 * L'etat d'un theme civique au diagnostic (20_ §4.4).
 *
 * <p>🛑 <b>{@code NON_EVALUE} n'est pas {@code FAIBLE}.</b> Un theme sur lequel
 * aucune question n'a ete posee n'a pas ete rate : il n'a pas ete mesure.
 * 20_ §4.2 pose d'ailleurs la contrainte inverse — « ne jamais evaluer un theme
 * sur une seule question » — precisement pour que ce cas reste rare. Les
 * confondre reproduirait l'incident V040/V041/V042 sur le module civique.
 */
public enum CivicThemeState {

    /** Taux &ge; seuil solide. Rien a y faire pour l'instant. */
    SOLIDE("Solide"),

    /** Entre les deux seuils. */
    A_RENFORCER("À renforcer"),

    /** Sous le seuil bas. C'est ce qui coute le plus de points. */
    FAIBLE("Faible"),

    /**
     * Aucune question posee sur ce theme. 🛑 Ce n'est <b>pas</b> un verdict :
     * les ecrans le nomment « Non evalue », jamais un etat pedagogique.
     */
    NON_EVALUE("Non évalué");

    private final String label;

    CivicThemeState(String label) {
        this.label = label;
    }

    /** Libelle FR rendu au candidat, tel quel. Recopie a la main dans les fronts. */
    public String getLabel() {
        return label;
    }
}
