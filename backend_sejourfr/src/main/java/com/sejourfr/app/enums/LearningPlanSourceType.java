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
    /** Resultat determine d'une session QCM de comprehension ORALE, ventile par niveau. */
    TCF_CO,
    /** Resultat determine d'une session QCM de comprehension ECRITE, ventile par niveau. */
    TCF_CE;

    /**
     * Preuve <b>en situation</b> : une production complete, examen blanc compris,
     * ou le candidat n'etait pas guide vers cette seule competence.
     *
     * <p>Le diagnostic en est volontairement exclu : c'est la <b>baseline</b>,
     * le point de depart qu'on cherche justement a depasser. Le confirmer
     * reviendrait a declarer une competence solide avant tout entrainement.
     *
     * <p><b>La COMPREHENSION en fait partie, et c'est un choix</b> (2026-08-21).
     * En expression, « contextualise » s'oppose au micro-exercice : le candidat
     * a produit une vraie tache au lieu de travailler un moyen isole, et c'est
     * ce transfert qu'il reste a prouver. En comprehension, <b>ce partage n'a
     * pas d'equivalent</b> : un QCM de CO ou de CE EST le format reel de
     * l'epreuve, il n'existe pas de version « guidee » d'une question a laquelle
     * l'opposer. Exiger une preuve en situation par-dessus reviendrait a
     * attendre une epreuve qui n'existe pas, et aucune competence CO/CE ne
     * pourrait jamais devenir solide.
     *
     * <p>⚠️ <b>Sans effet sur EE/EO</b> : la source d'une observation vit sur la
     * ligne, et une competence d'expression ne recoit jamais de {@code TCF_CO} /
     * {@code TCF_CE} — ces deux valeurs ne s'ecrivent que vers les six
     * competences de comprehension. Verrouille par test.
     */
    public boolean isContextual() {
        return this == PRODUCTION_EE || this == PRODUCTION_EO
                || this == MOCK_EXAM_EE || this == MOCK_EXAM_EO
                || this == TCF_CO || this == TCF_CE;
    }

    /**
     * Observation de COMPREHENSION : elle ne vient d'aucun correcteur, mais du
     * comptage determine des bonnes reponses d'une session QCM, ventile par
     * niveau de question.
     */
    public boolean isComprehension() {
        return this == TCF_CO || this == TCF_CE;
    }

    /** Micro-entrainement cible : il fait progresser, il ne confirme jamais seul. */
    public boolean isTargeted() {
        return this == SKILL_TRAINING;
    }
}
