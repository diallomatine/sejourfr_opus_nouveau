package com.sejourfr.app.progression.domain;

/**
 * Comment la tentative s'est terminee — ce qui decide s'il en sort une preuve
 * de maitrise ou seulement des points de parcours (V4.2 §23).
 *
 * <p>La distinction est normative : {@code practice} inachevee n'est pas un
 * echec pedagogique, {@code assessment} rendu ou expire l'est pleinement.
 */
public enum AttemptCompletionStatus {

    /** Rendu par le candidat : qualifiant, denominateur = totalQuestions. */
    SUBMITTED,

    /** Chrono ecoule : qualifiant, les non-repondues comptent fausses (§23.4). */
    TIME_EXPIRED,

    /** Quitte volontairement : aucune preuve de maitrise (§23.2). */
    ABANDONED,

    /** Serie de pratique laissee en cours : aucune preuve de maitrise (§23.1). */
    INCOMPLETE,

    /** Coupure technique : aucune preuve, aucune penalite (§23.3). */
    INTERRUPTED_TECHNICAL;

    /** Cette tentative peut-elle emettre une {@code LearningEvidence} ? */
    public boolean emitsMasteryEvidence() {
        return this == SUBMITTED || this == TIME_EXPIRED;
    }
}
