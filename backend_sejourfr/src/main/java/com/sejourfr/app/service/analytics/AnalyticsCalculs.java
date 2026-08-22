package com.sejourfr.app.service.analytics;

/**
 * Les deux seuls calculs de l'ecran Analytics — <b>autorite unique</b>.
 *
 * <p>Ils tiennent en dix lignes, et c'est precisement pour ca qu'ils avaient
 * vocation a etre recopies partout. Or les deux repondent « je ne sais pas »
 * plutot que zero quand la base est vide, et c'est cette reponse-la qu'une copie
 * finit toujours par perdre : une division par zero devient {@code Infinity}, un
 * ecart sans base devient « +100 % », et l'ecran affiche une progression
 * spectaculaire la ou il ne s'est rien passe.
 */
public final class AnalyticsCalculs {

    private AnalyticsCalculs() {
    }

    /**
     * Taux entre 0 et 1, ou {@code null} quand la base est nulle.
     *
     * <p>🛑 <b>Pas zero.</b> « 0 % de conversion » affirme que personne n'a
     * converti ; sans base, on n'a mesure personne. Les deux se ressemblent a
     * l'ecran et ne veulent pas dire la meme chose.
     */
    public static Double taux(long valeur, long base) {
        if (base <= 0) return null;
        return (double) valeur / (double) base;
    }

    /**
     * Ecart relatif a la periode precedente, ou {@code null} si elle est vide.
     *
     * <p>Brief §25 : « attention a la division par zero ». Le cas n'est pas
     * theorique — c'est le cas <i>normal</i> du premier mois d'un produit, ou la
     * periode precedente ne contient rien du tout.
     */
    public static Double delta(long courant, long precedent) {
        if (precedent <= 0) return null;
        return (double) (courant - precedent) / (double) precedent;
    }
}
