package com.sejourfr.app.enums;

/**
 * L'etat du Plan TCF servi.
 *
 * <p>🛑 <b>D-69 (2026-09-28, decision du proprietaire) : une seule valeur.</b>
 * Le Plan existe pour tout compte, diagnostic fait ou non — sans diagnostic,
 * son cycle est le cycle d'examens par defaut. {@code NEEDS_DIAGNOSTIC} et
 * {@code DIAGNOSTIC_IN_PROGRESS}, qui fermaient le Plan tant que le diagnostic
 * rapide n'etait pas clos, sont supprimes avec la porte qu'ils servaient.
 * L'enum reste : c'est le contrat lu par les fronts installes.
 */
public enum LearningPlanState {
    ACTIVE
}
