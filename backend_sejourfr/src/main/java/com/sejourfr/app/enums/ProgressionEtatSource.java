package com.sejourfr.app.enums;

/**
 * D'où vient l'état civique affiché sur l'écran de progression d'un thème.
 *
 * <p>🛑 <b>Arbitrage D13 du 2026-09-24</b> : l'Accueil garde son moteur (l'état
 * d'un thème y vient du dernier <b>diagnostic</b> civique), l'écran de thème lit
 * les <b>examens de thème</b>. Les deux peuvent donc différer le même jour ; le
 * libellé servi le dit au candidat pour qu'il ne lise pas une contradiction.
 * Libellé gelé par {@code ProgressionLabelsTest}, recopié à la main dans les
 * fronts.
 */
public enum ProgressionEtatSource {

    /** L'état est celui du dernier examen de ce thème. */
    DERNIER_EXAMEN_THEME("D'après votre dernier examen de ce thème");

    private final String label;

    ProgressionEtatSource(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
