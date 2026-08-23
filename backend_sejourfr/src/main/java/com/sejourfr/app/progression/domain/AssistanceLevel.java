package com.sejourfr.app.progression.domain;

/**
 * Le niveau d'aide dont le candidat a beneficie pendant l'activite (V4.2 §8.2).
 *
 * <p>Son facteur multiplie le poids de la preuve. <b>Aucun plancher artificiel
 * n'est applique</b> (§8.3) : une preuve tres assistee doit reellement peser
 * moins. En revanche l'assistance n'entame pas les {@code practicePoints} — le
 * sentiment d'effort de l'utilisateur reste entier (§26).
 */
public enum AssistanceLevel {
    NONE,
    LIGHT,
    HEAVY,
    ANSWER_OR_MODEL_SEEN_BEFORE_SUBMISSION
}
