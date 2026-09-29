package com.sejourfr.app.enums;

/**
 * Nature d'une etape du parcours TCF.
 *
 * <p><b>Trois natures, et elles n'ont pas le meme grain.</b> Un diagnostic
 * mesure le candidat, un examen mesure une epreuve, un entrainement travaille
 * une competence. C'est la seule taxonomie de la file : tout le reste — le
 * libelle, le compteur, le verrou, l'action a lancer — se derive de la
 * competence ou de l'epreuve que porte l'etape.
 *
 * <p>🛑 <b>Le serveur expose la nature, pas la phrase</b> — meme regle que
 * {@link PlanPathStepKind}, {@link PlanDomainAssessmentKind} et
 * {@code PlanChangeDto}. « Faire mon diagnostic rapide » et « Vérifier mes
 * progrès » appartiennent aux fronts.
 */
public enum JourneyStepType {

    /**
     * Le diagnostic rapide. Ajoute uniquement quand <b>aucune</b> evaluation
     * exploitable n'existe, historique compris (R11, R19).
     */
    DIAGNOSTIC,

    /**
     * Travailler une competence. ⚠️ <b>Deux grains sous un seul nom</b> : en
     * expression, les 5 petits sujets de l'etape
     * ({@code LearningPlanStep.PROMPTS_PAR_ETAPE}) ; en comprehension, des
     * series ciblees de 20 QCM ({@code trainSeriesQuota}) — les competences
     * CO/CE n'ont ni tache ni petit sujet. Le discriminant est
     * {@code skills.task_code}, et l'unite est <b>servie</b>
     * ({@link JourneyProgressUnit}), jamais deduite par un front.
     */
    TRAIN_SKILL,

    /**
     * Passer une epreuve. Deux intentions, portees par {@link JourneyStepPurpose} :
     * mesurer une epreuve jamais mesuree, ou verifier les progres d'un lot.
     */
    SECTION_EXAM
}
