package com.sejourfr.app.enums;

/**
 * Cadre de passation d'une production, lu sur sa session : sous-épreuve d'un
 * examen blanc complet ({@code parent_attempt_id}), examen blanc d'épreuve
 * ({@code slot_number}), sinon entraînement libre. Même prédicat que
 * {@code ProductionAccessService.isExamSession}, ventilé en deux.
 */
public enum AdminProductionContexte {
    ENTRAINEMENT("Entraînement"),
    EXAMEN_BLANC("Examen blanc d'épreuve"),
    EXAMEN_COMPLET("Examen blanc complet");

    private final String label;

    AdminProductionContexte(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }

    public static AdminProductionContexte of(boolean sousEpreuveDExamenComplet, boolean slotDExamen) {
        if (sousEpreuveDExamenComplet) return EXAMEN_COMPLET;
        if (slotDExamen) return EXAMEN_BLANC;
        return ENTRAINEMENT;
    }
}
