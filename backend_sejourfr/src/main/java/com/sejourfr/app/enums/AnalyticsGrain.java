package com.sejourfr.app.enums;

/**
 * Pas de la courbe temporelle, <b>choisi par le serveur</b> d'apres l'amplitude
 * de la fenetre (brief §51).
 *
 * <p>C'est le serveur qui tranche, jamais le front : le pas decide du nombre de
 * points, donc du sens de la courbe. Deux ecrans qui choisiraient chacun le leur
 * afficheraient deux courbes differentes pour la meme periode.
 *
 * <p>Les seuils sont ceux du brief, et ils ne sont pas arbitraires : une journee
 * n'a pas de « jour » a montrer, et au-dela d'un mois et demi une serie
 * journaliere devient un peigne illisible ou le bruit couvre la tendance.
 */
public enum AnalyticsGrain {

    /** Une barre par heure — fenetre d'un seul jour. */
    HOUR("hour"),

    /** Une barre par jour — de 2 a 45 jours. */
    DAY("day"),

    /** Une barre par semaine (lundi) — au-dela de 45 jours. */
    WEEK("week");

    /** Amplitude au-dela de laquelle on passe a la semaine. */
    public static final int MAX_JOURS_EN_GRAIN_JOUR = 45;

    private final String sqlUnit;

    AnalyticsGrain(String sqlUnit) {
        this.sqlUnit = sqlUnit;
    }

    /** Unite passee a {@code date_trunc} cote Postgres. */
    public String getSqlUnit() {
        return sqlUnit;
    }

    /**
     * Pas retenu pour une fenetre de {@code jours} jours, bornes incluses.
     *
     * @param jours amplitude reelle de la fenetre (jamais zero : une fenetre
     *              couvre au minimum la journee courante)
     */
    public static AnalyticsGrain pour(int jours) {
        if (jours <= 1) return HOUR;
        if (jours <= MAX_JOURS_EN_GRAIN_JOUR) return DAY;
        return WEEK;
    }
}
