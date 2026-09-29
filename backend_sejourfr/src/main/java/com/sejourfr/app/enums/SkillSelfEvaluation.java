package com.sejourfr.app.enums;

/**
 * Auto-evaluation DECLARATIVE et FACULTATIVE du candidat, saisie avant
 * validation de sa production.
 *
 * <p><b>Garde-fou produit</b> : elle n'entre jamais dans le verdict de l'IA et
 * n'est jamais envoyee au correcteur. C'est un miroir offert au candidat —
 * comparer « ce que je croyais » et « ce que le correcteur observe » est
 * l'interet pedagogique ; laisser sa propre note influencer la correction le
 * detruirait.
 */
public enum SkillSelfEvaluation {
    REUSSI("Je pense avoir réussi"),
    INCERTAIN("Je ne suis pas sûr"),
    DIFFICILE("J'ai eu du mal");

    private final String label;

    SkillSelfEvaluation(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
