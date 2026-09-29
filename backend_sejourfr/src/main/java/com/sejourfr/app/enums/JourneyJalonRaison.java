package com.sejourfr.app.enums;

/**
 * <b>Pourquoi le jalon « Faire un examen blanc complet » est propose</b>
 * (2026-09-27, D-68). Servi avec lui ({@code JourneyExamenCompletDto.raison}) :
 * les fronts en tirent leur phrase, jamais la condition.
 *
 * <p>🛑 Autorite unique : {@code JourneyJalonExamenComplet}. Quand les deux
 * conditions tiennent, {@link #OBJECTIF_ATTEINT} l'emporte — c'est la plus
 * forte des deux raisons de se mesurer.
 */
public enum JourneyJalonRaison {

    /**
     * Assez de cycles de <b>travail</b> termines depuis le dernier examen blanc
     * complet ({@code examenCompletJalonCycles} de la configuration du parcours,
     * 3 en v4) : le compteur repart de zero apres chaque examen complet.
     */
    CYCLES_DE_TRAVAIL,

    /**
     * Le niveau objectif est atteint sur <b>toutes</b> les epreuves (TCF) ou
     * <b>tous</b> les themes (civique), mesure par un <b>examen blanc</b> —
     * jamais par le diagnostic.
     */
    OBJECTIF_ATTEINT
}
