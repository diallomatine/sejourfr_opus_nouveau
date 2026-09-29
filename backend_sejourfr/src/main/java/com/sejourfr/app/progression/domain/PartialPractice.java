package com.sejourfr.app.progression.domain;

import java.time.Instant;

/**
 * <b>Une activité réellement travaillée mais laissée en cours</b> — elle donne
 * des points de parcours au prorata, et rien d'autre (V4.2 §23.1, §26).
 *
 * <p>C'est le pendant exact de {@link LearningEvidence} pour ce qui n'en produit
 * pas : une série de révision abandonnée à la douzième question n'est pas un
 * échec pédagogique, c'est du travail fourni. Elle n'émet donc <b>aucune preuve
 * de maîtrise</b> (invariant I7) — ni positive, ni négative — mais elle ne doit
 * pas non plus disparaître de l'écran du candidat.
 *
 * <p>🛑 Ces points <b>n'ajoutent aucune masse de confiance</b>, ne touchent pas
 * au {@code masteryScore} et ne satisfont aucun gate. Ils n'existent que pour
 * {@code visibleProgress}.
 *
 * @param completedUnits questions répondues, sujets traités, tâches rendues
 * @param totalUnits     le dénominateur annoncé au candidat
 */
public record PartialPractice(
        ProgressionStateKey stateKey,
        EvidenceSourceType sourceType,
        int completedUnits,
        int totalUnits,
        Instant occurredAt
) {

    public PartialPractice {
        if (totalUnits <= 0) {
            throw new IllegalArgumentException("totalUnits doit être > 0");
        }
        if (completedUnits < 0 || completedUnits > totalUnits) {
            throw new IllegalArgumentException(
                    "completedUnits hors bornes : " + completedUnits + "/" + totalUnits);
        }
    }

    /** La part de l'activité réellement faite, dans {@code [0,1]}. */
    public double completionRatio() {
        return (double) completedUnits / totalUnits;
    }
}
