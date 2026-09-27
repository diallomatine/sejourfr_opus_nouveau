package com.sejourfr.app.enums;

/**
 * <b>Ce qui clot le cycle</b> : l'issue principale de sa fin, servie des le
 * debut du cycle (2026-09-27).
 *
 * <p>Elle existe pour la <b>derniere etape de la timeline</b> du Plan (web et
 * mobile) : tant que la fin n'est pas atteinte, l'ecran annonce deja ce qui
 * l'attend — « Examen blanc complet » ou « Actualiser mon plan ». Sans ce fait
 * servi, chaque front aurait du recombiner {@code cycleDAffinage} et
 * {@code cycleDeMesure} : une seconde copie de la regle de fin de cycle.
 *
 * <p>🛑 <b>Autorite unique</b> : {@link #de(boolean, boolean)}. La meme valeur
 * decide de {@code JourneyNextStepDto.examenCompletPossible} une fois la fin
 * atteinte — l'annonce et le bouton ne peuvent donc pas diverger.
 */
public enum JourneyFinDeCycle {

    /** Le cycle se clot par l'examen blanc complet (l'actualisation reste
     *  offerte en second). */
    EXAMEN_COMPLET,

    /** Le cycle se clot par l'actualisation seule : cycle de mesure (enchainer
     *  un second examen complet ne mesurerait rien) ou cycle d'affinage (D-64 :
     *  il vient de mesurer les epreuves une a une). */
    ACTUALISATION;

    public static JourneyFinDeCycle de(boolean cycleDAffinage, boolean cycleDeMesure) {
        return cycleDAffinage || cycleDeMesure ? ACTUALISATION : EXAMEN_COMPLET;
    }
}
