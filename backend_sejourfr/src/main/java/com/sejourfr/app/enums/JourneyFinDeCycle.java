package com.sejourfr.app.enums;

/**
 * <b>Le geste qui a clos un cycle HISTORISE</b> — son mode de cloture, ecrit
 * une fois a l'historisation ({@code journey.fin_de_cycle}, V077 puis V078) et
 * raconte tel quel par « Mes cycles ».
 *
 * <p>🛑 <b>Ce n'est plus une PROPOSITION de fin de cycle</b> (2026-09-27, D-66).
 * Jusque-la cet enum servait aussi l'issue <b>annoncee</b> d'un cycle en cours
 * ({@code cycle.finDeCycle}) : « Examen blanc complet » ou « Actualiser mon
 * plan ». Le proprietaire a retire l'examen blanc complet de la fin de cycle —
 * elle ne propose plus que l'actualisation —, et un champ servi qui vaut
 * toujours la meme chose ne dit rien : il a ete supprime avec son autorite
 * ({@code JourneyFinDeCycle.de}). Ne reste que l'<b>evenement</b>, une donnee
 * reelle en base que l'historique relit.
 *
 * <p>{@code null} en base = inconnu (cycle historise avant V077) : l'ecran dit
 * « Cycle terminé », sans inventer l'issue.
 */
public enum JourneyFinDeCycle {

    /**
     * Clos en <b>passant a l'examen blanc complet</b> alors que ses etapes
     * obligatoires etaient toutes faites. Historique avant D-66 (l'issue de fin
     * de cycle « Passer l'examen blanc complet ») ; depuis D-66, le jalon
     * « Faire un examen blanc complet » clique sur un cycle deja termine.
     */
    EXAMEN_COMPLET,

    /** Clos par « Actualiser mon plan » : le cycle suivant a ete promu. */
    ACTUALISATION,

    /**
     * <b>Mis de cote</b> par le jalon « Faire un examen blanc complet » alors
     * qu'il restait des etapes a faire (V078, D-66). Les priorites non
     * terminees ne sont pas reportees a la main : les examens du cycle
     * d'examens qui suit les recalculent.
     */
    INTERROMPU
}
