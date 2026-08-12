package com.sejourfr.app.enums;

/**
 * Source d'une observation du Plan. CO/CE sont reserves des maintenant pour
 * que leur integration future ne demande pas de remodeler l'historique.
 *
 * <p><b>La provenance n'est pas un simple libelle</b> : c'est elle qui donne son
 * poids a l'observation dans {@code SkillMasteryEngine}, et surtout elle qui
 * distingue une reussite <b>ciblee</b> (un micro-exercice qui ne teste presque
 * que cette competence) d'une reussite <b>en situation</b> (une vraie tache TCF,
 * ou le candidat gere tout en meme temps). Seule la seconde peut confirmer une
 * maitrise ; c'est le principe pedagogique central du module.
 */
public enum LearningPlanSourceType {
    DIAGNOSTIC_EE,
    DIAGNOSTIC_EO,
    PRODUCTION_EE,
    PRODUCTION_EO,
    /** Production EE realisee dans un examen blanc (session d'examen ou TCF complet). */
    MOCK_EXAM_EE,
    /** Production EO realisee dans un examen blanc (session d'examen ou TCF complet). */
    MOCK_EXAM_EO,
    SKILL_TRAINING,
    TCF_CO,
    TCF_CE;

    /**
     * Preuve <b>en situation</b> : une production complete, examen blanc compris,
     * ou le candidat n'etait pas guide vers cette seule competence.
     *
     * <p>Le diagnostic en est volontairement exclu : c'est la <b>baseline</b>,
     * le point de depart qu'on cherche justement a depasser. Le confirmer
     * reviendrait a declarer une competence solide avant tout entrainement.
     */
    public boolean isContextual() {
        return this == PRODUCTION_EE || this == PRODUCTION_EO
                || this == MOCK_EXAM_EE || this == MOCK_EXAM_EO;
    }

    /** Micro-entrainement cible : il fait progresser, il ne confirme jamais seul. */
    public boolean isTargeted() {
        return this == SKILL_TRAINING;
    }
}
