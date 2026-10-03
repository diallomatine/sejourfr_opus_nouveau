package com.sejourfr.app.enums;

/**
 * État de signalement d'une production ou d'un signalement (console
 * « Productions IA »). {@code AUCUN} ne qualifie qu'une production (aucun
 * signalement actif) ; {@code RETIRE} ne qualifie qu'un signalement de
 * l'historique.
 */
public enum EtatSignalement {
    AUCUN("Non signalée"),
    SIGNALE("Signalée"),
    VERIFIE("Vérifiée"),
    RETIRE("Retiré");

    private final String label;

    EtatSignalement(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
