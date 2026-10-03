package com.sejourfr.app.enums;

/**
 * Motif d'un signalement admin d'une évaluation IA (V085). Les codes sont
 * figés par la contrainte {@code ck_ai_evaluation_flags_motif} ; les libellés
 * sont servis, l'admin ne les recopie pas.
 */
public enum MotifSignalement {
    NIVEAU_INCOHERENT("Niveau incohérent"),
    SCORE_INCOHERENT("Score incohérent"),
    FEEDBACK_INCORRECT("Feedback incorrect"),
    REPONSE_MAL_COMPRISE("Réponse mal comprise par l'IA"),
    TRANSCRIPTION("Problème de transcription"),
    AUTRE("Autre");

    private final String label;

    MotifSignalement(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
