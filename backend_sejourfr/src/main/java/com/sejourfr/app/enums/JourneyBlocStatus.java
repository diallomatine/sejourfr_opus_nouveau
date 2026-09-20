package com.sejourfr.app.enums;

/**
 * Ou en est un <b>bloc</b> du cycle — c'est-a-dire une <b>epreuve</b>.
 *
 * <p>🛑 <b>DERIVE A LA LECTURE, JAMAIS PERSISTE</b> (D-12, D-14). Un bloc n'est
 * pas une table : c'est la <b>lecture par epreuve</b> des etapes du cycle. Son
 * statut se recalcule a chaque appel depuis les clotures des etapes, l'election
 * de {@code CURRENT} et « cette epreuve a-t-elle deja ete mesuree ? » — lu chez
 * {@code NiveauActuelEpreuveResolver}, son unique autorite.
 *
 * <p>🛑 <b>Le serveur sert la nature, pas la phrase</b> (B-11) : « TERMINÉ »,
 * « 1 compétence restante · puis examen » et « VERROUILLÉ » sont composes par
 * les fronts, comme {@link JourneyStepStatus} et {@link PlanDomainAssessmentKind}
 * avant lui.
 */
public enum JourneyBlocStatus {

    /**
     * Toutes les etapes du bloc sont cloturees. Le <b>cycle</b> est termine
     * quand ses quatre blocs le sont (spec §3).
     */
    TERMINE,

    /**
     * Le bloc est le <b>premier</b>, dans l'ordre servi, a porter une etape
     * {@code TRAIN_SKILL} <b>ouverte</b> — qu'elle soit executable ou non.
     * Quand <b>aucun</b> bloc n'en porte (cycle de mesure, cycle dont tout le
     * travail est fini), c'est celui qui porte l'etape <b>courante</b>.
     *
     * <p>🛑 Un seul bloc a la fois, par construction : un seul peut etre le
     * <b>premier</b>.
     *
     * <p>⚠️ <b>Ce n'est plus « le bloc qui porte {@code CURRENT} »</b>
     * (2026-09-20, revocation partielle d'A37). Pour un compte <b>gratuit</b>,
     * {@code CURRENT} — « premiere etape non cloturee <b>et executable</b> »
     * (D-1) — ne peut pas tomber sur une competence (D-18 les rend toutes
     * inexecutables) : le badge partait au premier examen ouvert, et l'ecran
     * disait a la fois « commence par l'expression ecrite » et « la
     * comprehension orale est en cours ». 🛑 D-1 et D-18 sont intacts : c'est
     * le badge qui a cesse de dependre de {@code CURRENT}, pas l'inverse.
     */
    EN_COURS,

    /**
     * Le bloc ne porte <b>aucune competence</b> et son epreuve n'a <b>jamais ete
     * mesuree</b>. Il n'y a rien a y travailler tant que la mesure n'a pas dit
     * quoi : son examen est donc ouvert immediatement (D-15).
     *
     * <p>🛑 Ce n'est pas « bloc vide » : c'est « on ne sait pas encore ». Le
     * distinguer de {@link #A_VENIR} evite de presenter comme « plus tard » une
     * epreuve que le candidat peut mesurer tout de suite.
     */
    A_EVALUER,

    /** Des etapes restent, mais la main est ailleurs. */
    A_VENIR
}
