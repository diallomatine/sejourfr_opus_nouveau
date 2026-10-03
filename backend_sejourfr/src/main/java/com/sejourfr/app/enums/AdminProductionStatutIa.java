package com.sejourfr.app.enums;

/**
 * Statut IA d'une production, servi à la console « Productions IA » (F-6 A).
 * Calculé en SQL à un seul endroit ({@code AdminProductionReadRepository}) :
 * <ul>
 *   <li>{@code EN_COURS} : soumise, en transcription ou en évaluation ;</li>
 *   <li>{@code EVALUEE} : évaluée, production exploitable ;</li>
 *   <li>{@code NON_EVALUABLE} : évaluée sans matière à observer — ni note ni
 *       niveau, jamais un « A1 » ;</li>
 *   <li>{@code ECHEC} : le pipeline a échoué ({@code FAILED}), aucune
 *       évaluation n'existe.</li>
 * </ul>
 */
public enum AdminProductionStatutIa {
    EN_COURS("En cours"),
    EVALUEE("Évaluée"),
    NON_EVALUABLE("Non évaluable"),
    ECHEC("Échec");

    private final String label;

    AdminProductionStatutIa(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
