package com.sejourfr.app.service.plancivique;

/**
 * L'etat d'une etape du parcours d'une cible civique.
 *
 * <p>🛑 <b>C'est le SERVEUR qui situe le candidat, pas l'ecran.</b> Une premiere
 * version derivait ces trois etats depuis {@code boite} dans les deux fronts :
 * c'etait un front qui classait un nombre en etat pedagogique, ce que le depot
 * interdit, et deux implementations qui auraient diverge a la premiere retouche.
 *
 * <p>Le libelle de chaque etape, lui, reste <b>gele cote front</b> : ce DTO sert
 * des faits, jamais des phrases.
 */
public enum CivicEtapeEtat {

    /** Deja passee. */
    FRANCHIE,

    /** La ou en est le candidat. Il y en a <b>au plus une</b>. */
    EN_COURS,

    /** Pas encore atteinte. */
    A_VENIR
}
