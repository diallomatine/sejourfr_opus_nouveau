package com.sejourfr.app.enums;

import java.util.Locale;

/**
 * Verdict de l'IA sur le CRITERE UNIQUE d'un petit sujet. C'est la seule sortie
 * evaluative du module : ni note sur 20, ni niveau CECRL — un micro-exercice de
 * quelques phrases ne permet ni l'un ni l'autre, et les afficher donnerait au
 * candidat une certitude que la production ne porte pas.
 *
 * <p><b>Les libelles sont un contrat gele</b>, repris mot pour mot par les trois
 * fronts ({@code web_sejoufr/lib/types.ts}, {@code mobile .../skill_models.dart},
 * {@code admin .../skillHelpers.ts}) et figes par {@code SkillLabelsTest}. Ne pas
 * les reformuler d'un seul cote : le candidat qui passe du web au mobile doit
 * lire exactement le meme verdict.
 *
 * <p>{@code NOT_VALIDATED} se dit « Critère non atteint », et non « à
 * retravailler » : ce dernier est quasi synonyme du statut de sujet
 * {@code TO_REINFORCE} (« À renforcer ») et melangeait deux notions distinctes —
 * le verdict d'UNE tentative et l'etat d'UN sujet.
 */
public enum SkillCriterionStatus {
    VALIDATED("Critère validé"),
    PARTIAL("Critère partiellement atteint"),
    NOT_VALIDATED("Critère non atteint");

    private final String label;

    SkillCriterionStatus(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /**
     * Parse tolerant (casse/espaces libres) ; null si inconnu ou absent. Utilise
     * a la lecture de la sortie brute du correcteur, avant validation stricte.
     */
    public static SkillCriterionStatus parse(Object raw) {
        if (raw == null) return null;
        String s = raw.toString().trim().toUpperCase(Locale.ROOT);
        if (s.isEmpty()) return null;
        for (SkillCriterionStatus c : values()) {
            if (c.name().equals(s)) return c;
        }
        return null;
    }
}
