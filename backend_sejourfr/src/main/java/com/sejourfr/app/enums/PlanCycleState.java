package com.sejourfr.app.enums;

/**
 * Ou en est le <b>cycle de palier</b> courant du Plan.
 *
 * <p>Un cycle vise le palier <b>immediatement superieur</b> au niveau consolide
 * du candidat : on ne saute jamais de A2 a B2 (brief §37). Il se termine par un
 * <b>examen blanc complet</b> qui confirme, ou non, le palier sur les quatre
 * domaines — « competences solides &ne; niveau superieur confirme » (brief §2).
 *
 * <p><b>Derive a la lecture, jamais persiste</b> : aucune table
 * {@code plan_cycles}, aucune migration, aucun job. Le cycle se relit
 * integralement de l'historique d'observations et du profil TCF, exactement
 * comme {@code SkillMasteryState}, {@code SituationDansNiveau} et
 * {@link ContinuiteSimulation}. Recalibrer un seuil de maitrise deplace le
 * cycle au prochain appel, sans rattrapage.
 *
 * <h2>Quatre etats, pas huit</h2>
 * Le brief en enumere huit, <b>conceptuels</b>. Quatre seulement changent ce que
 * le Plan affiche ; les autres ont ete ecartes, et le motif compte autant que le
 * choix :
 * <ul>
 *   <li>{@code WAITING_REASSESSMENT} : le signal existe deja, <b>par
 *       competence</b>, sur {@code LearningPlanPriorityDto.readyForReassessment}.
 *       Un doublon au niveau du cycle finirait par le contredire.</li>
 *   <li>{@code GATE_MOCK_IN_PROGRESS} : il faudrait retenir <b>quel</b> attempt
 *       est le gate — donc persister le cycle, ce que ce chantier refuse. Un
 *       examen en cours se lit chez le moteur d'examen, qui en est
 *       l'autorite.</li>
 *   <li>{@code LEVEL_CONFIRMED} / {@code LEVEL_NOT_CONFIRMED} : ce sont des
 *       <b>transitions</b>, pas des etats. Des que l'examen confirme le palier,
 *       le niveau consolide monte et le cycle suivant commence : l'etat serait
 *       observable zero seconde. Et « non confirme », c'est
 *       {@link #TRAINING} avec les fragilites rouvertes. Ce qui se raconte au
 *       candidat appartient au bloc « ce qui a change ».</li>
 * </ul>
 */
public enum PlanCycleState {

    /**
     * Le profil n'est pas complet : au moins un des quatre domaines n'a jamais
     * ete mesure. Le Plan met « Completer mon profil » en avant et <b>ne
     * declenche aucun examen de palier</b> (brief §77) — un gate sur trois
     * domaines confirmerait un palier qu'on n'a pas mesure.
     */
    BUILDING_BASELINE,

    /** Profil complet, travail en cours sur les priorites du palier vise. */
    TRAINING,

    /**
     * Tout le travail du palier est fait : profil complet, aucune competence
     * bloquante, toutes les priorites du cycle transferees. Le Plan reclame
     * l'examen blanc complet qui confirmera le palier.
     */
    READY_FOR_GATE_MOCK,

    /**
     * L'objectif du candidat est atteint sur les domaines mesures. Le Plan
     * n'a plus de palier a construire : il entretient et remesure.
     */
    TARGET_STABILIZATION
}
