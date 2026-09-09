package com.sejourfr.app.enums;

/**
 * Etat d'une section du diagnostic TCF, tel que l'ecran d'accueil l'affiche
 * (30_ §5.1). <b>Derive a la lecture</b> depuis le sous-attempt : rien de tout
 * cela n'est persiste.
 */
public enum TcfDiagnosticSectionState {

    /** Jamais commencee. Elle attend le candidat aussi longtemps qu'il faut. */
    A_FAIRE,

    /**
     * Commencee, chrono lance, pas encore close. Une section commencee se
     * termine d'une traite (10_ §4.2) : il n'existe pas de reprise a
     * mi-section.
     */
    EN_COURS,

    /** Close. Ses reponses ou ses productions sont enregistrees. */
    TERMINEE
}
